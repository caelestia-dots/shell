#pragma once

#include <QHash>
#include <QObject>
#include <QQuickItem>
#include <QSize>
#include <QThread>
#include <QTimer>
#include <QUrl>

namespace caelestia::internal {

class VideoThumbnailer : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged REQUIRED)
    Q_PROPERTY(QUrl cacheDir READ cacheDir WRITE setCacheDir NOTIFY cacheDirChanged REQUIRED)
    Q_PROPERTY(QString cachePath READ cachePath NOTIFY cachePathChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)

public:
    explicit VideoThumbnailer(QObject* parent = nullptr);
    ~VideoThumbnailer();

    QString path() const;
    void setPath(const QString& path);

    QUrl cacheDir() const;
    void setCacheDir(const QUrl& dir);

    QString cachePath() const;
    bool ready() const;

signals:
    void pathChanged();
    void cacheDirChanged();
    void cachePathChanged();
    void readyChanged();

private slots:
    void startProcessing();
    void handleWorkerFinished(const QString& cachePath);

private:
    QString m_path;
    QUrl m_cacheDir;
    QString m_cachePath;
    bool m_ready = false;

    QTimer m_debounceTimer;

    class Worker;
    QThread* m_workerThread = nullptr;

    static QHash<QString, QString> s_memoryCache;
};

} // namespace caelestia::internal
