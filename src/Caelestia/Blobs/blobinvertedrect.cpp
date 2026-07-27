#include "blobinvertedrect.hpp"
#include "blobgroup.hpp"
#include "blobmaterial.hpp"

#include <qsggeometry.h>
#include <qsgnode.h>

#include <algorithm>
#include <cstring>

BlobInvertedRect::BlobInvertedRect(QQuickItem* parent)
    : BlobShape(parent) {}

static void setFrameIndices(quint16* idx) {
    // Top strip: 0-1-4, 1-5-4
    idx[0] = 0;
    idx[1] = 1;
    idx[2] = 4;
    idx[3] = 1;
    idx[4] = 5;
    idx[5] = 4;
    // Right strip: 1-2-5, 2-6-5
    idx[6] = 1;
    idx[7] = 2;
    idx[8] = 5;
    idx[9] = 2;
    idx[10] = 6;
    idx[11] = 5;
    // Bottom strip: 2-3-6, 3-7-6
    idx[12] = 2;
    idx[13] = 3;
    idx[14] = 6;
    idx[15] = 3;
    idx[16] = 7;
    idx[17] = 6;
    // Left strip: 3-0-7, 0-4-7
    idx[18] = 3;
    idx[19] = 0;
    idx[20] = 7;
    idx[21] = 0;
    idx[22] = 4;
    idx[23] = 7;
}

QSGNode* BlobInvertedRect::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) {
    if (!m_group) {
        delete oldNode;
        return nullptr;
    }

    const float pad = static_cast<float>(m_group->smoothing());

    // Compute inner hole boundary in local coords
    // Inset past the inner border edge by 2x smoothing to cover the blend zone
    const float inset = pad * 2.0f;
    const float holeLeft = static_cast<float>(m_borderLeft) + inset;
    const float holeTop = static_cast<float>(m_borderTop) + inset;
    const float holeRight = static_cast<float>(width() - m_borderRight) - inset;
    const float holeBot = static_cast<float>(height() - m_borderBottom) - inset;

    // If the hole is too small or invalid, fall back to full quad
    if (holeLeft >= holeRight || holeTop >= holeBot)
        return BlobShape::updatePaintNode(oldNode, nullptr);

    auto* node = static_cast<QSGGeometryNode*>(oldNode);

    const bool needsRebuild = !node || node->geometry()->vertexCount() != 8;

    if (needsRebuild) {
        delete oldNode;
        node = new QSGGeometryNode;

        auto* geometry =
            new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 8, 24, QSGGeometry::UnsignedShortType);
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        setFrameIndices(geometry->indexDataAsUShort());

        auto* material = new BlobMaterial;
        material->setFlag(QSGMaterial::Blending);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }

    // Outer bounds (local coords)
    const float x0 = static_cast<float>(m_localPaddedRect.x());
    const float y0 = static_cast<float>(m_localPaddedRect.y());
    const float x1 = x0 + static_cast<float>(m_localPaddedRect.width());
    const float y1 = y0 + static_cast<float>(m_localPaddedRect.height());
    const float w = x1 - x0;
    const float h = y1 - y0;

    // Update vertex positions and texture coordinates
    auto* v = node->geometry()->vertexDataAsTexturedPoint2D();

    // Outer corners
    v[0].set(x0, y0, 0.0f, 0.0f);
    v[1].set(x1, y0, 1.0f, 0.0f);
    v[2].set(x1, y1, 1.0f, 1.0f);
    v[3].set(x0, y1, 0.0f, 1.0f);
    // Inner corners (hole)
    v[4].set(holeLeft, holeTop, (holeLeft - x0) / w, (holeTop - y0) / h);
    v[5].set(holeRight, holeTop, (holeRight - x0) / w, (holeTop - y0) / h);
    v[6].set(holeRight, holeBot, (holeRight - x0) / w, (holeBot - y0) / h);
    v[7].set(holeLeft, holeBot, (holeLeft - x0) / w, (holeBot - y0) / h);

    node->markDirty(QSGNode::DirtyGeometry);

    // Update material uniforms
    auto* material = static_cast<BlobMaterial*>(node->material());
    material->m_paddedX = m_cachedPaddedX;
    material->m_paddedY = m_cachedPaddedY;
    material->m_paddedW = m_cachedPaddedW;
    material->m_paddedH = m_cachedPaddedH;
    material->m_smoothFactor = pad;
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

BlobInvertedRect::~BlobInvertedRect() {
    if (m_group)
        m_group->clearInvertedRect(this);
}

void BlobInvertedRect::setBorderLeft(qreal v) {
    if (qFuzzyCompare(m_borderLeft, v))
        return;
    m_borderLeft = v;
    emit borderLeftChanged();
    if (m_group)
        m_group->markDirty();
}

void BlobInvertedRect::setBorderRight(qreal v) {
    if (qFuzzyCompare(m_borderRight, v))
        return;
    m_borderRight = v;
    emit borderRightChanged();
    if (m_group)
        m_group->markDirty();
}

void BlobInvertedRect::setBorderTop(qreal v) {
    if (qFuzzyCompare(m_borderTop, v))
        return;
    m_borderTop = v;
    emit borderTopChanged();
    if (m_group)
        m_group->markDirty();
}

void BlobInvertedRect::setBorderBottom(qreal v) {
    if (qFuzzyCompare(m_borderBottom, v))
        return;
    m_borderBottom = v;
    emit borderBottomChanged();
    if (m_group)
        m_group->markDirty();
}

void BlobInvertedRect::registerWithGroup() {
    if (m_group)
        m_group->setInvertedRect(this);
}

void BlobInvertedRect::unregisterFromGroup() {
    if (m_group)
        m_group->clearInvertedRect(this);
}
