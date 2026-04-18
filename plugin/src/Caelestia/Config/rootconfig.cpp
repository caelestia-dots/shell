#include "rootconfig.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsondocument.h>
#include <qmetaobject.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString watchRoot() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
}

} // namespace

RootConfig::RootConfig(QObject* parent)
    : ConfigObject(parent) {}

bool RootConfig::recentlySaved() const {
    return m_recentlySaved;
}

QStringList RootConfig::collectUnknownKeys(const ConfigObject* obj, const QJsonObject& json) {
    QStringList unknown;
    const auto* meta = obj->metaObject();

    QSet<QString> known;
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i)
        known.insert(QString::fromUtf8(meta->property(i).name()));

    for (auto it = json.begin(); it != json.end(); ++it) {
        if (!known.contains(it.key())) {
            unknown.append(it.key());
        } else if (it.value().isObject()) {
            int idx = meta->indexOfProperty(it.key().toUtf8().constData());
            if (idx >= 0) {
                auto prop = meta->property(idx);
                auto value = prop.read(obj);
                auto* subObj = value.value<ConfigObject*>();
                if (subObj) {
                    const auto subUnknown = collectUnknownKeys(subObj, it.value().toObject());
                    for (const auto& subKey : subUnknown)
                        unknown.append(it.key() + QStringLiteral(".") + subKey);
                }
            }
        }
    }

    return unknown;
}

void RootConfig::setupFileBackend(const QString& path, const QString& screen) {
    m_filePath = path;
    m_screen = screen;

    m_watcher = new QFileSystemWatcher(this);
    m_saveTimer = new QTimer(this);
    m_cooldownTimer = new QTimer(this);
    m_retryTimer = new QTimer(this);

    m_retryTimer->setSingleShot(true);
    m_retryTimer->setInterval(50);
    connect(m_retryTimer, &QTimer::timeout, this, &RootConfig::reload);

    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(500);
    connect(m_saveTimer, &QTimer::timeout, this, [this] {
        QDir().mkpath(QFileInfo(m_filePath).absolutePath());

        QFile file(m_filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            auto err = QStringLiteral("Failed to write %1: %2").arg(m_filePath, file.errorString());
            qCWarning(lcConfig, "%s", qUtf8Printable(err));
            emit saveFailed(err, m_screen);
            return;
        }

        auto json = toJsonObject();
        file.write(QJsonDocument(json).toJson(QJsonDocument::Indented));
        file.close();

        // Update watches — save may have created directories
        updateWatch();

        emit saved(m_screen);
    });

    m_cooldownTimer->setSingleShot(true);
    m_cooldownTimer->setInterval(2000);
    connect(m_cooldownTimer, &QTimer::timeout, this, [this] {
        m_recentlySaved = false;
    });

    m_reloadDebounce = new QTimer(this);
    m_reloadDebounce->setSingleShot(true);
    m_reloadDebounce->setInterval(50);
    connect(m_reloadDebounce, &QTimer::timeout, this, &RootConfig::reload);

    // Auto-save when any property changes (debounced by the save timer)
    connectAutoSave(this);

    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &RootConfig::onWatcherEvent);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &RootConfig::onWatcherEvent);

    qCDebug(lcConfig) << "Setting up file backend for" << metaObject()->className() << "at" << path;

    updateWatch();

    // Load immediately so values are available during construction.
    // Defer signal emissions to next event loop tick so QML has time to connect.
    auto result = reloadFromFile();
    QTimer::singleShot(0, this, [this, result] {
        emitLoadSignals(result, false);
    });
}

void RootConfig::connectAutoSave(ConfigObject* obj) {
    connect(obj, &ConfigObject::propertiesChanged, this, [this] {
        if (!m_loading)
            saveToFile();
    });

    // Recurse into sub-objects
    const auto* meta = obj->metaObject();
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        auto value = prop.read(obj);
        auto* subObj = value.value<ConfigObject*>();
        if (subObj)
            connectAutoSave(subObj);
    }
}

void RootConfig::updateWatch() {
    auto targetDir = QFileInfo(m_filePath).absolutePath();

    // Find the nearest existing directory, walking up toward the watch root
    auto dir = targetDir;
    while (!QFile::exists(dir) && dir != watchRoot() && !dir.isEmpty()) {
        auto parent = QFileInfo(dir).absolutePath();
        if (parent == dir)
            break; // reached filesystem root
        dir = parent;
    }

    // Update directory watch if it changed
    if (dir != m_watchedDir) {
        if (!m_watchedDir.isEmpty())
            m_watcher->removePath(m_watchedDir);

        m_watchedDir = dir;

        if (QFile::exists(dir))
            m_watcher->addPath(dir);
    }

    // Watch the file itself if it exists (for in-place modifications)
    if (QFile::exists(m_filePath)) {
        if (!m_watcher->files().contains(m_filePath))
            m_watcher->addPath(m_filePath);
    }
}

void RootConfig::onWatcherEvent() {
    // Re-evaluate what to watch — directories may have been created or deleted
    updateWatch();

    if (!m_recentlySaved)
        m_reloadDebounce->start();
}

void RootConfig::saveToFile() {
    if (!m_saveTimer)
        return;
    m_saveTimer->start();
    m_recentlySaved = true;
    m_cooldownTimer->start();
}

std::optional<QString> RootConfig::reloadFromFile() {
    QFile file(m_filePath);

    if (!file.exists()) {
        qCDebug(lcConfig) << "File does not exist:" << m_filePath;
        return std::nullopt;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        auto err = QStringLiteral("Failed to open %1: %2").arg(m_filePath, file.errorString());
        qCDebug(lcConfig, "%s", qUtf8Printable(err));
        return err;
    }

    QJsonParseError error{};
    auto doc = QJsonDocument::fromJson(file.readAll(), &error);

    if (error.error != QJsonParseError::NoError) {
        if (m_retryTimer && m_parseRetries < 3) {
            m_parseRetries++;
            qCDebug(lcConfig, "Failed to parse %s: %s - retrying (%d/3)", qUtf8Printable(m_filePath),
                qUtf8Printable(error.errorString()), m_parseRetries);
            m_retryTimer->start();
            return std::nullopt; // pending retry — no signal
        }

        qCWarning(lcConfig, "Failed to parse %s: %s", qUtf8Printable(m_filePath), qUtf8Printable(error.errorString()));
        m_parseRetries = 0;
        return QStringLiteral("JSON parse error: %1").arg(error.errorString());
    }

    m_parseRetries = 0;

    qCDebug(lcConfig) << "Reloading" << metaObject()->className() << "from" << m_filePath;

    m_loading = true;

    clearLoadedKeys();

    auto jsonObj = doc.object();
    loadFromJson(jsonObj);

    m_loading = false;

    // Collect unknown keys — caller is responsible for emitting signals
    m_lastUnknownKeys = collectUnknownKeys(this, jsonObj);

    return QString(); // success
}

void RootConfig::save() {
    saveToFile();
}

void RootConfig::emitLoadSignals(const std::optional<QString>& result, bool emitLoaded) {
    if (!result.has_value())
        return;

    for (const auto& key : std::as_const(m_lastUnknownKeys))
        emit unknownOption(key, m_screen);
    m_lastUnknownKeys.clear();

    if (result->isEmpty()) {
        if (emitLoaded)
            emit loaded(m_screen);
    } else {
        emit loadFailed(*result, m_screen);
    }
}

void RootConfig::reload() {
    emitLoadSignals(reloadFromFile());
}

} // namespace caelestia::config
