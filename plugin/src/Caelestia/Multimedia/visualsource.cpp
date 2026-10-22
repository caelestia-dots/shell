#include "visualsource.hpp"

#include <qmimedatabase.h>
#include <qquickwindow.h>
#include <qvideosink.h>

#include "imagecache.hpp"

namespace caelestia::multimedia {

using Qt::StringLiterals::operator""_s;

VisualSource::VisualSource(QObject* parent)
    : QObject(parent) {
    m_player.setLoops(QMediaPlayer::Infinite);
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

    const auto path = localPath();
    const auto provider = QUrl(m_source).scheme() == u"image"_s;
    const auto mime = path.isEmpty() || provider ? QString() : QMimeDatabase().mimeTypeForFile(path).name();
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
    QObject::disconnect(m_windowConn);

    m_sizeSource = sizeSource;
    emit sizeSourceChanged();

    if (m_sizeSource) {
        QObject::connect(m_sizeSource, &QQuickItem::widthChanged, this, &VisualSource::refresh);
        QObject::connect(m_sizeSource, &QQuickItem::heightChanged, this, &VisualSource::refresh);
        QObject::connect(m_sizeSource, &QQuickItem::windowChanged, this, &VisualSource::watchWindow);
        watchWindow(m_sizeSource->window());
    }
    refresh();
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

void VisualSource::setImagePath(const QUrl& imagePath) {
    if (m_imagePath == imagePath)
        return;

    m_imagePath = imagePath;
    emit imagePathChanged();
}

void VisualSource::watchWindow(QQuickWindow* window) {
    QObject::disconnect(m_windowConn);
    if (window)
        m_windowConn = QObject::connect(window, &QWindow::screenChanged, this, &VisualSource::refresh);
    refresh();
}

void VisualSource::refresh() {
    const auto path = localPath();
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

    auto* const cache = ImageCache::instance();
    const auto bucket = ImageCache::bucketFor((m_sizeSource->size() * window->devicePixelRatio()).toSize());
    const auto key = ImageCache::keyFor(path, bucket, aspectMode());
    if (key == m_key)
        return;

    m_key = key;
    m_bucket = bucket;
    setSourceSize(bucket);
    const auto cached = cache->lookup(key);

    if (m_type == Type::Live) {
        setImagePath(m_videoReady ? QUrl() : cached);
        return;
    }

    if (cached.isEmpty()) {
        cache->store(key, path, bucket, aspectMode());
        setImagePath(QUrl::fromLocalFile(path));
    } else {
        setImagePath(cached);
    }
}

void VisualSource::onVideoFrame(const QVideoFrame& frame) {
    if (m_videoReady)
        return;

    setVideoReady(true);
    setImagePath({});

    if (!m_key.isEmpty() && ImageCache::instance()->lookup(m_key).isEmpty())
        ImageCache::instance()->store(m_key, frame.toImage(), m_bucket, aspectMode());
}

void VisualSource::syncPlayer() {
    const auto url = m_type == Type::Live ? QUrl::fromLocalFile(localPath()) : QUrl();
    if (m_player.source() != url)
        m_player.setSource(url);

    if (m_playing && !url.isEmpty())
        m_player.play();
    else
        m_player.pause();
}

QString VisualSource::localPath() const {
    const QUrl url(m_source);
    return url.isLocalFile() ? url.toLocalFile() : m_source;
}

QUrl VisualSource::rawUrl() const {
    const QUrl url(m_source);
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

} // namespace caelestia::multimedia
