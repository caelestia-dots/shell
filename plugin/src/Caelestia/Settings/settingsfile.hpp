#pragma once

#include <qfilesystemwatcher.h>
#include <qobject.h>
#include <qtimer.h>

#include "node.hpp"

namespace caelestia::settings {

class SettingsFile : public QObject {
    Q_OBJECT

public:
    explicit SettingsFile(const QString& path, Node* node, QObject* parent = nullptr);

private:
    QString m_path;
    Node* m_node;
    QFileSystemWatcher* m_watcher;
    QTimer* m_saveTimer;
    QByteArray m_lastData;

    void onFileChanged();
    void onDirChanged();
    void onNeedsSave();

    void initWatcher();
    void load();
    void save();
};

} // namespace caelestia::settings
