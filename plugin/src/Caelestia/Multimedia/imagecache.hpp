#pragma once

#include <qimage.h>
#include <qnamespace.h>
#include <qsize.h>
#include <qstring.h>

#include <caelestia/utils/cache.hpp>

namespace caelestia::shell::multimedia {

class ImageCache : public utils::FileCache {
public:
    static ImageCache* instance();

    [[nodiscard]] static QSize bucketFor(const QSize& devicePixels);
    [[nodiscard]] static QString keyFor(const QString& path, const QSize& bucket, Qt::AspectRatioMode mode);

    void store(const QString& key, const QString& path, const QSize& bucket, Qt::AspectRatioMode mode);
    void store(const QString& key, const QImage& image, const QSize& bucket, Qt::AspectRatioMode mode);

private:
    explicit ImageCache();
};

} // namespace caelestia::shell::multimedia
