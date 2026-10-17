#pragma once

#include <qimage.h>
#include <qnamespace.h>
#include <qsize.h>
#include <qstring.h>
#include <qthread.h>
#include <qurl.h>

namespace caelestia::multimedia {

class ImageCacheWorker;

class ImageCache {
public:
    Q_DISABLE_COPY_MOVE(ImageCache)

    static ImageCache* instance();

    [[nodiscard]] static QSize bucketFor(const QSize& devicePixels);
    [[nodiscard]] static QString keyFor(const QString& path, const QSize& bucket, Qt::AspectRatioMode mode);

    [[nodiscard]] QUrl lookup(const QString& key) const;
    void store(const QString& key, const QString& path, const QSize& bucket, Qt::AspectRatioMode mode);
    void store(const QString& key, const QImage& image, const QSize& bucket, Qt::AspectRatioMode mode);

private:
    explicit ImageCache();
    ~ImageCache();

    QString m_dir;
    QThread m_thread;
    ImageCacheWorker* m_worker;
};

} // namespace caelestia::multimedia
