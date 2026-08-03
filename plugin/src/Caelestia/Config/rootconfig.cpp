#include "rootconfig.hpp"

#include <qdatetime.h>
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

        const auto json = toJson().toObject();
        file.write(QJsonDocument(json).toJson(QJsonDocument::Indented));
        file.close();

        // Update watches — save may have created directories
        updateWatch();
        m_lastSignature = fileSignature();

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

void RootConfig::markLoadFailed() {
    m_loadFailed = true;

    // A queued save would write memory over a file that could not be read
    if (m_saveTimer)
        m_saveTimer->stop();
}

void RootConfig::connectAutoSave(ConfigNode* node) {
    connect(node, &ConfigNode::propertiesChanged, this, [this] {
        if (!m_loading)
            saveToFile();
    });

    // Recurse into child nodes
    const auto children = node->childNodes();
    for (auto* const child : children)
        connectAutoSave(child);
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

    if (m_recentlySaved)
        return;

    // Only reload when the file actually changed (directory is watched so events fire for unrelated files)
    if (fileSignature() == m_lastSignature)
        return;

    m_reloadDebounce->start();
}

QString RootConfig::fileSignature() const {
    QFileInfo info(m_filePath);
    if (!info.exists())
        return QString();

    return QStringLiteral("%1:%2").arg(info.size()).arg(info.lastModified().toMSecsSinceEpoch());
}

void RootConfig::saveToFile() {
    if (!m_saveTimer)
        return;

    if (m_loadFailed) {
        qCWarning(lcConfig) << "Not saving" << m_filePath << "- last load failed";

        // Saves are attempted on every change, so only report the first one
        if (!m_saveBlockedNotified) {
            m_saveBlockedNotified = true;
            emit saveFailed(
                QStringLiteral("Not overwriting %1 until the last load error is fixed").arg(m_filePath), m_screen);
        }

        return;
    }

    m_saveTimer->start();
    m_recentlySaved = true;
    m_cooldownTimer->start();
}

std::optional<QString> RootConfig::reloadFromFile() {
    m_lastSignature = fileSignature();
    m_loadFailed = false;
    m_saveBlockedNotified = false;

    QFile file(m_filePath);

    if (!file.exists()) {
        qCDebug(lcConfig) << "File does not exist:" << m_filePath;
        return std::nullopt;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        markLoadFailed();
        auto err = QStringLiteral("Failed to open %1: %2").arg(m_filePath, file.errorString());
        qCDebug(lcConfig, "%s", qUtf8Printable(err));
        return err;
    }

    QJsonParseError error{};
    auto doc = QJsonDocument::fromJson(file.readAll(), &error);

    if (error.error != QJsonParseError::NoError) {
        markLoadFailed();

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

    loadFromJson(doc.object());

    m_loading = false;

    // Collect unknown keys — caller is responsible for emitting signals
    m_lastUnknownKeys = unknownKeys();

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
