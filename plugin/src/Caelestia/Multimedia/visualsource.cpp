#include "visualsource.hpp"

namespace caelestia::multimedia {

VisualSource::VisualSource(QObject* parent)
    : QObject(parent) {}

VisualSource::Type VisualSource::type() const {
    return m_type;
}

bool VisualSource::ready() const {
    return m_ready;
}

QString VisualSource::source() const {
    return m_source;
}

QUrl VisualSource::imagePath() const {
    return m_imagePath;
}

void VisualSource::setSource(const QString& source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();
}

QSize VisualSource::sourceSize() const {
    return m_sourceSize;
}

void VisualSource::setSourceSize(const QSize& size) {
    if (m_sourceSize == size)
        return;

    m_sourceSize = size;
    emit sourceSizeChanged();
}

bool VisualSource::playing() const {
    return m_playing;
}

void VisualSource::setPlaying(bool playing) {
    if (m_playing == playing)
        return;

    m_playing = playing;
    emit playingChanged();
}

QObject* VisualSource::videoOutput() const {
    return m_videoOutput;
}

void VisualSource::setVideoOutput(QObject* videoOutput) {
    if (m_videoOutput == videoOutput)
        return;

    m_videoOutput = videoOutput;
    emit videoOutputChanged();
}

} // namespace caelestia::multimedia
