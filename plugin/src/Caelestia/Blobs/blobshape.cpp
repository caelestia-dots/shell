#include "blobshape.hpp"

#include <qsggeometry.h>
#include <qsgnode.h>

#include <algorithm>
#include <cmath>

#include "blobgroup.hpp"
#include "blobinvertedrect.hpp"

namespace caelestia::blobs {

namespace {

float deformPadding(const QMatrix4x4& dm, float hw, float hh) {
    // Bounding box of the deformed shape: |M * corners|
    const float dm00 = dm(0, 0);
    const float dm01 = dm(0, 1);
    const float dm10 = dm(1, 0);
    const float dm11 = dm(1, 1);
    const float boundX = std::abs(dm00) * hw + std::abs(dm01) * hh;
    const float boundY = std::abs(dm10) * hw + std::abs(dm11) * hh;
    const float extraX = std::max(boundX - hw, 0.0f) + std::abs(dm(0, 3));
    const float extraY = std::max(boundY - hh, 0.0f) + std::abs(dm(1, 3));
    return std::max(extraX, extraY);
}

float cpuSdBox(float px, float py, float cx, float cy, float hw, float hh) {
    const float dx = std::abs(px - cx) - hw;
    const float dy = std::abs(py - cy) - hh;
    const float mdx = std::max(dx, 0.0f);
    const float mdy = std::max(dy, 0.0f);
    return std::sqrt(mdx * mdx + mdy * mdy) + std::min(std::max(dx, dy), 0.0f);
}

float cpuSmoothstep(float edge0, float edge1, float x) {
    const float t = std::clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

float cornerFillFactor(float sd, float smoothFactor) {
    // Continuous two-sided window. The corner is squared (factor -> 0) only within
    // ±smoothFactor of the neighbour's edge (the visible junction); it keeps its full
    // radius both far outside the neighbour and deep inside it (where it is buried and
    // squaring would only crease the interior). C0-continuous across sd = 0 — unlike the
    // old `if (sd >= 0)` branch, which snapped the radius full<->square (factor 1<->0) on
    // sub-pixel motion as a corner crossed the edge, flickering the fill bridge in/out.
    const float outside = cpuSmoothstep(0.0f, smoothFactor, sd); // 0 at edge, ->1 far outside
    const float inside = cpuSmoothstep(0.0f, -smoothFactor, sd); // 0 at edge, ->1 deep inside
    return std::max(outside, inside);
}

// Corner order matches BlobRectData::radius: TR, BR, BL, TL
void rectCorners(const BlobRectData& r, float outX[4], float outY[4]) {
    outX[0] = r.cx + r.hw;
    outY[0] = r.cy - r.hh;
    outX[1] = r.cx + r.hw;
    outY[1] = r.cy + r.hh;
    outX[2] = r.cx - r.hw;
    outY[2] = r.cy + r.hh;
    outX[3] = r.cx - r.hw;
    outY[3] = r.cy - r.hh;
}

} // namespace

BlobShape::BlobShape(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents);
}

BlobGroup* BlobShape::group() const {
    return m_group;
}

void BlobShape::setGroup(BlobGroup* g) {
    if (m_group == g)
        return;
    if (m_group && isComponentComplete())
        unregisterFromGroup();
    m_group = g;
    if (m_group && isComponentComplete())
        registerWithGroup();
    emit groupChanged();
    if (m_group)
        m_group->markDirty();
}

qreal BlobShape::radius() const {
    return m_radius;
}

void BlobShape::setRadius(qreal r) {
    if (qFuzzyCompare(m_radius, r))
        return;
    m_radius = r;
    emit radiusChanged();
    if (m_group)
        m_group->markDirty();
}

QMatrix4x4 BlobShape::deformMatrix() const {
    return m_centeredDeformMatrix;
}

QMatrix4x4 BlobShape::rawDeformMatrix() const {
    return m_deformMatrix;
}

void BlobShape::componentComplete() {
    QQuickItem::componentComplete();
    if (m_group)
        registerWithGroup();
}

void BlobShape::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    updateCenteredDeformMatrix();
    if (m_group) {
        // Accumulate sub-pixel drift so slow movements don't desync the shader
        m_pendingDx += static_cast<float>(newGeometry.x() - oldGeometry.x());
        m_pendingDy += static_cast<float>(newGeometry.y() - oldGeometry.y());
        const auto dw = std::abs(newGeometry.width() - oldGeometry.width());
        const auto dh = std::abs(newGeometry.height() - oldGeometry.height());
        if (std::abs(m_pendingDx) > 0.5f || std::abs(m_pendingDy) > 0.5f || dw > 0.5 || dh > 0.5) {
            m_pendingDx = 0;
            m_pendingDy = 0;
            m_group->markShapeDirty(this);
        }
    }
}

