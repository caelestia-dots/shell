#include "settingsfile.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qsavefile.h>

namespace caelestia::settings {

Q_LOGGING_CATEGORY(lcSettingsFile, "caelestia.settings.file", QtInfoMsg)

SettingsFile::SettingsFile(const QString& path, Node* node, QObject* parent)
    : QObject(parent)
    , m_path(path)
    , m_node(node)
    , m_watcher(new QFileSystemWatcher(this))
    , m_saveTimer(new QTimer(this)) {
    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(500); // Save at most once every 500ms
    QObject::connect(m_saveTimer, &QTimer::timeout, this, &SettingsFile::save);

    QObject::connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &SettingsFile::onFileChanged);
    QObject::connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &SettingsFile::onDirChanged);
    QObject::connect(m_node, &Node::needsSave, this, &SettingsFile::onNeedsSave);

    initWatcher();
    load();
}

void SettingsFile::onFileChanged() {
    initWatcher(); // Re-add path in case the file was replaced
    load();
}

void SettingsFile::onDirChanged() {
    // Ignore if the file is already watched
    if (m_watcher->files().contains(m_path))
        return;

    initWatcher();

    if (QFile::exists(m_path))
        load();
}

void SettingsFile::onNeedsSave() {
    if (!m_saveTimer->isActive())
        m_saveTimer->start();
}

void SettingsFile::initWatcher() {
    const QFileInfo info(m_path);
    const auto dir = info.absolutePath();

    if (QDir(dir).exists() && !m_watcher->directories().contains(dir))
        m_watcher->addPath(dir);

    if (info.exists() && !m_watcher->files().contains(m_path))
        m_watcher->addPath(m_path);
}

void SettingsFile::load() {
    QFile file(m_path);

    if (!file.open(QIODevice::ReadOnly)) {
        qCWarning(lcSettingsFile) << "Failed to open" << m_path << "for reading:" << file.errorString();
        return;
    }

    const auto data = file.readAll();
    file.close();

    // Skip loads caused by our own writes
    if (data == m_lastData)
        return;
    m_lastData = data;

    QJsonParseError error;
    const auto doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        qCWarning(lcSettingsFile) << "Failed to parse" << m_path << ":" << error.errorString();
        return;
    }

    qCDebug(lcSettingsFile) << "Loading" << m_path;

    const auto result = m_node->syncJson(doc.isObject() ? QJsonValue(doc.object()) : QJsonValue(doc.array()));

    for (const auto& rejected : result.rejected)
        qCWarning(lcSettingsFile) << "Rejected" << rejected.key << "=" << rejected.value << ":" << rejected.reason;
    for (const auto& unknown : result.unknown)
        qCWarning(lcSettingsFile) << "Unknown option" << unknown;
}

void SettingsFile::save() {
    const auto dir = QFileInfo(m_path).absolutePath();

    if (!QDir().mkpath(dir)) {
        qCWarning(lcSettingsFile) << "Failed to create dir" << dir;
        return;
    }

    const auto json = m_node->toJson();
    const auto doc = json.isObject() ? QJsonDocument(json.toObject()) : QJsonDocument(json.toArray());
    const auto data = doc.toJson();

    // Write atomically
    QSaveFile file(m_path);

    if (!file.open(QIODevice::WriteOnly)) {
        qCWarning(lcSettingsFile) << "Failed to open" << m_path << "for writing:" << file.errorString();
        return;
    }

    file.write(data);

    if (!file.commit()) {
        qCWarning(lcSettingsFile) << "Failed to write" << m_path << ":" << file.errorString();
        return;
    }

    m_lastData = data;
    qCDebug(lcSettingsFile) << "Saved" << m_path;

    initWatcher(); // The file may have just been created, or replaced by the rename
}

} // namespace caelestia::settings
