#include "wavyline.hpp"

#include <qpainter.h>
#include <qpainterpath.h>

namespace caelestia::controls {

WavyLine::WavyLine(QQuickItem* parent)
    : QQuickPaintedItem(parent)
    , m_lineWidth(4)
    , m_amplitudeMultiplier(0.5)
    , m_frequency(6)
    , m_startX(0)
    , m_fullLength(0)
    , m_color(Qt::white)
    , m_waveProgress(0)
    , m_pathType(Linear)
    , m_startAngle(0)
    , m_fullAngle(360)
    , m_radius(-1)
    , m_value(1)
    , m_startAngleRad(0)
    , m_fullAngleRad(2 * M_PI) {
    setAntialiasing(true);
}

int WavyLine::lineWidth() const {
    return m_lineWidth;
}

void WavyLine::setLineWidth(int lineWidth) {
    if (m_lineWidth != lineWidth) {
        m_lineWidth = lineWidth;
        emit lineWidthChanged();
        update();
    }
}

qreal WavyLine::amplitudeMultiplier() const {
    return m_amplitudeMultiplier;
}

void WavyLine::setAmplitudeMultiplier(qreal amplitudeMultiplier) {
    if (!qFuzzyCompare(m_amplitudeMultiplier + 1.0, amplitudeMultiplier + 1.0)) {
        m_amplitudeMultiplier = amplitudeMultiplier;
        emit amplitudeMultiplierChanged();
        update();
    }
}

int WavyLine::frequency() const {
    return m_frequency;
}

void WavyLine::setFrequency(int frequency) {
    if (m_frequency != frequency) {
        m_frequency = frequency;
        emit frequencyChanged();
        update();
    }
}

qreal WavyLine::startX() const {
    return m_startX;
}

void WavyLine::setStartX(qreal startX) {
    if (!qFuzzyCompare(m_startX + 1.0, startX + 1.0)) {
        m_startX = startX;
        emit startXChanged();
        update();
    }
}

qreal WavyLine::fullLength() const {
    return m_fullLength;
}

void WavyLine::setFullLength(qreal fullLength) {
    if (!qFuzzyCompare(m_fullLength + 1.0, fullLength + 1.0)) {
        m_fullLength = fullLength;
        emit fullLengthChanged();
        update();
    }
}

QColor WavyLine::color() const {
    return m_color;
}

void WavyLine::setColor(const QColor& color) {
    if (m_color != color) {
        m_color = color;
        emit colorChanged();
        update();
    }
}

qreal WavyLine::waveProgress() const {
    return m_waveProgress;
}

void WavyLine::setWaveProgress(qreal progress) {
    if (!qFuzzyCompare(m_waveProgress + 1.0, progress + 1.0)) {
        m_waveProgress = progress;
        emit waveProgressChanged();
        update();
    }
}

WavyLine::PathType WavyLine::pathType() const {
    return m_pathType;
}

void WavyLine::setPathType(PathType pathType) {
    if (m_pathType != pathType) {
        m_pathType = pathType;
        emit pathTypeChanged();
        update();
    }
}

qreal WavyLine::startAngle() const {
    return m_startAngle;
}

void WavyLine::setStartAngle(qreal startAngle) {
    if (!qFuzzyCompare(m_startAngle + 1.0, startAngle + 1.0)) {
        m_startAngle = startAngle;
        m_startAngleRad = startAngle * M_PI / 180.0;
        emit startAngleChanged();
        update();
    }
}

qreal WavyLine::fullAngle() const {
    return m_fullAngle;
}

void WavyLine::setFullAngle(qreal fullAngle) {
    if (!qFuzzyCompare(m_fullAngle + 1.0, fullAngle + 1.0)) {
        m_fullAngle = fullAngle;
        m_fullAngleRad = fullAngle * M_PI / 180.0;
        emit fullAngleChanged();
        update();
    }
}

qreal WavyLine::radius() const {
    return m_radius;
}

void WavyLine::setRadius(qreal radius) {
    if (!qFuzzyCompare(m_radius + 1.0, radius + 1.0)) {
        m_radius = radius;
        emit radiusChanged();
        update();
    }
}

qreal WavyLine::value() const {
    return m_value;
}

void WavyLine::setValue(qreal value) {
    if (!qFuzzyCompare(m_value + 1.0, value + 1.0)) {
        m_value = value;
        emit valueChanged();
        update();
    }
}

void WavyLine::paint(QPainter* painter) {
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setPen(QPen(m_color, m_lineWidth, Qt::SolidLine, Qt::RoundCap));

    if (m_pathType == Arc) {
        paintArc(painter);
    } else {
        paintLinear(painter);
    }
}

void WavyLine::paintLinear(QPainter* painter) {
    const auto amplitude = m_lineWidth * m_amplitudeMultiplier;
    const auto phase = m_waveProgress * 2 * M_PI;
    const auto centerY = height() / 2;
    const auto len = m_fullLength > 0 ? m_fullLength : 1;
    const auto start = m_lineWidth / 2.0;
    const auto fullEnd = width() - m_lineWidth / 2.0;
    const auto drawEnd = start + (fullEnd - start) * m_value;

    QPainterPath path;
    bool first = true;

    for (int x = m_lineWidth / 2; x <= drawEnd; ++x) {
        const auto theta = m_frequency * 2 * M_PI * (x + m_startX) / len + phase;
        const auto waveY = centerY + amplitude * qSin(theta);
        if (first) {
            path.moveTo(x, waveY);
            first = false;
        } else {
            path.lineTo(x, waveY);
        }
    }

    painter->drawPath(path);
}

void WavyLine::paintArc(QPainter* painter) {
    if (m_fullAngleRad <= 0) {
        return;
    }

    const auto amplitude = m_lineWidth * m_amplitudeMultiplier;
    const auto cx = width() / 2.0;
    const auto cy = height() / 2.0;
    const auto radius = m_radius > 0 ? m_radius : (qMin(width(), height()) - m_lineWidth - 2 * amplitude) / 2.0;

    if (radius <= 0) {
        return;
    }

    const auto phase = m_waveProgress * 2 * M_PI;
    const auto arcLen = radius * m_fullAngleRad;
    const auto len = m_fullLength > 0 ? m_fullLength : arcLen;
    const auto drawAngleRad = m_fullAngleRad * m_value;

    if (drawAngleRad <= 0) {
        return;
    }

    const auto N = qMax(64, qCeil(radius * drawAngleRad));
    const auto dTheta = drawAngleRad / N;

    QPainterPath path;

    for (int i = 0; i <= N; ++i) {
        const auto theta = m_startAngleRad + i * dTheta;
        const auto s = i * dTheta * radius;
        const auto phi = m_frequency * 2 * M_PI * (s + m_startX) / len + phase;
        const auto r = radius + amplitude * qSin(phi);
        const auto px = cx + r * qCos(theta);
        const auto py = cy + r * qSin(theta);
        if (i == 0) {
            path.moveTo(px, py);
        } else {
            path.lineTo(px, py);
        }
    }

    painter->drawPath(path);
}

} // namespace caelestia::controls
