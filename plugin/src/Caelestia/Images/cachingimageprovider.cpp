#include "cachingimageprovider.hpp"

#include "imagecacher.hpp"

#include <qfileinfo.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qloggingcategory.h>
#include <qrunnable.h>
#include <qthreadpool.h>

Q_LOGGING_CATEGORY(lcCProv, "caelestia.images.cacheprovider", QtInfoMsg)

namespace caelestia::images {

namespace {

class CachingImageResponse final : public QQuickImageResponse, public QRunnable {
public:
    CachingImageResponse(const QString& id, const QSize& requestedSize, ImageCacher::FillMode fillMode)
        : m_id(id)
        , m_requestedSize(requestedSize)
        , m_fillMode(fillMode) {
        setAutoDelete(false);
    }

    [[nodiscard]] QQuickTextureFactory* textureFactory() const override {
        return QQuickTextureFactory::textureFactoryForImage(m_image);
    }

    [[nodiscard]] QString errorString() const override { return m_error; }

    void run() override {
        process();
        emit finished();
    }

private:
    // Try to load an image from disk, set m_error / return false on miss.
    bool loadInto(const QString& path, QImage& out) {
        if (!QFileInfo::exists(path))
            return false;
        QImage img(path);
        if (img.isNull())
            return false;
        out = img;
        return true;
    }

    void process() {
        QString path = QString::fromUtf8(m_id.toUtf8().percentDecoded());
        if (!path.startsWith(QLatin1Char('/')))
            path.prepend(QLatin1Char('/'));

        if (!QFileInfo::exists(path)) {
            m_error = QStringLiteral("Source file does not exist: ") + path;
            qCWarning(lcCProv).noquote() << m_error;
            return;
        }

        QSize size = m_requestedSize;
        const bool needsW = size.width() <= 0;
        const bool needsH = size.height() <= 0;

        // If both dimensions are missing, the cache key is identity-only —
        // decode the source directly.
        if (needsW && needsH) {
            qCDebug(lcCProv).noquote() << "Given source size is invalid, returning original:" << path;
            if (!loadInto(path, m_image))
                m_error = QStringLiteral("Failed to decode source: ") + path;
            return;
        }

        // If one dimension is missing, derive it from the source aspect ratio.
        // For videos Qt's QImageReader can't decode, so probe via ffprobe-less
        // means: try cached first, otherwise skip derived sizing.
        if (needsW || needsH) {
            if (ImageCacher::isVideoLike(path)) {
                // Videos: keep the missing dimension at the requested value so
                // ffmpeg scales cleanly; the cachePath stays stable.
                if (needsW)
                    size.setWidth(size.height() > 0 ? size.height() : 1);
                else
                    size.setHeight(size.width() > 0 ? size.width() : 1);
            } else {
                const QImageReader sourceReader(path);
                const QSize sourceSize = sourceReader.size();
                if (!sourceSize.isValid() || sourceSize.isEmpty()) {
                    m_error = QStringLiteral("Could not determine source size for: ") + path;
                    qCWarning(lcCProv).noquote() << m_error;
                    return;
                }
                if (needsW)
                    size.setWidth(qRound(size.height() * sourceSize.width() / static_cast<qreal>(sourceSize.height())));
                else
                    size.setHeight(qRound(size.width() * sourceSize.height() / static_cast<qreal>(sourceSize.width())));
            }
        }

        const QString cachePath = ImageCacher::cachePathFor(path, size, m_fillMode);
        if (cachePath.isEmpty()) {
            m_error = QStringLiteral("Failed to compute cache path for: ") + path;
            return;
        }

        // Fast path: cache already has a valid PNG.
        if (loadInto(cachePath, m_image))
            return;

        // For video/large-image sources we can't defer: QImage("video.mp4")
        // returns null, so the Image would receive nothing in this response.
        // Run the job synchronously here (we're already on a worker thread,
        // so blocking this thread is fine and only delays the first paint).
        if (ImageCacher::isVideoLike(path)) {
            ImageCacher::runJob(path, cachePath, size, m_fillMode);
            if (loadInto(cachePath, m_image))
                return;
            m_error = QStringLiteral("Failed to render video frame for: ") + path;
            qCWarning(lcCProv).noquote() << m_error;
            return;
        }

        // Image path: kick off background caching for next time, but reply
        // now with the original so the user doesn't see an empty box.
        ImageCacher::instance()->schedule(path, cachePath, size, m_fillMode);

        if (!loadInto(path, m_image))
            m_error = QStringLiteral("Failed to decode source: ") + path;
    }

    QString m_id;
    QSize m_requestedSize;
    ImageCacher::FillMode m_fillMode;
    QImage m_image;
    QString m_error;
};

} // namespace

CachingImageProvider::CachingImageProvider(FillMode fillMode)
    : m_fillMode(fillMode) {}

QQuickImageResponse* CachingImageProvider::requestImageResponse(const QString& id, const QSize& requestedSize) {
    auto* const response = new CachingImageResponse(id, requestedSize, m_fillMode);
    QThreadPool::globalInstance()->start(response);
    return response;
}

} // namespace caelestia::images
