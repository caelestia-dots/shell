#include "sparklineitem.hpp"

#include <qpainter.h>
#include <qpainterpath.h>
#include <qpen.h>

namespace caelestia::internal {

SparklineItem::SparklineItem(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    setAntialiasing(true);
}

void SparklineItem::paint(QPainter* painter) {
    const bool has1 = m_line1 && m_line1->count() >= 2;
    const bool has2 = m_line2 && m_line2->count() >= 2;
    if (!has1 && !has2)
        return;

    painter->setRenderHint(QPainter::Antialiasing, true);

    // Draw line1 first (behind), then line2 (in front)
    if (has1)
        drawLine(painter, m_line1, m_line1Color, m_line1FillAlpha);
    if (has2)
        drawLine(painter, m_line2, m_line2Color, m_line2FillAlpha);
}

void SparklineItem::drawLine(QPainter* painter, CircularBuffer* buffer, const QColor& color, qreal fillAlpha) {
    const qreal w = width();
    const qreal h = height();
    const int len = buffer->count();
    const qreal stepX = w / static_cast<qreal>(m_historyLength - 1);
    const qreal startX = w - (len - 1) * stepX - stepX * m_slideProgress + stepX;

    // Build line path
    QPainterPath linePath;
    linePath.moveTo(startX, h - (buffer->at(0) / m_maxValue) * h);
    for (int i = 1; i < len; ++i) {
        const qreal x = startX + i * stepX;
        const qreal y = h - (buffer->at(i) / m_maxValue) * h;
        linePath.lineTo(x, y);
    }

    // Stroke the line
    QPen pen(color, m_lineWidth);
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::RoundJoin);
    painter->setPen(pen);
    painter->setBrush(Qt::NoBrush);
    painter->drawPath(linePath);

    // Fill under the line
    QPainterPath fillPath = linePath;
    fillPath.lineTo(startX + (len - 1) * stepX, h);
    fillPath.lineTo(startX, h);
    fillPath.closeSubpath();

    QColor fillColor = color;
    fillColor.setAlphaF(static_cast<float>(fillAlpha));
    painter->setPen(Qt::NoPen);
    painter->setBrush(fillColor);
    painter->drawPath(fillPath);
}

void SparklineItem::connectBuffer(CircularBuffer* buffer) {
    if (!buffer)
        return;

    connect(buffer, &CircularBuffer::valuesChanged, this, [this]() {
        update();
    });
    connect(buffer, &QObject::destroyed, this, [this, buffer]() {
        if (m_line1 == buffer) {
            m_line1 = nullptr;
            emit line1Changed();
        }
        if (m_line2 == buffer) {
            m_line2 = nullptr;
            emit line2Changed();
        }
        update();
    });
}

CircularBuffer* SparklineItem::line1() const {
    return m_line1;
}

void SparklineItem::setLine1(CircularBuffer* buffer) {
    if (m_line1 == buffer)
        return;
    if (m_line1)
        disconnect(m_line1, nullptr, this, nullptr);
    m_line1 = buffer;
    connectBuffer(buffer);
    emit line1Changed();
    update();
}

CircularBuffer* SparklineItem::line2() const {
    return m_line2;
}

void SparklineItem::setLine2(CircularBuffer* buffer) {
    if (m_line2 == buffer)
        return;
    if (m_line2)
        disconnect(m_line2, nullptr, this, nullptr);
    m_line2 = buffer;
    connectBuffer(buffer);
    emit line2Changed();
    update();
}

QColor SparklineItem::line1Color() const {
    return m_line1Color;
}

void SparklineItem::setLine1Color(const QColor& color) {
    if (m_line1Color == color)
        return;
    m_line1Color = color;
    emit line1ColorChanged();
    update();
}

QColor SparklineItem::line2Color() const {
    return m_line2Color;
}

void SparklineItem::setLine2Color(const QColor& color) {
    if (m_line2Color == color)
        return;
    m_line2Color = color;
    emit line2ColorChanged();
    update();
}

qreal SparklineItem::line1FillAlpha() const {
    return m_line1FillAlpha;
}

void SparklineItem::setLine1FillAlpha(qreal alpha) {
    if (qFuzzyCompare(m_line1FillAlpha, alpha))
        return;
    m_line1FillAlpha = alpha;
    emit line1FillAlphaChanged();
    update();
}

qreal SparklineItem::line2FillAlpha() const {
    return m_line2FillAlpha;
}

void SparklineItem::setLine2FillAlpha(qreal alpha) {
    if (qFuzzyCompare(m_line2FillAlpha, alpha))
        return;
    m_line2FillAlpha = alpha;
    emit line2FillAlphaChanged();
    update();
}

qreal SparklineItem::maxValue() const {
    return m_maxValue;
}

void SparklineItem::setMaxValue(qreal value) {
    if (qFuzzyCompare(m_maxValue, value))
        return;
    m_maxValue = value;
    emit maxValueChanged();
    update();
}

qreal SparklineItem::slideProgress() const {
    return m_slideProgress;
}

void SparklineItem::setSlideProgress(qreal progress) {
    if (qFuzzyCompare(m_slideProgress, progress))
        return;
    m_slideProgress = progress;
    emit slideProgressChanged();
    update();
}

int SparklineItem::historyLength() const {
    return m_historyLength;
}

void SparklineItem::setHistoryLength(int length) {
    if (m_historyLength == length)
        return;
    m_historyLength = length;
    emit historyLengthChanged();
    update();
}

qreal SparklineItem::lineWidth() const {
    return m_lineWidth;
}

void SparklineItem::setLineWidth(qreal width) {
    if (qFuzzyCompare(m_lineWidth, width))
        return;
    m_lineWidth = width;
    emit lineWidthChanged();
    update();
}

} // namespace caelestia::internal
