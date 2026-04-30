#include "blobshape.hpp"
#include "blobgroup.hpp"
#include "blobinvertedrect.hpp"

#include <qsggeometry.h>
#include <qsgnode.h>

#include <algorithm>
#include <cmath>

static float deformPadding(const QMatrix4x4& dm, float hw, float hh) {
    // Bounding box of the deformed shape: |M * corners|
    const float dm00 = dm(0, 0), dm01 = dm(0, 1);
    const float dm10 = dm(1, 0), dm11 = dm(1, 1);
    const float boundX = std::abs(dm00) * hw + std::abs(dm01) * hh;
    const float boundY = std::abs(dm10) * hw + std::abs(dm11) * hh;
    const float extraX = std::max(boundX - hw, 0.0f) + std::abs(dm(0, 3));
    const float extraY = std::max(boundY - hh, 0.0f) + std::abs(dm(1, 3));
    return std::max(extraX, extraY);
}

static float cpuSdBox(float px, float py, float cx, float cy, float hw, float hh) {
    const float dx = std::abs(px - cx) - hw;
    const float dy = std::abs(py - cy) - hh;
    const float mdx = std::max(dx, 0.0f);
    const float mdy = std::max(dy, 0.0f);
    return std::sqrt(mdx * mdx + mdy * mdy) + std::min(std::max(dx, dy), 0.0f);
}

