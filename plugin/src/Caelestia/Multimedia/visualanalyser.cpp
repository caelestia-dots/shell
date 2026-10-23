#include "visualanalyser.hpp"

namespace caelestia::multimedia {

VisualAnalyser::VisualAnalyser(QObject* parent)
    : QObject(parent) {}

QString VisualAnalyser::source() const {
    return m_source;
}

void VisualAnalyser::setSource(const QString& source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();

    media::analyseForPath(m_source).then(this, [this](media::Analysis analysis) {
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
