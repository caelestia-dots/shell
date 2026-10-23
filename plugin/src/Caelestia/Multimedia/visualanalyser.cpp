#include "visualanalyser.hpp"

#include <qqmlengine.h>
#include <qquickimageprovider.h>
#include <qsize.h>
#include <qtconcurrentrun.h>

#include "remotecache.hpp"

namespace caelestia::multimedia {

namespace {

constexpr QSize k_providerSize(64, 64);

} // namespace

VisualAnalyser::VisualAnalyser(QObject* parent)
    : QObject(parent) {
    QObject::connect(RemoteCache::instance(), &RemoteCache::updated, this, [this](const QUrl& url, const QUrl& file) {
        if (QUrl(m_source) == url)
            analyse(file.toLocalFile());
    });
}

QString VisualAnalyser::source() const {
    return m_source;
}

void VisualAnalyser::setSource(const QString& source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();

    if (m_complete)
        resolve();
}

void VisualAnalyser::classBegin() {}

void VisualAnalyser::componentComplete() {
    m_complete = true;
    resolve();
}

void VisualAnalyser::resolve() {
    const QUrl url(m_source);
    if (RemoteCache::isRemote(url)) {
        RemoteCache::instance()->fetch(url).then(this, [this, url](const QUrl& file) {
            if (QUrl(m_source) == url)
                analyse(file.toLocalFile());
        });
    } else if (url.scheme() == u"image") {
        analyseProvider(url);
    } else {
        analyse(url.isLocalFile() ? url.toLocalFile() : m_source);
    }
}

void VisualAnalyser::analyse(const QString& path) {
    apply(media::analyseForPath(path));
}

void VisualAnalyser::analyseProvider(const QUrl& url) {
    auto* const engine = qmlEngine(this);
    if (!engine)
        return;

    auto* const base = engine->imageProvider(url.host());
    if (!base)
        return;

    // Keep the ?path= / ?fallback= query, drop only scheme, host and leading slash
    const auto id = url.toString(QUrl::RemoveScheme | QUrl::RemoveAuthority).mid(1);

    if (base->imageType() == QQmlImageProviderBase::Image) {
        auto* const provider = static_cast<QQuickImageProvider*>(base);
        apply(QtConcurrent::run([provider, id] {
            QSize size;
            return media::analyseImage(provider->requestImage(id, &size, k_providerSize));
        }));
    } else if (base->imageType() == QQmlImageProviderBase::Pixmap) {
        auto* const provider = static_cast<QQuickImageProvider*>(base);
        QSize size;
        auto image = provider->requestPixmap(id, &size, k_providerSize).toImage();
        apply(QtConcurrent::run([image = std::move(image)] {
            return media::analyseImage(image);
        }));
    }
}

void VisualAnalyser::apply(QFuture<media::Analysis> future) {
    future.then(this, [this, source = m_source](media::Analysis analysis) {
        if (source != m_source)
            return;

        m_analysis = std::move(analysis);
        emit dominantColourChanged();
        emit luminanceChanged();
    });
}

QColor VisualAnalyser::dominantColour() const {
    return m_analysis.dominant;
}

qreal VisualAnalyser::luminance() const {
    return m_analysis.luminance;
}

} // namespace caelestia::multimedia