static float cpuSmoothstep(float edge0, float edge1, float x) {
    const float t = std::clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

BlobShape::BlobShape(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents);
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

void BlobShape::setRadius(qreal r) {
    if (qFuzzyCompare(m_radius, r))
        return;
    m_radius = r;
    emit radiusChanged();
    if (m_group)
        m_group->markDirty();
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

void BlobShape::cornerRadii(float out[4]) const {
    const auto maxR = static_cast<float>(std::min(width(), height())) * 0.5f;
    const auto r = std::min(static_cast<float>(m_radius), maxR);
    out[0] = r;
    out[1] = r;
    out[2] = r;
    out[3] = r;
}

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

    const QPointF scenePos = mapToScene(QPointF(0, 0));
    const float pad = static_cast<float>(m_group->smoothing());

    if (isInvertedRect()) {
        m_cachedPaddedX = static_cast<float>(scenePos.x());
        m_cachedPaddedY = static_cast<float>(scenePos.y());
        m_cachedPaddedW = static_cast<float>(width());
        m_cachedPaddedH = static_cast<float>(height());
        m_localPaddedRect = QRectF(0, 0, width(), height());
    } else {
        const float hw = static_cast<float>(width()) * 0.5f;
        const float hh = static_cast<float>(height()) * 0.5f;
        const float totalPad = pad + deformPadding(m_deformMatrix, hw, hh);

        m_cachedPaddedX = static_cast<float>(scenePos.x()) - totalPad;
        m_cachedPaddedY = static_cast<float>(scenePos.y()) - totalPad;
        m_cachedPaddedW = static_cast<float>(width()) + 2.0f * totalPad;
        m_cachedPaddedH = static_cast<float>(height()) + 2.0f * totalPad;
        m_localPaddedRect = QRectF(static_cast<double>(-totalPad), static_cast<double>(-totalPad),
            width() + 2.0 * static_cast<double>(totalPad), height() + 2.0 * static_cast<double>(totalPad));
    }

    // Filter nearby normal rects
    m_cachedRects.clear();
    m_cachedMyIndex = -2;
    const QRectF myPadded(static_cast<double>(m_cachedPaddedX), static_cast<double>(m_cachedPaddedY),
        static_cast<double>(m_cachedPaddedW), static_cast<double>(m_cachedPaddedH));

    // Track shape pointers parallel to m_cachedRects for pairwise exclusion lookups
    QVector<BlobShape*> rectShapes;
    rectShapes.reserve(m_group->shapes().size());

    for (BlobShape* other : m_group->shapes()) {
        if (other->isInvertedRect())
            continue;

        // Skip zero-size rects
        if (other->width() <= 0 || other->height() <= 0)
            continue;

        if (isExcluded(other))
            continue;

        const QPointF otherScene = other->mapToScene(QPointF(0, 0));

        bool include = false;
        if (isInvertedRect()) {
            include = true;
        } else {
            const float otherHW = static_cast<float>(other->width()) * 0.5f;
            const float otherHH = static_cast<float>(other->height()) * 0.5f;
            const float otherPad = pad + deformPadding(other->m_deformMatrix, otherHW, otherHH);
            const QRectF otherPadded(otherScene.x() - static_cast<double>(otherPad),
                otherScene.y() - static_cast<double>(otherPad), other->width() + 2.0 * static_cast<double>(otherPad),
                other->height() + 2.0 * static_cast<double>(otherPad));
            include = myPadded.intersects(otherPadded);
        }

        if (include) {
            if (other == this)
                m_cachedMyIndex = static_cast<int>(m_cachedRects.size());

            const QMatrix4x4& dm = other->m_deformMatrix;
            const float a = dm(0, 0), b = dm(1, 0);
            const float c = dm(0, 1), d = dm(1, 1);

            BlobRectData r;
            r.cx = static_cast<float>(otherScene.x() + other->width() / 2.0);
            r.cy = static_cast<float>(otherScene.y() + other->height() / 2.0);
            r.hw = static_cast<float>(other->width() / 2.0);
            r.hh = static_cast<float>(other->height() / 2.0);
            other->cornerRadii(r.radius);
            r.offsetX = dm(0, 3);
            r.offsetY = dm(1, 3);

            // Pre-compute inverse deformation matrix
            const float det = a * d - c * b;
            const float invDet = std::abs(det) > 1e-6f ? 1.0f / det : 1.0f;
            r.invDeform[0] = d * invDet;
            r.invDeform[1] = -b * invDet;
            r.invDeform[2] = -c * invDet;
            r.invDeform[3] = a * invDet;

            // Pre-compute minimum eigenvalue (avoids per-pixel sqrt)
            const float halfTr = 0.5f * (a + d);
            const float halfDiff = 0.5f * (a - d);
            r.minEig = halfTr - std::sqrt(halfDiff * halfDiff + c * c);

            // Pre-compute screen-space AABB half-extents
            r.screenHalfX = std::abs(a) * r.hw + std::abs(c) * r.hh;
            r.screenHalfY = std::abs(b) * r.hw + std::abs(d) * r.hh;

            m_cachedRects.append(r);
            rectShapes.append(other);
        }
    }

    if (isInvertedRect())
        m_cachedMyIndex = -1;

    // Compute pairwise exclude masks. Bit j in entry i is set iff rect i excludes rect j
    // or rect j excludes rect i. The shader uses this to avoid smin between excluded pairs.
    const auto cachedCount = m_cachedRects.size();
    for (qsizetype i = 0; i < cachedCount; ++i) {
        int mask = 0;
        BlobShape* si = rectShapes[i];
        for (qsizetype j = 0; j < cachedCount; ++j) {
            if (j == i)
                continue;
            BlobShape* sj = rectShapes[j];
            if (si->isExcluded(sj) || sj->isExcluded(si))
                mask |= (1 << j);
        }
        m_cachedRects[i].excludeMask = mask;
    }

    // Cache inverted rect data
    m_cachedHasInverted = false;
    m_cachedInvertedRadius = 0;
    memset(m_cachedInvertedOuter, 0, sizeof(m_cachedInvertedOuter));
    memset(m_cachedInvertedInner, 0, sizeof(m_cachedInvertedInner));

    auto* inv = m_group->invertedRect();
    if (inv) {
        const QPointF invScene = inv->mapToScene(QPointF(0, 0));
        const float outerCX = static_cast<float>(invScene.x() + inv->width() / 2.0);
        const float outerCY = static_cast<float>(invScene.y() + inv->height() / 2.0);
        const float outerHW = static_cast<float>(inv->width() / 2.0);
        const float outerHH = static_cast<float>(inv->height() / 2.0);

        const float innerCX = outerCX + static_cast<float>((inv->borderLeft() - inv->borderRight()) / 2.0);
        const float innerCY = outerCY + static_cast<float>((inv->borderTop() - inv->borderBottom()) / 2.0);
        const float innerHW = outerHW - static_cast<float>((inv->borderLeft() + inv->borderRight()) / 2.0);
        const float innerHH = outerHH - static_cast<float>((inv->borderTop() + inv->borderBottom()) / 2.0);

        // Check if this rect is near the border (within 2x smoothing of inner edge)
        bool nearBorder = isInvertedRect();
        if (!nearBorder) {
            const float margin = pad * 2.0f;
            const float myCX = m_cachedPaddedX + m_cachedPaddedW * 0.5f;
            const float myCY = m_cachedPaddedY + m_cachedPaddedH * 0.5f;
            const float myHW = m_cachedPaddedW * 0.5f;
            const float myHH = m_cachedPaddedH * 0.5f;
            // Near border if any edge of padded rect is within margin of inner edge
            nearBorder = (myCX - myHW < innerCX - innerHW + margin) || (myCX + myHW > innerCX + innerHW - margin) ||
                         (myCY - myHH < innerCY - innerHH + margin) || (myCY + myHH > innerCY + innerHH - margin);
        }

        if (nearBorder) {
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
    }

    // Pre-compute effective per-corner radii (moves O(N²) work from GPU to CPU)
    const float smoothFactor = pad;
    constexpr float minR = 2.0f;
    const auto rectCount = m_cachedRects.size();
    for (qsizetype i = 0; i < rectCount; ++i) {
        auto& ri = m_cachedRects[i];
        const int riExcludeMask = ri.excludeMask;
        float fTr = 1.0f, fBr = 1.0f, fBl = 1.0f, fTl = 1.0f;

        const float cTrX = ri.cx + ri.hw, cTrY = ri.cy - ri.hh;
        const float cBrX = ri.cx + ri.hw, cBrY = ri.cy + ri.hh;
        const float cBlX = ri.cx - ri.hw, cBlY = ri.cy + ri.hh;
        const float cTlX = ri.cx - ri.hw, cTlY = ri.cy - ri.hh;

        for (qsizetype j = 0; j < rectCount; ++j) {
            if (j == i)
                continue;
            if (riExcludeMask & (1 << j))
                continue;
            const auto& rj = m_cachedRects[j];
            fTr = std::min(fTr, cpuSmoothstep(0.0f, smoothFactor, cpuSdBox(cTrX, cTrY, rj.cx, rj.cy, rj.hw, rj.hh)));
            fBr = std::min(fBr, cpuSmoothstep(0.0f, smoothFactor, cpuSdBox(cBrX, cBrY, rj.cx, rj.cy, rj.hw, rj.hh)));
            fBl = std::min(fBl, cpuSmoothstep(0.0f, smoothFactor, cpuSdBox(cBlX, cBlY, rj.cx, rj.cy, rj.hw, rj.hh)));
            fTl = std::min(fTl, cpuSmoothstep(0.0f, smoothFactor, cpuSdBox(cTlX, cTlY, rj.cx, rj.cy, rj.hw, rj.hh)));
        }

        if (m_cachedHasInverted) {
            const float icx = m_cachedInvertedInner[0];
            const float icy = m_cachedInvertedInner[1];
            const float ihw = m_cachedInvertedInner[2];
            const float ihh = m_cachedInvertedInner[3];
            fTr = std::min(fTr, cpuSmoothstep(0.0f, smoothFactor, -cpuSdBox(cTrX, cTrY, icx, icy, ihw, ihh)));
            fBr = std::min(fBr, cpuSmoothstep(0.0f, smoothFactor, -cpuSdBox(cBrX, cBrY, icx, icy, ihw, ihh)));
            fBl = std::min(fBl, cpuSmoothstep(0.0f, smoothFactor, -cpuSdBox(cBlX, cBlY, icx, icy, ihw, ihh)));
            fTl = std::min(fTl, cpuSmoothstep(0.0f, smoothFactor, -cpuSdBox(cTlX, cTlY, icx, icy, ihw, ihh)));
        }

        // Combine base radii with fill factors into effective per-corner radii
        ri.radius[0] = std::max(ri.radius[0] * fTr, minR);
        ri.radius[1] = std::max(ri.radius[1] * fBr, minR);
        ri.radius[2] = std::max(ri.radius[2] * fBl, minR);
        ri.radius[3] = std::max(ri.radius[3] * fTl, minR);
    }
}

QSGNode* BlobShape::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) {
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

    const float x0 = static_cast<float>(m_localPaddedRect.x());
    const float y0 = static_cast<float>(m_localPaddedRect.y());
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

    const int count = static_cast<int>(qMin(m_cachedRects.size(), qsizetype(16)));
    material->m_rectCount = count;
    for (int i = 0; i < count; ++i)
        material->m_rects[i] = m_cachedRects[i];

    node->markDirty(QSGNode::DirtyMaterial);

    return node;
}
