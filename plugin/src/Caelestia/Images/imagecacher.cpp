#include "imagecacher.hpp"

#include <qcryptographichash.h>
#include <qdatetime.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qloggingcategory.h>
#include <qmutex.h>
#include <qpainter.h>
#include <qsavefile.h>
#include <qthreadpool.h>
#include <qtimezone.h>

namespace {

Q_LOGGING_CATEGORY(lcCacher, "caelestia.images.cacher", QtInfoMsg)

} // namespace

namespace caelestia::images {

using Qt::StringLiterals::operator""_s;

namespace {

// Cache key from the file's identity rather than its contents: hashing the whole file on
// every lookup meant re-reading every (often multi-MB) source even when cached. Like
// freedesktop thumbnails, a changed file gets a new key through its size and mtime.
QString cacheKeyFor(const QString& path) {
    const QFileInfo info(path);
    if (!info.exists()) {
        qCWarning(lcCacher).noquote() << "cacheKeyFor: file does not exist" << path;
        return {};
    }

    const auto mtime = info.lastModified(QTimeZone::UTC).toMSecsSinceEpoch();
    const auto id = u"%1\n%2\n%3"_s.arg(info.canonicalFilePath(), QString::number(info.size()), QString::number(mtime));
    return QString::fromLatin1(QCryptographicHash::hash(id.toUtf8(), QCryptographicHash::Sha256).toHex());
}

QString fillSuffix(ImageCacher::FillMode fillMode) {
    switch (fillMode) {
    case ImageCacher::FillMode::Crop:
        return u"crop"_s;
    case ImageCacher::FillMode::Fit:
        return u"fit"_s;
    default:
        return u"stretch"_s;
    }
}

} // namespace

const QString& ImageCacher::cacheDir() {
    static const QString k_dir = [] {
        QString cache = qEnvironmentVariable("XDG_CACHE_HOME");
        if (cache.isEmpty())
            cache = QDir::homePath() + u"/.cache"_s;
        return cache + u"/caelestia/imagecache"_s;
    }();
    return k_dir;
}

QString ImageCacher::cachePathFor(const QString& sourcePath, const QSize& size, FillMode fillMode) {
    const QString key = cacheKeyFor(sourcePath);
    if (key.isEmpty())
        return {};

    const QString filename = u"%1@%2x%3-%4.png"_s.arg(
        key, QString::number(size.width()), QString::number(size.height()), fillSuffix(fillMode));

    return cacheDir() + u'/' + filename;
}

ImageCacher* ImageCacher::instance() {
    static ImageCacher s_instance;
    return &s_instance;
}

ImageCacher::ImageCacher(QObject* parent)
    : QObject(parent) {}

void ImageCacher::schedule(const QString& sourcePath, const QSize& size, FillMode fillMode) {
    schedule(sourcePath, cachePathFor(sourcePath, size, fillMode), size, fillMode);
}

void ImageCacher::schedule(const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode) {
    if (cachePath.isEmpty())
        return;

    {
        const QMutexLocker locker(&m_mutex);
        if (m_inflight.contains(cachePath))
            return;
        m_inflight.insert(cachePath);
    }

    QThreadPool::globalInstance()->start([this, sourcePath, cachePath, size, fillMode]() {
        runJob(sourcePath, cachePath, size, fillMode);
        const QMutexLocker locker(&m_mutex);
        // NOLINTNEXTLINE(clang-analyzer-core.CallAndMessage) m_inflight is a value member, not a pointer
        m_inflight.remove(cachePath);
    });
}

void ImageCacher::runJob(const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode) {
    if (QFile::exists(cachePath)) {
        return;
    }

    // Decode no larger than needed to cover the target (cheaper, and avoids holding a full
    // 4K/8K image in memory), the smooth scale below then gives the exact size
    QImageReader reader(sourcePath);
    const QSize sourceSize = reader.size();
    if (sourceSize.isValid() && sourceSize.width() > size.width() && sourceSize.height() > size.height())
        reader.setScaledSize(sourceSize.scaled(size, Qt::KeepAspectRatioByExpanding));

    QImage image = reader.read();
    if (image.isNull()) {
        qCWarning(lcCacher).noquote() << "Failed to decode source" << sourcePath;
        return;
    }

    Qt::AspectRatioMode scaleMode = Qt::IgnoreAspectRatio;
    switch (fillMode) {
    case FillMode::Crop:
        scaleMode = Qt::KeepAspectRatioByExpanding;
        break;
    case FillMode::Fit:
        scaleMode = Qt::KeepAspectRatio;
        break;
    case FillMode::Stretch:
        scaleMode = Qt::IgnoreAspectRatio;
        break;
    }

    image.convertTo(QImage::Format_ARGB32);
    image = image.scaled(size, scaleMode, Qt::SmoothTransformation);

    if (image.isNull()) {
        qCWarning(lcCacher).noquote() << "Failed to scale" << sourcePath;
        return;
    }

    QImage canvas;
    if (fillMode == FillMode::Stretch) {
        canvas = image;
    } else {
        canvas = QImage(size, QImage::Format_ARGB32);
        canvas.fill(Qt::transparent);

        QPainter painter(&canvas);
        painter.drawImage((size.width() - image.width()) / 2, (size.height() - image.height()) / 2, image);
        painter.end();
    }

    const QString parent = QFileInfo(cachePath).absolutePath();
    if (!QDir().mkpath(parent)) {
        qCWarning(lcCacher).noquote() << "Failed to create cache dir" << parent;
        return;
    }

    QSaveFile saveFile(cachePath);
    if (!saveFile.open(QIODevice::WriteOnly) || !canvas.save(&saveFile, "PNG") || !saveFile.commit()) {
        qCWarning(
            lcCacher, "Failed to save to %s: %s", qUtf8Printable(cachePath), qUtf8Printable(saveFile.errorString()));
        return;
    }

    qCDebug(lcCacher).noquote() << "Saved to" << cachePath;
}

} // namespace caelestia::images
