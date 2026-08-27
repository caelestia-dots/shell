#pragma once

#include <qfilesystemwatcher.h>
#include <qjsonvalue.h>
#include <qobject.h>
#include <qtimer.h>

namespace caelestia::settings {

class SettingsFile : public QObject {
    Q_OBJECT

public:
    enum class LoadResult {
        Unchanged,
        Changed,
        ParseError,
        Error
    };

    explicit SettingsFile(const QString& path, QObject* parent = nullptr);

    [[nodiscard]] std::optional<QJsonValue> read() const;
    void write(const QJsonValue& json);

    LoadResult load(bool emitErrors = true);

signals:
    void changed(); // Data changed, not file watcher event
    void readFailed(const QString& error);
    void writeFailed(const QString& error);

private:
    QString m_path;
    QFileSystemWatcher* m_watcher;
    QTimer* m_saveDebounce;
    QTimer* m_loadDebounce;
    int m_loadRetries;
    std::optional<QJsonValue> m_lastData;
    std::optional<QJsonValue> m_pendingWrite;

    void onFileChanged();
    void onDirChanged();

    void initWatcher();
    void scheduleLoad();
    void onLoadDebounced();
    void save();
};

} // namespace caelestia::settings