void BlobShape::updateCenteredDeformMatrix() {
    const auto cx = static_cast<float>(width()) * 0.5f;
    const auto cy = static_cast<float>(height()) * 0.5f;
    QMatrix4x4 result;
    result.translate(cx, cy);
    result *= m_deformMatrix;
    result.translate(-cx, -cy);
    if (m_centeredDeformMatrix != result) {
        m_centeredDeformMatrix = result;
        emit deformMatrixChanged();
    }
}

bool BlobShape::isInvertedRect() const {
    return false;
}

bool BlobShape::isExcluded(const BlobShape* other) const {
    Q_UNUSED(other);
    return false;
}

bool BlobShape::isCornerExcluded(const BlobShape* other) const {
    Q_UNUSED(other);
    return false;
}

void BlobShape::cornerRadii(float out[4]) const {
    const auto maxR = static_cast<float>(std::min(width(), height())) * 0.5f;
    const auto r = std::min(static_cast<float>(m_radius), maxR);
    out[0] = r;
    out[1] = r;
    out[2] = r;
    out[3] = r;
}

void BlobShape::updatePhysics() {}

void BlobShape::registerWithGroup() {
    if (m_group)
        m_group->addShape(this);
}

void BlobShape::unregisterFromGroup() {
    if (m_group)
        m_group->removeShape(this);
}

void BlobShape::updatePolish() {
    if (!m_group)
        return;

    // Ensure all shapes have up-to-date physics (only once per frame)
    m_group->ensurePhysicsUpdated();

    const auto pad = static_cast<float>(m_group->smoothing());

    updatePaddedBounds(pad);

    // Tracks shape pointers parallel to m_cachedRects for pairwise exclusion lookups
    QVector<BlobShape*> rectShapes;
    collectNearbyRects(pad, rectShapes);
    computeExcludeMasks(rectShapes);
    cacheInvertedRect(pad);
    applyCornerFill(pad, rectShapes);
}

QRectF BlobShape::localPaddedRect(float pad) const {
    if (isInvertedRect())
        return { 0, 0, width(), height() };

    const auto hw = static_cast<float>(width()) * 0.5f;
    const auto hh = static_cast<float>(height()) * 0.5f;
    const auto totalPad = static_cast<double>(pad + deformPadding(m_deformMatrix, hw, hh));

    return { -totalPad, -totalPad, width() + 2.0 * totalPad, height() + 2.0 * totalPad };
}

QRectF BlobShape::paddedSceneRect(const QPointF& scenePos, float pad) const {
    return localPaddedRect(pad).translated(scenePos);
}

void BlobShape::updatePaddedBounds(float pad) {
    m_localPaddedRect = localPaddedRect(pad);

    const QRectF padded = m_localPaddedRect.translated(mapToScene(QPointF(0, 0)));
    m_cachedPaddedX = static_cast<float>(padded.x());
    m_cachedPaddedY = static_cast<float>(padded.y());
    m_cachedPaddedW = static_cast<float>(padded.width());
    m_cachedPaddedH = static_cast<float>(padded.height());
}

