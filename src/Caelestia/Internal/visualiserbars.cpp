#include "visualiserbars.hpp"

#include <algorithm>
#include <cmath>
#include <qbrush.h>
#include <qpainter.h>
#include <qpainterpath.h>
#include <qpen.h>

namespace caelestia::internal {

VisualiserBars::VisualiserBars(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    setAntialiasing(true);
}

void VisualiserBars::advance(qreal dt) {
    if (m_displayValues.isEmpty() || m_settled)
        return;

    // dt is in seconds (from FrameAnimation.frameTime), convert to ms
    const qreal dtMs = dt * 1000.0;
    const qreal tau = m_animationDuration / 3.0;
    const qreal alpha = 1.0 - std::exp(-dtMs / tau);

    bool allSettled = true;

    for (qsizetype i = 0; i < m_displayValues.size(); ++i) {
        const double diff = m_targetValues[i] - m_displayValues[i];

        if (std::abs(diff) > 0.001) {
            m_displayValues[i] += diff * alpha;
            allSettled = false;
        } else {
            m_displayValues[i] = m_targetValues[i];
        }
    }

    update();

    if (allSettled && !m_settled) {
        m_settled = true;
        emit settledChanged();
    }
}

void VisualiserBars::paint(QPainter* painter) {
    if (m_displayValues.isEmpty())
        return;

    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->setPen(Qt::NoPen);

    const qreal h = height();
    const qreal maxBarHeight = h * 0.4;

    QLinearGradient gradient(0, h - maxBarHeight, 0, h);
    gradient.setColorAt(0, m_primaryColor);
    gradient.setColorAt(1, m_secondaryColor);
    painter->setBrush(gradient);

    drawSide(painter, false);
    drawSide(painter, true);
}

void VisualiserBars::drawSide(QPainter* painter, bool rightSide) {
    const qreal w = width();
    const qreal h = height();
    const auto count = m_displayValues.size();

    if (count == 0)
        return;

    const qreal sideWidth = w * 0.4;
    const qreal slotWidth = sideWidth / static_cast<qreal>(count);
    const qreal barWidth = slotWidth - m_spacing;

    if (barWidth <= 0)
        return;

    const qreal sideOffset = rightSide ? w * 0.6 : 0;
    const qreal maxBarHeight = h * 0.4;

    for (qsizetype i = 0; i < count; ++i) {
        const qsizetype valueIndex = rightSide ? i : (count - i - 1);
        const qreal value = std::clamp(m_displayValues[valueIndex], 0.0, 1.0);
        const qreal barHeight = value * maxBarHeight;

        if (barHeight <= 0)
            continue;

        const qreal x = static_cast<qreal>(i) * slotWidth + sideOffset;
        const qreal y = h - barHeight;
        const qreal r = std::min({ m_rounding, barWidth / 2.0, barHeight });

        QPainterPath path;
        path.moveTo(x, h);
        path.lineTo(x, y + r);

        if (r > 0) {
            path.arcTo(x, y, r * 2, r * 2, 180, -90);
            path.lineTo(x + barWidth - r, y);
            path.arcTo(x + barWidth - r * 2, y, r * 2, r * 2, 90, -90);
        } else {
            path.lineTo(x, y);
            path.lineTo(x + barWidth, y);
        }

        path.lineTo(x + barWidth, h);
        path.closeSubpath();

        painter->drawPath(path);
    }
}

QVector<double> VisualiserBars::values() const {
    return m_targetValues;
}

void VisualiserBars::setValues(const QVector<double>& values) {
    m_targetValues = values;

    if (m_displayValues.size() != values.size()) {
        m_displayValues.resize(values.size(), 0.0);
    }

    if (m_settled) {
        m_settled = false;
        emit settledChanged();
    }

    emit valuesChanged();
}

bool VisualiserBars::settled() const {
    return m_settled;
}

QColor VisualiserBars::primaryColor() const {
    return m_primaryColor;
}

void VisualiserBars::setPrimaryColor(const QColor& color) {
    if (m_primaryColor == color)
        return;
    m_primaryColor = color;
    emit primaryColorChanged();
    update();
}

QColor VisualiserBars::secondaryColor() const {
    return m_secondaryColor;
}

void VisualiserBars::setSecondaryColor(const QColor& color) {
    if (m_secondaryColor == color)
        return;
    m_secondaryColor = color;
    emit secondaryColorChanged();
    update();
}

qreal VisualiserBars::rounding() const {
    return m_rounding;
}

void VisualiserBars::setRounding(qreal rounding) {
    if (qFuzzyCompare(m_rounding, rounding))
        return;
    m_rounding = rounding;
    emit roundingChanged();
    update();
}

qreal VisualiserBars::spacing() const {
    return m_spacing;
}

void VisualiserBars::setSpacing(qreal spacing) {
    if (qFuzzyCompare(m_spacing, spacing))
        return;
    m_spacing = spacing;
    emit spacingChanged();
    update();
}

int VisualiserBars::animationDuration() const {
    return m_animationDuration;
}

void VisualiserBars::setAnimationDuration(int duration) {
    if (m_animationDuration == duration)
        return;
    m_animationDuration = duration;
    emit animationDurationChanged();
}

} // namespace caelestia::internal
