#include "arcgauge.hpp"

#include <QtMath>
#include <qpainter.h>
#include <qpen.h>

namespace caelestia::internal {

ArcGauge::ArcGauge(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    setAntialiasing(true);
}

void ArcGauge::paint(QPainter* painter) {
    const qreal w = width();
    const qreal h = height();
    const qreal side = qMin(w, h);
    const qreal radius = (side - m_lineWidth - 2.0) / 2.0;
    const qreal cx = w / 2.0;
    const qreal cy = h / 2.0;

    const QRectF arcRect(cx - radius, cy - radius, radius * 2.0, radius * 2.0);

    // Convert from Canvas convention (CW radians from 3 o'clock) to QPainter (CCW 1/16th degrees)
    const int startAngle16 = qRound(-(m_startAngle * 180.0 / M_PI) * 16.0);
    const int sweepAngle16 = qRound(-(m_sweepAngle * 180.0 / M_PI) * 16.0);

    painter->setRenderHint(QPainter::Antialiasing, true);

    // Draw track arc
    QPen trackPen(m_trackColor, m_lineWidth);
    trackPen.setCapStyle(Qt::RoundCap);
    painter->setPen(trackPen);
    painter->setBrush(Qt::NoBrush);
    painter->drawArc(arcRect, startAngle16, sweepAngle16);

    // Draw value arc
    if (m_percentage > 0.0) {
        const int valueSweep16 = qRound(static_cast<qreal>(sweepAngle16) * m_percentage);
        QPen valuePen(m_accentColor, m_lineWidth);
        valuePen.setCapStyle(Qt::RoundCap);
        painter->setPen(valuePen);
        painter->drawArc(arcRect, startAngle16, valueSweep16);
    }
}

qreal ArcGauge::percentage() const {
    return m_percentage;
}

void ArcGauge::setPercentage(qreal percentage) {
    if (qFuzzyCompare(m_percentage, percentage))
        return;
    m_percentage = percentage;
    emit percentageChanged();
    update();
}

QColor ArcGauge::accentColor() const {
    return m_accentColor;
}

void ArcGauge::setAccentColor(const QColor& color) {
    if (m_accentColor == color)
        return;
    m_accentColor = color;
    emit accentColorChanged();
    update();
}

QColor ArcGauge::trackColor() const {
    return m_trackColor;
}

void ArcGauge::setTrackColor(const QColor& color) {
    if (m_trackColor == color)
        return;
    m_trackColor = color;
    emit trackColorChanged();
    update();
}

qreal ArcGauge::startAngle() const {
    return m_startAngle;
}

void ArcGauge::setStartAngle(qreal angle) {
    if (qFuzzyCompare(m_startAngle, angle))
        return;
    m_startAngle = angle;
    emit startAngleChanged();
    update();
}

qreal ArcGauge::sweepAngle() const {
    return m_sweepAngle;
}

void ArcGauge::setSweepAngle(qreal angle) {
    if (qFuzzyCompare(m_sweepAngle, angle))
        return;
    m_sweepAngle = angle;
    emit sweepAngleChanged();
    update();
}

qreal ArcGauge::lineWidth() const {
    return m_lineWidth;
}

void ArcGauge::setLineWidth(qreal width) {
    if (qFuzzyCompare(m_lineWidth, width))
        return;
    m_lineWidth = width;
    emit lineWidthChanged();
    update();
}

} // namespace caelestia::internal
