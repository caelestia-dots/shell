#include "visualiserbars.hpp"

#include <qsgnode.h>
#include <qsgvertexcolormaterial.h>

#include <algorithm>
#include <cmath>
#include <cstring>

namespace caelestia::components {

VisualiserBars::VisualiserBars(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
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

QSGNode* VisualiserBars::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* /*data*/) {
    const qreal w = width();
    const qreal h = height();
    const auto count = m_displayValues.size();
    const qreal sideWidth = w * 0.4;
    const qreal slotWidth = count > 0 ? sideWidth / static_cast<qreal>(count) : 0.0;
    const qreal barWidth = slotWidth - m_spacing;
    const qreal maxBarHeight = h * 0.4;

    // Each bar is a convex outline of up to 2 * (k_arcSteps + 1) + 4 points, fanned from its centre
    constexpr int k_arcSteps = 6;
    constexpr int k_pointsPerBar = 2 * (k_arcSteps + 1) + 4;

    QVector<QSGGeometry::ColoredPoint2D> vertices;
    if (count > 0 && barWidth > 0 && h > 0) {
        // Upper bound: two sides, each bar fanned into at most k_pointsPerBar triangles
        vertices.resize(static_cast<qsizetype>(count) * 2 * k_pointsPerBar * 3);
        qsizetype index = 0;
        for (int side = 0; side < 2; ++side) {
            const qreal sideOffset = side == 1 ? w * 0.6 : 0.0;
            for (qsizetype i = 0; i < count; ++i) {
                const qsizetype valueIndex = side == 1 ? i : (count - i - 1);
                const qreal value = std::clamp(m_displayValues[valueIndex], 0.0, 1.0);
                const qreal barHeight = value * maxBarHeight;
                if (barHeight <= 0)
                    continue;
                const qreal x = static_cast<qreal>(i) * slotWidth + sideOffset;
                appendBar(vertices.data(), index, x, h - barHeight, barWidth, barHeight, h);
            }
        }
        vertices.resize(index);
    }

    auto* node = static_cast<QSGGeometryNode*>(oldNode);
    if (vertices.isEmpty()) {
        delete node;
        return nullptr;
    }

    if (!node) {
        node = new QSGGeometryNode;
        auto* material = new QSGVertexColorMaterial;
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
        auto* geometry = new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), 0);
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
    }

    QSGGeometry* geometry = node->geometry();
    geometry->allocate(static_cast<int>(vertices.size()));
    memcpy(geometry->vertexData(), vertices.constData(),
        static_cast<size_t>(vertices.size()) * sizeof(QSGGeometry::ColoredPoint2D));
    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}

// The gradient runs from the top of the tallest bar (primary) down to the bottom edge (secondary),
// the same as the QLinearGradient the software painter used. Colours are interpolated per vertex.
QSGGeometry::ColoredPoint2D VisualiserBars::colouredPoint(qreal x, qreal y, qreal h) const {
    const qreal top = h - h * 0.4;
    const qreal t = std::clamp((y - top) / (h * 0.4), 0.0, 1.0);
    const qreal alpha =
        static_cast<qreal>(m_primaryColor.alphaF()) +
        (static_cast<qreal>(m_secondaryColor.alphaF()) - static_cast<qreal>(m_primaryColor.alphaF())) * t;
    const auto channel = [&](qreal primary, qreal secondary) {
        const qreal value = primary + (secondary - primary) * t;
        // Vertex colours are premultiplied
        return static_cast<uchar>(std::lround(value * alpha * 255.0));
    };

    QSGGeometry::ColoredPoint2D p{};
    p.x = static_cast<float>(x);
    p.y = static_cast<float>(y);
    p.r = channel(static_cast<qreal>(m_primaryColor.redF()), static_cast<qreal>(m_secondaryColor.redF()));
    p.g = channel(static_cast<qreal>(m_primaryColor.greenF()), static_cast<qreal>(m_secondaryColor.greenF()));
    p.b = channel(static_cast<qreal>(m_primaryColor.blueF()), static_cast<qreal>(m_secondaryColor.blueF()));
    p.a = static_cast<uchar>(std::lround(alpha * 255.0));
    return p;
}

void VisualiserBars::appendBar(QSGGeometry::ColoredPoint2D* out, qsizetype& index, qreal x, qreal y, qreal barWidth,
    qreal barHeight, qreal h) const {
    const qreal r = std::min({ m_rounding, barWidth / 2.0, barHeight });

    // Outline in order: bottom-left, up the left side, top-left arc, top-right arc, down the right side
    QVector<QPointF> outline;
    outline.reserve(2 * 7 + 4);
    outline.append({ x, h });
    outline.append({ x, y + r });
    if (r > 0) {
        constexpr int k_steps = 6;
        for (int s = 0; s <= k_steps; ++s) {
            const qreal a = (180.0 - 90.0 * s / k_steps) * M_PI / 180.0;
            outline.append({ x + r + r * std::cos(a), y + r - r * std::sin(a) });
        }
        for (int s = 0; s <= k_steps; ++s) {
            const qreal a = (90.0 - 90.0 * s / k_steps) * M_PI / 180.0;
            outline.append({ x + barWidth - r + r * std::cos(a), y + r - r * std::sin(a) });
        }
    } else {
        outline.append({ x, y });
        outline.append({ x + barWidth, y });
    }
    outline.append({ x + barWidth, h });

    // The outline is convex, so a fan from its centre covers it exactly
    const QPointF centre(x + barWidth / 2.0, y + barHeight / 2.0);
    const auto n = outline.size();
    for (qsizetype i = 0; i < n; ++i) {
        const QPointF& a = outline[i];
        const QPointF& b = outline[(i + 1) % n];
        out[index++] = colouredPoint(centre.x(), centre.y(), h);
        out[index++] = colouredPoint(a.x(), a.y(), h);
        out[index++] = colouredPoint(b.x(), b.y(), h);
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

} // namespace caelestia::components
