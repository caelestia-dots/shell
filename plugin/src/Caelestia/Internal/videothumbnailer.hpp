#pragma once

#include <QObject>
#include <QQuickItem>
#include <QUrl>
#include <QSize>

namespace caelestia::internal {

class VideoThumbnailer : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged REQUIRED)
    Q_PROPERTY(QUrl cacheDir READ cacheDir WRITE setCacheDir NOTIFY cacheDirChanged REQUIRED)
    Q_PROPERTY(QUrl cachePath READ cachePath NOTIFY cachePathChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)

public:
    explicit VideoThumbnailer(QObject* parent = nullptr);

    QString path() const;
    void setPath(const QString& path);

    QUrl cacheDir() const;
    void setCacheDir(const QUrl& dir);

    QUrl cachePath() const;
    bool ready() const;

signals:
    void pathChanged();
    void cacheDirChanged();
    void cachePathChanged();
    void readyChanged();

private:
    QString m_path;
    QUrl m_cacheDir;
    QUrl m_cachePath;
    bool m_ready = false;

    void generateThumbnail(const QString& path, const QString& cacheFile);
    QString sha256sum(const QString& path) const;
};

} // namespace caelestia::internal
