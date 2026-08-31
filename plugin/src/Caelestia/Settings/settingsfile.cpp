#include "settingsfile.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qsavefile.h>

namespace caelestia::settings {

Q_LOGGING_CATEGORY(lcSettingsFile, "caelestia.settings.file", QtInfoMsg)

namespace {

// Max retries for loads which fail due to malformed JSON, e.g. partial writes
constexpr int kMaxLoadRetries = 3;

} // namespace

SettingsFile::SettingsFile(const QString& path, QObject* parent)
    : QObject(parent)
    , m_path(path)
    , m_watcher(new QFileSystemWatcher(this))
    , m_saveDebounce(new QTimer(this))
    , m_loadDebounce(new QTimer(this))
    , m_loadRetries(0) {
    m_saveDebounce->setSingleShot(true);
    m_saveDebounce->setInterval(500); // Save at most once every 500ms

    m_loadDebounce->setSingleShot(true);
    m_loadDebounce->setInterval(50); // Coalesce watcher events within 50ms
    QObject::connect(m_loadDebounce, &QTimer::timeout, this, &SettingsFile::onLoadDebounced);

    QObject::connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &SettingsFile::onFileChanged);
    QObject::connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &SettingsFile::onDirChanged);

    initWatcher();
}

std::optional<QJsonValue> SettingsFile::read() const {
    return m_lastData;
}

void SettingsFile::write(const QJsonValue& json) {
    m_pendingWrite = json;
    save();
}

void SettingsFile::onFileChanged() {
    initWatcher(); // Re-add path in case the file was replaced
    scheduleLoad();
}

void SettingsFile::onDirChanged() {
    // Ignore if the file is already watched
    if (m_watcher->files().contains(m_path))
        return;

    initWatcher();

    if (QFile::exists(m_path))
        scheduleLoad();
}

void SettingsFile::initWatcher() {
    const QFileInfo info(m_path);
    const auto dir = info.absolutePath();

    if (QDir(dir).exists() && !m_watcher->directories().contains(dir))
        m_watcher->addPath(dir);

    if (info.exists() && !m_watcher->files().contains(m_path))
        m_watcher->addPath(m_path);
}

void SettingsFile::scheduleLoad() {
    // Ignore if a load is already pending
    if (m_loadDebounce->isActive())
        return;

    m_loadRetries = 0;
    m_loadDebounce->start();
}

void SettingsFile::onLoadDebounced() {
    const auto isFinalTry = m_loadRetries >= kMaxLoadRetries;

    if (load(isFinalTry) == LoadResult::ParseError && !isFinalTry) {
        // Likely a partial write, retry after another debounce
        ++m_loadRetries;
        qCDebug(lcSettingsFile, "Retrying load of %s (%d/%d)", qUtf8Printable(m_path), m_loadRetries, kMaxLoadRetries);
        m_loadDebounce->start();
    }
}

SettingsFile::LoadResult SettingsFile::load(bool reportErrors) {
    QFile file(m_path);

    if (!file.exists()) {
        if (m_lastData) {
            m_lastData = std::nullopt;
            emit changed();
            return LoadResult::Changed;
        }
        return LoadResult::Unchanged;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qCWarning(lcSettingsFile, "Failed to open %s for reading: %s", qUtf8Printable(m_path),
            qUtf8Printable(file.errorString()));
        emit readFailed(QStringLiteral("Failed to open: %1").arg(file.errorString()));
        return LoadResult::Error;
    }

    const auto data = file.readAll();
    file.close();

    QJsonParseError error;
    const auto doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        if (reportErrors) {
            qCWarning(lcSettingsFile, "Failed to parse %s as JSON: %s", qUtf8Printable(m_path),
                qUtf8Printable(error.errorString()));
            emit readFailed(QStringLiteral("Failed to parse: %1").arg(error.errorString()));
        } else {
            qCDebug(lcSettingsFile, "Failed to parse %s as JSON: %s", qUtf8Printable(m_path),
                qUtf8Printable(error.errorString()));
        }
        return LoadResult::ParseError;
    }

    const auto json = doc.isObject() ? QJsonValue(doc.object()) : QJsonValue(doc.array());

    if (json == m_lastData)
        return LoadResult::Unchanged;

    // Clear pending write, stuff loaded from file should take precedence
    m_pendingWrite = std::nullopt;

    m_lastData = json;
    emit changed();

    qCDebug(lcSettingsFile) << "Read JSON from" << m_path;
    qCDebug(lcSettingsFile) << " " << json;

    return LoadResult::Changed;
}

void SettingsFile::save() {
    if (!m_pendingWrite)
        return;

    if (m_saveDebounce->isActive()) {
        // Queue save for debounce end
        QObject::connect(m_saveDebounce, &QTimer::timeout, this, &SettingsFile::save,
            static_cast<Qt::ConnectionType>(Qt::UniqueConnection | Qt::SingleShotConnection));
        return;
    }

    // Debounce regardless of whether the save actually succeeded
    m_saveDebounce->start();

    const auto json = m_pendingWrite.value();
    const auto data = (json.isObject() ? QJsonDocument(json.toObject()) : QJsonDocument(json.toArray())).toJson();
    m_pendingWrite = std::nullopt;

    const auto dir = QFileInfo(m_path).absolutePath();

    if (!QDir().mkpath(dir)) {
        qCWarning(lcSettingsFile) << "Failed to create dir" << dir;
        emit writeFailed(QStringLiteral("Failed to create parent directory"));
        return;
    }

    // Write atomically
    QSaveFile file(m_path);

    if (!file.open(QIODevice::WriteOnly)) {
        qCWarning(lcSettingsFile, "Failed to open %s for writing: %s", qUtf8Printable(m_path),
            qUtf8Printable(file.errorString()));
        emit writeFailed(QStringLiteral("Failed to open: %1").arg(file.errorString()));
        return;
    }

    file.write(data);

    if (!file.commit()) {
        qCWarning(lcSettingsFile, "Failed to write %s: %s", qUtf8Printable(m_path), qUtf8Printable(file.errorString()));
        emit writeFailed(QStringLiteral("Failed to write: %1").arg(file.errorString()));
        return;
    }

    m_lastData = json;
    qCDebug(lcSettingsFile) << "Saved" << m_path;

    initWatcher(); // The file may have just been created, or replaced by the rename
}

} // namespace caelestia::settings
