#include "visualiserbars.hpp"

#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QQuickWindow>
#include <QTimer>
#include <QtMath>

namespace caelestia::internal {

// standard: cubic-bezier(0.2, 0, 0, 1)
static constexpr qreal BEZ_X1 = 0.2;
static constexpr qreal BEZ_Y1 = 0.0;
static constexpr qreal BEZ_X2 = 0.0;
static constexpr qreal BEZ_Y2 = 1.0;

static qreal clamp01(qreal v) {
    if (v < 0.0) {
        qWarning() << "Value clamped to 0.0:" << v;
        return 0.0;
    }
    if (v > 1.0) {
        qWarning() << "Value clamped to 1.0:" << v;
        return 1.0;
    }
    return v;
}

static qreal cubicBezier1D(qreal t, qreal p0, qreal p1, qreal p2, qreal p3) {
    const qreal u = 1.0 - t;
    return (u * u * u * p0) + (3.0 * u * u * t * p1) + (3.0 * u * t * t * p2) + (t * t * t * p3);
}

static qreal cubicBezierEase(qreal x) {
    x = clamp01(x);

    // control points for x curve: P0=0, P1=BEZ_X1, P2=BEZ_X2, P3=1
    // control points for y curve: P0=0, P1=BEZ_Y1, P2=BEZ_Y2, P3=1

    // binary search for t
    qreal lo = 0.0;
    qreal hi = 1.0;
    qreal t = 0.5;

    for (int i = 0; i < 20; i++) {
        t = (lo + hi) * 0.5;
        qreal cx = cubicBezier1D(t, 0.0, BEZ_X1, BEZ_X2, 1.0);

        if (cx < x)
            lo = t;
        else
            hi = t;
    }

    qreal cy = cubicBezier1D(t, 0.0, BEZ_Y1, BEZ_Y2, 1.0);
    return clamp01(cy);
}

VisualiserBars::VisualiserBars(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    setAntialiasing(true);
    setRenderTarget(QQuickPaintedItem::Image);

    ensureBuffers();

    m_frameTimer = new QTimer(this);
    m_frameTimer->setInterval(16);
    connect(m_frameTimer, &QTimer::timeout, this, [this]() {
        stepAnimations();
    });
    m_frameTimer->start();

    m_time.start();
    m_lastFrameMs = m_time.elapsed();
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

    const int totalBars = m_barCount * 2;

    if (m_displayValues.size() != totalBars)
        m_displayValues = QVector<qreal>(totalBars, 0.0);

    if (m_spatialValues.size() != totalBars)
        m_spatialValues = QVector<qreal>(totalBars, 0.0);

    if (m_animStart.size() != totalBars)
        m_animStart = QVector<qreal>(totalBars, 0.0);

    if (m_animTarget.size() != totalBars)
        m_animTarget = QVector<qreal>(totalBars, 0.0);

    if (m_animElapsed.size() != totalBars)
        m_animElapsed = QVector<qreal>(totalBars, 0.0);

    if (m_animActive.size() != totalBars)
        m_animActive = QVector<bool>(totalBars, false);
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

void VisualiserBars::startAnimation(int index, qreal target) {
    target = clamp01(target);

    if (index < 0 || index >= m_displayValues.size())
        return;

    constexpr qreal EPS = 0.0001;

    if (m_animActive[index] && qAbs(m_animTarget[index] - target) < EPS)
        return;

    if (!m_animActive[index] && qAbs(m_displayValues[index] - target) < EPS)
        return;

    m_animStart[index] = m_displayValues[index];
    m_animTarget[index] = target;
    m_animElapsed[index] = 0.0;
    m_animActive[index] = true;
}

void VisualiserBars::stepAnimations() {
    const qint64 now = m_time.elapsed();
    qreal dt = static_cast<qreal>(now - m_lastFrameMs) / 1000.0;

    if (dt < 0.0) {
        qWarning() << "Negative dt detected, clamping to 0.0:" << dt;
        dt = 0.0;
    }

    m_lastFrameMs = now;

    bool anyActive = false;

    const qreal smoothing = clamp01(m_smoothing);

    const qreal minSmoothing = 0.001;
    const qreal effectiveSmoothing = qMax(smoothing, minSmoothing);

    const qreal baseDurationSec = qMax(0.001, m_animationDuration / 1000.0);
    const qreal durationSec = baseDurationSec * effectiveSmoothing;

    for (int i = 0; i < m_displayValues.size(); i++) {
        if (!m_animActive[i])
            continue;

        anyActive = true;

        if (smoothing <= 0.001) {
            m_displayValues[i] = m_animTarget[i];
            m_animActive[i] = false;
            continue;
        }

        m_animElapsed[i] += dt;

        qreal t = m_animElapsed[i] / durationSec;
        if (t >= 1.0) {
            m_displayValues[i] = m_animTarget[i];
            m_animActive[i] = false;
            continue;
        }

        qreal eased = cubicBezierEase(clamp01(t));

        m_displayValues[i] = m_animStart[i] + (m_animTarget[i] - m_animStart[i]) * eased;
    }

    if (anyActive)
        update();
}

void VisualiserBars::paint(QPainter* p) {
    const qreal w = width();
    const qreal h = height();

    if (w <= 1.0 || h <= 1.0)
        return;

    ensureBuffers();

    for (int i = 0; i < m_barCount * 2; i++) {
        m_spatialValues[i] = spatialSmooth(i, m_displayValues, m_curvature);
    }

    p->setPen(Qt::NoPen);

    QLinearGradient grad(0, h * 0.7, 0, h);
    grad.setColorAt(0.0, m_barColorTop);
    grad.setColorAt(1.0, m_barColorBottom);
    p->setBrush(grad);

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
    if (count <= 0) {
        qWarning() << "Invalid bar count, must be positive:" << count;
        return;
    }
    if (count == m_barCount)
        return;

    m_barCount = count;

    ensureBuffers();

    for (int i = 0; i < m_animActive.size(); i++)
        m_animActive[i] = false;

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
    if (smoothing < 0.0 || smoothing > 1.0) {
        qWarning() << "Smoothing value clamped to [0,1]:" << smoothing;
    }
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

int VisualiserBars::animationDuration() const {
    return m_animationDuration;
}

void VisualiserBars::setAnimationDuration(int ms) {
    if (ms < 0) {
        qWarning() << "Animation duration clamped to 0:" << ms;
        ms = 0;
    }

    if (m_animationDuration == ms)
        return;

    m_animationDuration = ms;
    emit animationDurationChanged();
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

        // animate all bars to 0
        for (int i = 0; i < m_barCount; i++) {
            startAnimation(i, 0.0);
            startAnimation(m_barCount + i, 0.0);
        }

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

    for (int i = 0; i < m_barCount; i++) {
        qreal leftTarget = m_audioValues[i];

        int mirroredIndex = m_barCount - i - 1;
        qreal rightTarget = 0.0;

        if (mirroredIndex >= 0 && mirroredIndex < m_audioValues.size())
            rightTarget = m_audioValues[mirroredIndex];

        startAnimation(i, leftTarget);
        startAnimation(m_barCount + i, rightTarget);
    }

    emit audioValuesChanged();
    update();
}

} // namespace caelestia::internal
