#include "visualsource.hpp"

namespace caelestia::multimedia {

VisualSource::VisualSource(QObject* parent)
    : QObject(parent) {}

VisualSource::Type VisualSource::type() const {
    return m_type;
}

bool VisualSource::videoReady() const {
    return m_videoReady;
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

bool VisualSource::playing() const {
    return m_playing;
}

void VisualSource::setPlaying(bool playing) {
    if (m_playing == playing)
        return;

    m_playing = playing;
    emit playingChanged();
}

VisualSource::FillMode VisualSource::fillMode() const {
    return m_fillMode;
}

void VisualSource::setFillMode(FillMode fillMode) {
    if (m_fillMode == fillMode)
        return;

    m_fillMode = fillMode;
    emit fillModeChanged();
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

QQuickItem* VisualSource::sizeSource() const {
    return m_sizeSource;
}

void VisualSource::setSizeSource(QQuickItem* sizeSource) {
    if (m_sizeSource == sizeSource)
        return;

    m_sizeSource = sizeSource;
    emit sizeSourceChanged();
}

} // namespace caelestia::multimedia
