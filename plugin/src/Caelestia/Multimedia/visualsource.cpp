#include "visualsource.hpp"

#include <qcoreevent.h>
#include <qmimedatabase.h>
#include <qquickwindow.h>
#include <qscopeguard.h>
#include <qvideosink.h>

#include "imagecache.hpp"
#include "ktxencoder.hpp"
#include "remotecache.hpp"

namespace caelestia::shell::multimedia {

using Qt::StringLiterals::operator""_s;

VisualSource::VisualSource(QObject* parent)
    : QObject(parent) {
    m_player.setLoops(QMediaPlayer::Infinite);
    QObject::connect(&m_player, &QMediaPlayer::mediaStatusChanged, this, &VisualSource::onMediaStatusChanged);
    QObject::connect(RemoteCache::instance(), &RemoteCache::updated, this, [this](const QUrl& url, const QUrl& file) {
        if (QUrl(m_source) == url)
            setLocalPath(file.toLocalFile());
    });
}

VisualSource::Type VisualSource::type() const {
    return m_type;
}

bool VisualSource::videoReady() const {
    return m_videoReady;
}

QSize VisualSource::sourceSize() const {
    return m_sourceSize;
}

QRectF VisualSource::imageRect() const {
    return m_imageRect;
}

QUrl VisualSource::imagePath() const {
    return m_imagePath;
}

QString VisualSource::source() const {
    return m_source;
}

void VisualSource::setSource(const QString& source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();

    const QUrl url(m_source);
    if (RemoteCache::isRemote(url)) {
        m_localPath.clear();
        load();
        RemoteCache::instance()->fetch(url).then(this, [this, url](const QUrl& file) {
            if (QUrl(m_source) == url)
                setLocalPath(file.toLocalFile());
        });
    } else {
        m_localPath = url.isLocalFile() ? url.toLocalFile() : m_source;
        load();
    }
}

void VisualSource::setLocalPath(const QString& path) {
    if (m_localPath == path)
        return;

    m_localPath = path;
    load();
}

void VisualSource::load() {
    const auto provider = QUrl(m_source).scheme() == u"image"_s;
    const auto mime =
        m_localPath.isEmpty() || provider ? QString() : QMimeDatabase().mimeTypeForFile(m_localPath).name();
    // We don't use the mime type for svg checking because Qt doesn't.
    // See QQuickPixmap::isScalableImageFormat.
    const auto prettyPath = QUrl(m_source).path(QUrl::PrettyDecoded);
    m_scalable =
        provider || prettyPath.endsWith(u"svg"_s) || prettyPath.endsWith(u"svgz"_s) || prettyPath.endsWith(u"pdf"_s);

    if (mime.startsWith(u"video/"_s))
        setType(Type::Live);
    else if (provider || mime.startsWith(u"image/"_s) || mime == u"application/pdf"_s)
        setType(Type::Still);
    else
        setType(Type::Unknown);

    ++m_generation;
    setVideoReady(false);
    m_key.clear();
    m_textureSize = {};
    m_preview.clear();
    m_position = 0;
    refresh();
    syncPlayer();
}

bool VisualSource::playing() const {
    return m_playing;
}

void VisualSource::setPlaying(bool playing) {
    if (m_playing == playing)
        return;

    m_playing = playing;
    emit playingChanged();
    syncPlayer();
}

VisualSource::FillMode VisualSource::fillMode() const {
    return m_fillMode;
}

void VisualSource::setFillMode(FillMode fillMode) {
    if (m_fillMode == fillMode)
        return;

    m_fillMode = fillMode;
    emit fillModeChanged();
    refresh();
}

QObject* VisualSource::videoOutput() const {
    return m_videoOutput;
}

void VisualSource::setVideoOutput(QObject* videoOutput) {
    if (m_videoOutput == videoOutput)
        return;

    QObject::disconnect(m_sinkConn);
    m_videoOutput = videoOutput;
    emit videoOutputChanged();

    m_player.setVideoOutput(m_videoOutput);
    if (const auto* sink = m_player.videoSink())
        m_sinkConn = QObject::connect(
            sink, &QVideoSink::videoFrameChanged, this,
            [this](const QVideoFrame& frame) {
                if (!frame.isValid())
                    return;

                QMetaObject::invokeMethod(
                    this,
                    [this, frame, generation = m_generation.load()] {
                        if (generation == m_generation && m_type == Type::Live)
                            onVideoFrame(frame);
                    },
                    Qt::QueuedConnection);
            },
            Qt::DirectConnection);
}

QQuickItem* VisualSource::sizeSource() const {
    return m_sizeSource;
}

void VisualSource::setSizeSource(QQuickItem* sizeSource) {
    if (m_sizeSource == sizeSource)
        return;

    if (m_sizeSource)
        QObject::disconnect(m_sizeSource, nullptr, this, nullptr);

    m_sizeSource = sizeSource;
    emit sizeSourceChanged();

    if (m_sizeSource) {
        QObject::connect(m_sizeSource, &QQuickItem::widthChanged, this, &VisualSource::refresh);
        QObject::connect(m_sizeSource, &QQuickItem::heightChanged, this, &VisualSource::refresh);
        QObject::connect(m_sizeSource, &QQuickItem::windowChanged, this, &VisualSource::watchWindow);
    }
    watchWindow(m_sizeSource ? m_sizeSource->window() : nullptr);
}

bool VisualSource::eventFilter(QObject* watched, QEvent* event) {
    if (event->type() == QEvent::DevicePixelRatioChange)
        refresh();
    return QObject::eventFilter(watched, event);
}

void VisualSource::setType(Type type) {
    if (m_type == type)
        return;

    m_type = type;
    emit typeChanged();
}

void VisualSource::setVideoReady(bool videoReady) {
    if (m_videoReady == videoReady)
        return;

    m_videoReady = videoReady;
    emit videoReadyChanged();
}

void VisualSource::setSourceSize(const QSize& sourceSize) {
    if (m_sourceSize == sourceSize)
        return;

    m_sourceSize = sourceSize;
    emit sourceSizeChanged();
}

// Covers the item unless a crop can map the texture 1:1 onto device pixels
void VisualSource::updateImageRect() {
    QRectF rect;
    if (m_sizeSource) {
        const auto size = m_sizeSource->size();
        const auto* window = m_sizeSource->window();
        rect.setSize(size);

        if (window && !m_textureSize.isEmpty() && m_fillMode == FillMode::PreserveAspectCrop) {
            const auto dpr = window->devicePixelRatio();
            // Truncate the overflow like the cached crop does
            const QPoint origin(
                qRound((size.width() * dpr - m_bucket.width()) / 2) - (m_textureSize.width() - m_bucket.width()) / 2,
                qRound((size.height() * dpr - m_bucket.height()) / 2) -
                    (m_textureSize.height() - m_bucket.height()) / 2);
            rect = QRectF(QPointF(origin) / dpr, QSizeF(m_textureSize) / dpr);
        }
    }

    if (m_imageRect == rect)
        return;

    m_imageRect = rect;
    emit imageRectChanged();
}

void VisualSource::setImagePath(const QUrl& imagePath) {
    if (m_imagePath == imagePath)
        return;

    m_imagePath = imagePath;
    emit imagePathChanged();
}

void VisualSource::watchWindow(QQuickWindow* window) {
    QObject::disconnect(m_windowConn);
    if (m_window)
        m_window->removeEventFilter(this);

    m_window = window;
    if (window) {
        m_windowConn = QObject::connect(window, &QWindow::screenChanged, this, &VisualSource::refresh);
        window->installEventFilter(this);
    }
    refresh();
}

void VisualSource::refresh() {
    const auto updateRect = qScopeGuard([this] {
        updateImageRect();
    });

    const auto& path = m_localPath;
    if (path.isEmpty()) {
        setImagePath({});
        return;
    }

    if (!m_sizeSource) {
        setSourceSize({});
        setImagePath(m_type == Type::Live ? QUrl() : rawUrl());
        return;
    }

    const auto* window = m_sizeSource->window();
    if (!window || m_sizeSource->size().isEmpty())
        return;

    if (m_scalable || m_type == Type::Unknown) {
        setSourceSize(m_scalable ? m_sizeSource->size().toSize() : QSize());
        setImagePath(rawUrl());
        return;
    }

    const auto bucket = ImageCache::bucketFor((m_sizeSource->size() * window->devicePixelRatio()).toSize());
    const auto key = ImageCache::keyFor(path, bucket, aspectMode());
    if (key != m_key) {
        m_key = key;
        m_bucket = bucket;
        loadBucket(bucket);
    }
}

void VisualSource::loadBucket(const QSize& bucket) {
    auto* const cache = ImageCache::instance();
    const auto& path = m_localPath;
    const auto cached = cache->lookupSync(m_key);

    m_textureSize = bucket;

    if (m_type == Type::Live) {
        setSourceSize(bucket);
        m_preview = cached;
        setImagePath(m_videoReady ? QUrl() : cached);
        syncPlayer();
        return;
    }

    if (cached.isEmpty()) {
        cache->store(m_key, path, bucket, aspectMode());
        // Qt decodes the whole image, and scales before it transforms
        const auto cover = ktx::coverFor(path, bucket);
        if (m_fillMode == FillMode::PreserveAspectCrop && cover.size.isValid())
            m_textureSize = cover.size;
        setSourceSize(cover.transposed ? bucket.transposed() : bucket);
        setImagePath(QUrl::fromLocalFile(path));
    } else {
        setSourceSize(bucket);
        setImagePath(cached);
    }
}

void VisualSource::onVideoFrame(const QVideoFrame& frame) {
    if (m_videoReady && m_playing)
        return;

    setVideoReady(true);
    setImagePath({});

    ImageCache::instance()->store(m_key, frame.toImage(), m_bucket, aspectMode());

    if (!m_playing)
        unload();
}

void VisualSource::onMediaStatusChanged(QMediaPlayer::MediaStatus status) {
    // Stopping also reports LoadedMedia, so only react to loads started here
    if (status != QMediaPlayer::LoadedMedia || !m_loading)
        return;

    m_loading = false;
    if (m_position > 0)
        m_player.setPosition(m_position);

    if (m_playing)
        m_player.play();
    else
        m_player.pause();
}

void VisualSource::syncPlayer() {
    const auto url = m_type == Type::Live ? QUrl::fromLocalFile(m_localPath) : QUrl();
    if (!m_player.source().isEmpty() && m_player.source() != url)
        unload();

    if (url.isEmpty())
        return;

    if (m_player.source() == url) {
        if (m_loading)
            return;

        if (m_playing) {
            m_player.play();
        } else if (m_videoReady) {
            m_position = m_player.position();
            unload();
        }

        return;
    }

    const auto previewPending = m_sizeSource && m_key.isEmpty();
    if (m_playing || (!previewPending && m_preview.isEmpty())) {
        m_loading = true;
        m_player.setSource(url);
    }
}

void VisualSource::unload() {
    if (m_player.source().isEmpty())
        return;

    ++m_generation;
    m_player.setSource({});
}

QUrl VisualSource::rawUrl() const {
    const QUrl url(m_source);
    if (RemoteCache::isRemote(url))
        return QUrl::fromLocalFile(m_localPath);
    return url.isLocalFile() || !url.scheme().isEmpty() ? url : QUrl::fromLocalFile(m_source);
}

Qt::AspectRatioMode VisualSource::aspectMode() const {
    switch (m_fillMode) {
    case FillMode::Stretch:
        return Qt::IgnoreAspectRatio;
    case FillMode::PreserveAspectFit:
        return Qt::KeepAspectRatio;
    case FillMode::PreserveAspectCrop:
        return Qt::KeepAspectRatioByExpanding;
    }

    Q_UNREACHABLE_RETURN(Qt::IgnoreAspectRatio);
}

} // namespace caelestia::shell::multimedia