void BlobShape::writeRectData(BlobRectData& r, const QPointF& scenePos) const {
    const QMatrix4x4& dm = m_deformMatrix;
    const float m00 = dm(0, 0);
    const float m10 = dm(1, 0);
    const float m01 = dm(0, 1);
    const float m11 = dm(1, 1);

    r.cx = static_cast<float>(scenePos.x() + width() / 2.0);
    r.cy = static_cast<float>(scenePos.y() + height() / 2.0);
    r.hw = static_cast<float>(width() / 2.0);
    r.hh = static_cast<float>(height() / 2.0);
    cornerRadii(r.radius);
    r.offsetX = dm(0, 3);
    r.offsetY = dm(1, 3);

    // Pre-compute inverse deformation matrix
    const float det = m00 * m11 - m01 * m10;
    const float invDet = std::abs(det) > 1e-6f ? 1.0f / det : 1.0f;
    r.invDeform[0] = m11 * invDet;
    r.invDeform[1] = -m10 * invDet;
    r.invDeform[2] = -m01 * invDet;
    r.invDeform[3] = m00 * invDet;

    // Pre-compute minimum eigenvalue (avoids per-pixel sqrt)
    const float halfTr = 0.5f * (m00 + m11);
    const float halfDiff = 0.5f * (m00 - m11);
    r.minEig = halfTr - std::sqrt(halfDiff * halfDiff + m01 * m01);

    // Pre-compute screen-space AABB half-extents
    r.screenHalfX = std::abs(m00) * r.hw + std::abs(m01) * r.hh;
    r.screenHalfY = std::abs(m10) * r.hw + std::abs(m11) * r.hh;
}

void BlobShape::collectNearbyRects(float pad, QVector<BlobShape*>& rectShapes) {
    m_cachedRects.clear();
    m_cachedMyIndex = -2;

    const QRectF myPadded(static_cast<double>(m_cachedPaddedX), static_cast<double>(m_cachedPaddedY),
        static_cast<double>(m_cachedPaddedW), static_cast<double>(m_cachedPaddedH));
    const bool inverted = isInvertedRect();

    rectShapes.reserve(k_maxRects);
    m_cachedRects.reserve(k_maxRects);

    for (BlobShape* other : m_group->shapes()) {
        if (m_cachedRects.size() >= k_maxRects)
            break;

        if (other->isInvertedRect())
            continue;

        // Skip zero-size rects
        if (other->width() <= 0 || other->height() <= 0)
            continue;

        if (isExcluded(other))
            continue;

        const QPointF otherScene = other->mapToScene(QPointF(0, 0));

        // An inverted rect smins against every shape, others only against overlapping ones
        if (!inverted && !myPadded.intersects(other->paddedSceneRect(otherScene, pad)))
            continue;

        if (other == this)
            m_cachedMyIndex = static_cast<int>(m_cachedRects.size());

        BlobRectData r;
        other->writeRectData(r, otherScene);
        m_cachedRects.append(r);
        rectShapes.append(other);
    }

    if (inverted)
        m_cachedMyIndex = -1;
}

void BlobShape::computeExcludeMasks(const QVector<BlobShape*>& rectShapes) {
    // Bit j in entry i is set iff rect i excludes rect j or rect j excludes rect i.
    // The shader uses this to avoid smin between excluded pairs.
    const auto cachedCount = m_cachedRects.size();
    for (qsizetype i = 0; i < cachedCount; ++i) {
        int mask = 0;
        const BlobShape* si = rectShapes[i];
        for (qsizetype j = 0; j < cachedCount; ++j) {
            if (j == i)
                continue;
            const BlobShape* sj = rectShapes[j];
            if (si->isExcluded(sj) || sj->isExcluded(si))
                mask |= (1 << j);
        }
        m_cachedRects[i].excludeMask = mask;
    }
}

