#include "imagecache.hpp"

#include <algorithm>

#include "ktxencoder.hpp"

namespace caelestia::shell::multimedia {

using Qt::StringLiterals::operator""_s;

namespace {

constexpr int k_bucket = 256;
constexpr qint64 k_maxBytes = 512ll * 1024 * 1024;
constexpr int k_version = 1;

int roundUp(int value) {
    return std::max(1, (value + k_bucket - 1) / k_bucket) * k_bucket;
}

QByteArray encode(const QImage& image) {
    return image.isNull() ? QByteArray() : ktx::encodeBc3(image);
}

} // namespace

ImageCache* ImageCache::instance() {
    static ImageCache s_instance;
    return &s_instance;
}

ImageCache::ImageCache()
    : FileCache(u"multimedia/image"_s, k_maxBytes, u".ktx"_s, k_version) {}

QSize ImageCache::bucketFor(const QSize& devicePixels) {
    return { roundUp(devicePixels.width()), roundUp(devicePixels.height()) };
}

QString ImageCache::keyFor(const QString& path, const QSize& bucket, Qt::AspectRatioMode mode) {
    return keyForPath(path,
        u"%1x%2|%3"_s.arg(QString::number(bucket.width()), QString::number(bucket.height()), QString::number(mode)));
}

void ImageCache::store(const QString& key, const QString& path, const QSize& bucket, Qt::AspectRatioMode mode) {
    FileCache::store(key, [path, bucket, mode] {
        return encode(ktx::readFitted(path, bucket, mode));
    });
}

void ImageCache::store(const QString& key, const QImage& image, const QSize& bucket, Qt::AspectRatioMode mode) {
    FileCache::store(key, [image, bucket, mode] {
        return encode(ktx::fitted(image, bucket, mode));
    });
}

} // namespace caelestia::shell::multimedia
