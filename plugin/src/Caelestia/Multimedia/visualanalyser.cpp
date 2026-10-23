#include "visualanalyser.hpp"

#include <qurl.h>

#include "remotecache.hpp"

namespace caelestia::multimedia {

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

    const QUrl url(m_source);
    if (RemoteCache::isRemote(url)) {
        RemoteCache::instance()->fetch(url).then(this, [this, url](const QUrl& file) {
            if (QUrl(m_source) == url)
                analyse(file.toLocalFile());
        });
    } else {
        analyse(url.isLocalFile() ? url.toLocalFile() : m_source);
    }
}

void VisualAnalyser::analyse(const QString& path) {
    media::analyseForPath(path).then(this, [this, source = m_source](media::Analysis analysis) {
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