bool BlobShape::isNearInvertedBorder(float cx, float cy, float hw, float hh, float margin) const {
    const float myCX = m_cachedPaddedX + m_cachedPaddedW * 0.5f;
    const float myCY = m_cachedPaddedY + m_cachedPaddedH * 0.5f;
    const float myHW = m_cachedPaddedW * 0.5f;
    const float myHH = m_cachedPaddedH * 0.5f;

    // Near border if any edge of padded rect is within margin of inner edge
    return (myCX - myHW < cx - hw + margin) || (myCX + myHW > cx + hw - margin) || (myCY - myHH < cy - hh + margin) ||
           (myCY + myHH > cy + hh - margin);
}

void BlobShape::cacheInvertedRect(float pad) {
    m_cachedHasInverted = false;
    m_cachedInvertedRadius = 0;
    memset(m_cachedInvertedOuter, 0, sizeof(m_cachedInvertedOuter));
    memset(m_cachedInvertedInner, 0, sizeof(m_cachedInvertedInner));

    auto* inv = m_group->invertedRect();
    if (!inv)
        return;

    const QPointF invScene = inv->mapToScene(QPointF(0, 0));
    const auto outerCX = static_cast<float>(invScene.x() + inv->width() / 2.0);
    const auto outerCY = static_cast<float>(invScene.y() + inv->height() / 2.0);
    const auto outerHW = static_cast<float>(inv->width() / 2.0);
    const auto outerHH = static_cast<float>(inv->height() / 2.0);

    const float innerCX = outerCX + static_cast<float>((inv->borderLeft() - inv->borderRight()) / 2.0);
    const float innerCY = outerCY + static_cast<float>((inv->borderTop() - inv->borderBottom()) / 2.0);
    const float innerHW = outerHW - static_cast<float>((inv->borderLeft() + inv->borderRight()) / 2.0);
    const float innerHH = outerHH - static_cast<float>((inv->borderTop() + inv->borderBottom()) / 2.0);

    // Only rects near the border (within 2x smoothing of the inner edge) need it
    if (!isInvertedRect() && !isNearInvertedBorder(innerCX, innerCY, innerHW, innerHH, pad * 2.0f))
        return;

    m_cachedHasInverted = true;
    m_cachedInvertedRadius = static_cast<float>(inv->radius());

    m_cachedInvertedOuter[0] = outerCX;
    m_cachedInvertedOuter[1] = outerCY;
    m_cachedInvertedOuter[2] = outerHW;
    m_cachedInvertedOuter[3] = outerHH;

    m_cachedInvertedInner[0] = innerCX;
    m_cachedInvertedInner[1] = innerCY;
    m_cachedInvertedInner[2] = innerHW;
    m_cachedInvertedInner[3] = innerHH;
}

void BlobShape::accumulateNeighbourFill(qsizetype index, const QVector<BlobShape*>& rectShapes, const float cornerX[4],
    const float cornerY[4], float smoothFactor, float factors[4]) const {
    const auto rectCount = m_cachedRects.size();
    const int excludeMask = m_cachedRects[index].excludeMask;
    const BlobShape* si = rectShapes[index];

    for (qsizetype j = 0; j < rectCount; ++j) {
        if (j == index)
            continue;
        if (excludeMask & (1 << j))
            continue;

        const BlobShape* sj = rectShapes[j];
        if (si->isCornerExcluded(sj) || sj->isCornerExcluded(si))
            continue;

        // Square each corner only near rj's edge; keep full radius far outside AND
        // deep inside rj (buried, so it can't crease the visible junction).
        const auto& rj = m_cachedRects[j];
        for (int k = 0; k < 4; ++k) {
            const float sd = cpuSdBox(cornerX[k], cornerY[k], rj.cx, rj.cy, rj.hw, rj.hh);
            factors[k] = std::min(factors[k], cornerFillFactor(sd, smoothFactor));
        }
    }
}

