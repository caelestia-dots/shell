#include "visual.hpp"

namespace caelestia::multimedia {

Visual::Visual(QQuickItem* parent)
    : QQuickItem(parent) {}

Visual::Type Visual::type() const {
    return m_type;
}

bool Visual::ready() const {
    return m_ready;
}

QString Visual::source() const {
    return m_source;
}

void Visual::setSource(const QString& source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();
}

bool Visual::playing() const {
    return m_playing;
}

void Visual::setPlaying(bool playing) {
    if (m_playing == playing)
        return;

    m_playing = playing;
    emit playingChanged();
}

QObject* Visual::videoOutput() const {
    return m_videoOutput;
}

void Visual::setVideoOutput(QObject* videoOutput) {
    if (m_videoOutput == videoOutput)
        return;

    m_videoOutput = videoOutput;
    emit videoOutputChanged();
}

} // namespace caelestia::multimedia
