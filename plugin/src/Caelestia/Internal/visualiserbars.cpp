#include "visualiserbars.hpp"

#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QQuickWindow>
#include <QtMath>

namespace caelestia::internal {

VisualiserBars::VisualiserBars(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    setAntialiasing(true);

    setRenderTarget(QQuickPaintedItem::FramebufferObject);

    m_barColorTop = QColor(255, 255, 255, 180);
    m_barColorBottom = QColor(255, 255, 255, 180);

    ensureBuffers();
}

qreal VisualiserBars::effectiveScale() const {
    if (window())
        return window()->devicePixelRatio();
    return 1.0;
}

qreal VisualiserBars::snapToPixel(qreal v) const {
    const qreal dpr = effectiveScale();
    return qRound(v * dpr) / dpr;
}

void VisualiserBars::ensureBuffers() {
    if (m_audioValues.size() != m_barCount)
        m_audioValues = QVector<qreal>(m_barCount, 0.0);

    if (m_displayValues.size() != m_barCount * 2)
        m_displayValues = QVector<qreal>(m_barCount * 2, 0.0);

    if (m_spatialValues.size() != m_barCount * 2)
        m_spatialValues = QVector<qreal>(m_barCount * 2, 0.0);
}

qreal VisualiserBars::clamp01(qreal v) const {
    if (v < 0.0)
        return 0.0;
    if (v > 1.0)
        return 1.0;
    return v;
}

qreal VisualiserBars::spatialSmooth(int index, const QVector<qreal>& values, int radius) const {
    if (radius <= 0)
        return values[index];

    qreal sum = 0.0;
    qreal weightSum = 0.0;

    for (int o = -radius; o <= radius; o++) {
        int idx = index + o;
        if (idx < 0 || idx >= values.size())
            continue;

        qreal w = qExp(-(o * o) / (2.0 * radius * radius));
        sum += values[idx] * w;
        weightSum += w;
    }

    if (weightSum <= 0.0)
        return values[index];

    return sum / weightSum;
}

void VisualiserBars::paint(QPainter* p) {
    const qreal w = width();
    const qreal h = height();

    if (w <= 1.0 || h <= 1.0)
        return;

    ensureBuffers();

    p->setPen(Qt::NoPen);

    QLinearGradient grad(0, h * 0.7, 0, h);
    grad.setColorAt(0.0, m_barColorTop);
    grad.setColorAt(1.0, m_barColorBottom);
    p->setBrush(grad);

    for (int i = 0; i < m_barCount; i++) {
        qreal leftTarget = 0.0;
        if (i < m_audioValues.size())
            leftTarget = clamp01(m_audioValues[i]);

        int mirroredIndex = m_barCount - i - 1;
        qreal rightTarget = 0.0;
        if (mirroredIndex >= 0 && mirroredIndex < m_audioValues.size())
            rightTarget = clamp01(m_audioValues[mirroredIndex]);

        m_displayValues[i] += (leftTarget - m_displayValues[i]) * m_smoothing;
        m_displayValues[m_barCount + i] += (rightTarget - m_displayValues[m_barCount + i]) * m_smoothing;
    }

    for (int i = 0; i < m_barCount * 2; i++) {
        m_spatialValues[i] = spatialSmooth(i, m_displayValues, m_curvature);
    }

    const qreal leftStart = 0.0;
    const qreal leftWidth = w * 0.4;

    const qreal rightStart = w * 0.6;
    const qreal rightWidth = w * 0.4;

    const qreal maxBarHeight = h * 0.4;

    for (int i = 0; i < m_barCount; i++) {
        qreal lx0 = leftStart + (i * leftWidth) / m_barCount;
        qreal lx1 = leftStart + ((i + 1) * leftWidth) / m_barCount;

        qreal rx0 = rightStart + (i * rightWidth) / m_barCount;
        qreal rx1 = rightStart + ((i + 1) * rightWidth) / m_barCount;

        lx0 = snapToPixel(lx0);
        lx1 = snapToPixel(lx1);

        rx0 = snapToPixel(rx0);
        rx1 = snapToPixel(rx1);

        qreal barWidthLeft = (lx1 - lx0) - m_spacing;
        qreal barWidthRight = (rx1 - rx0) - m_spacing;

        if (barWidthLeft <= 0.0 || barWidthRight <= 0.0)
            continue;

        const qreal halfSpace = m_spacing * 0.5;

        qreal drawLX = lx0 + halfSpace;
        qreal drawRX = rx0 + halfSpace;

        drawLX = snapToPixel(drawLX);
        drawRX = snapToPixel(drawRX);

        barWidthLeft = snapToPixel(drawLX + barWidthLeft) - drawLX;
        barWidthRight = snapToPixel(drawRX + barWidthRight) - drawRX;

        const qreal vLeft = clamp01(m_spatialValues[i]);
        const qreal vRight = clamp01(m_spatialValues[m_barCount + i]);

        const qreal hLeft = vLeft * maxBarHeight;
        const qreal hRight = vRight * maxBarHeight;

        qreal rLeft = qMin(m_barRadius, barWidthLeft / 2);
        rLeft = qMin(rLeft, hLeft / 2);

        qreal rRight = qMin(m_barRadius, barWidthRight / 2);
        rRight = qMin(rRight, hRight / 2);

        if (hLeft > 0.5) {
            const qreal yLeft = h - hLeft;

            QPainterPath path;
            path.moveTo(drawLX, h);
            path.lineTo(drawLX, yLeft + rLeft);
            path.quadTo(drawLX, yLeft, drawLX + rLeft, yLeft);
            path.lineTo(drawLX + barWidthLeft - rLeft, yLeft);
            path.quadTo(drawLX + barWidthLeft, yLeft, drawLX + barWidthLeft, yLeft + rLeft);
            path.lineTo(drawLX + barWidthLeft, h);
            path.closeSubpath();

            p->drawPath(path);
        }

        if (hRight > 0.5) {
            const qreal yRight = h - hRight;

            QPainterPath path;
            path.moveTo(drawRX, h);
            path.lineTo(drawRX, yRight + rRight);
            path.quadTo(drawRX, yRight, drawRX + rRight, yRight);
            path.lineTo(drawRX + barWidthRight - rRight, yRight);
            path.quadTo(drawRX + barWidthRight, yRight, drawRX + barWidthRight, yRight + rRight);
            path.lineTo(drawRX + barWidthRight, h);
            path.closeSubpath();

            p->drawPath(path);
        }
    }
}

int VisualiserBars::barCount() const {
    return m_barCount;
}

void VisualiserBars::setBarCount(int count) {
    if (count <= 0 || count == m_barCount)
        return;

    m_barCount = count;
    ensureBuffers();

    emit barCountChanged();
    update();
}

qreal VisualiserBars::spacing() const {
    return m_spacing;
}

void VisualiserBars::setSpacing(qreal spacing) {
    if (qFuzzyCompare(spacing, m_spacing))
        return;

    m_spacing = spacing;
    emit spacingChanged();
    update();
}

qreal VisualiserBars::smoothing() const {
    return m_smoothing;
}

void VisualiserBars::setSmoothing(qreal smoothing) {
    smoothing = clamp01(smoothing);

    if (qFuzzyCompare(smoothing, m_smoothing))
        return;

    m_smoothing = smoothing;
    emit smoothingChanged();
    update();
}

int VisualiserBars::curvature() const {
    return m_curvature;
}

void VisualiserBars::setCurvature(int curvature) {
    if (curvature == m_curvature)
        return;

    m_curvature = curvature;
    emit curvatureChanged();
    update();
}

qreal VisualiserBars::barRadius() const {
    return m_barRadius;
}

void VisualiserBars::setBarRadius(qreal radius) {
    if (qFuzzyCompare(radius, m_barRadius))
        return;

    m_barRadius = radius;
    emit barRadiusChanged();
    update();
}

QColor VisualiserBars::barColorTop() const {
    return m_barColorTop;
}

void VisualiserBars::setBarColorTop(const QColor& c) {
    if (c == m_barColorTop)
        return;

    m_barColorTop = c;
    emit barColorTopChanged();
    update();
}

QColor VisualiserBars::barColorBottom() const {
    return m_barColorBottom;
}

void VisualiserBars::setBarColorBottom(const QColor& c) {
    if (c == m_barColorBottom)
        return;

    m_barColorBottom = c;
    emit barColorBottomChanged();
    update();
}

QList<double> VisualiserBars::audioValues() const {
    QList<double> out;
    out.reserve(m_audioValues.size());

    for (qreal v : m_audioValues)
        out.push_back(v);

    return out;
}

void VisualiserBars::setAudioValues(const QList<double>& values) {
    ensureBuffers();

    if (values.isEmpty()) {
        for (int i = 0; i < m_barCount; i++)
            m_audioValues[i] = 0.0;

        emit audioValuesChanged();
        update();
        return;
    }

    const qsizetype n = qMin(values.size(), qsizetype(m_barCount));

    for (int i = 0; i < int(n); i++) {
        m_audioValues[i] = clamp01(values[i]);
    }

    for (int i = int(n); i < m_barCount; i++) {
        m_audioValues[i] = 0.0;
    }

    emit audioValuesChanged();
    update();
}

} // namespace caelestia::internal