void BlobShape::accumulateInvertedFill(
    const float cornerX[4], const float cornerY[4], float smoothFactor, float factors[4]) const {
    const float icx = m_cachedInvertedInner[0];
    const float icy = m_cachedInvertedInner[1];
    const float ihw = m_cachedInvertedInner[2];
    const float ihh = m_cachedInvertedInner[3];

    for (int k = 0; k < 4; ++k) {
        const float sd = cpuSdBox(cornerX[k], cornerY[k], icx, icy, ihw, ihh);
        factors[k] = std::min(factors[k], cpuSmoothstep(0.0f, smoothFactor, -sd));
    }
}

void BlobShape::applyCornerFill(float smoothFactor, const QVector<BlobShape*>& rectShapes) {
    // Pre-computes effective per-corner radii (moves O(N^2) work from GPU to CPU)
    constexpr float k_minR = 2.0f;
    const bool cornerFill = m_group->cornerFill();
    const auto rectCount = m_cachedRects.size();

    for (qsizetype i = 0; i < rectCount; ++i) {
        float cornerX[4];
        float cornerY[4];
        rectCorners(m_cachedRects[i], cornerX, cornerY);

        float factors[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
        if (cornerFill) {
            accumulateNeighbourFill(i, rectShapes, cornerX, cornerY, smoothFactor, factors);
            if (m_cachedHasInverted)
                accumulateInvertedFill(cornerX, cornerY, smoothFactor, factors);
        }

        // Combine base radii with fill factors into effective per-corner radii
        auto& ri = m_cachedRects[i];
        for (int k = 0; k < 4; ++k) {
            ri.radius[k] = std::max(ri.radius[k] * factors[k], k_minR);
        }
    }
}

QSGNode* BlobShape::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) {
    Q_UNUSED(data);

    if (!m_group) {
        delete oldNode;
        return nullptr;
    }

    auto* node = static_cast<QSGGeometryNode*>(oldNode);
    if (!node) {
        node = new QSGGeometryNode;

        auto* geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4);
        geometry->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        auto* material = new BlobMaterial;
        material->setFlag(QSGMaterial::Blending);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }

    // Update geometry
    auto* geometry = node->geometry();
    auto* v = geometry->vertexDataAsTexturedPoint2D();

    const auto x0 = static_cast<float>(m_localPaddedRect.x());
    const auto y0 = static_cast<float>(m_localPaddedRect.y());
    const float x1 = x0 + static_cast<float>(m_localPaddedRect.width());
    const float y1 = y0 + static_cast<float>(m_localPaddedRect.height());

    v[0].set(x0, y0, 0.0f, 0.0f);
    v[1].set(x1, y0, 1.0f, 0.0f);
    v[2].set(x0, y1, 0.0f, 1.0f);
    v[3].set(x1, y1, 1.0f, 1.0f);

    node->markDirty(QSGNode::DirtyGeometry);

    // Update material
    auto* material = static_cast<BlobMaterial*>(node->material());
    material->m_paddedX = m_cachedPaddedX;
    material->m_paddedY = m_cachedPaddedY;
    material->m_paddedW = m_cachedPaddedW;
    material->m_paddedH = m_cachedPaddedH;
    material->m_smoothFactor = static_cast<float>(m_group->smoothing());
    material->m_myIndex = m_cachedMyIndex;
    material->m_color = m_group->color();
    material->m_hasInverted = m_cachedHasInverted ? 1 : 0;
    material->m_invertedRadius = m_cachedInvertedRadius;
    memcpy(material->m_invertedOuter, m_cachedInvertedOuter, sizeof(m_cachedInvertedOuter));
    memcpy(material->m_invertedInner, m_cachedInvertedInner, sizeof(m_cachedInvertedInner));

    const int count = static_cast<int>(m_cachedRects.size());
    material->m_rectCount = count;
    for (int i = 0; i < count; ++i)
        material->m_rects[i] = m_cachedRects[i];

    node->markDirty(QSGNode::DirtyMaterial);

    return node;
}

} // namespace caelestia::blobs
