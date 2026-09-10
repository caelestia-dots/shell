#pragma once

#include <qmatrix4x4.h>
#include <qquickitem.h>
#include <qvector.h>

#include "blobmaterial.hpp"

namespace caelestia::blobs {

class BlobGroup;

class BlobShape : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(caelestia::blobs::BlobGroup* group READ group WRITE setGroup NOTIFY groupChanged)
    Q_PROPERTY(qreal radius READ radius WRITE setRadius NOTIFY radiusChanged)
    Q_PROPERTY(QMatrix4x4 deformMatrix READ deformMatrix NOTIFY deformMatrixChanged)
    Q_PROPERTY(QMatrix4x4 rawDeformMatrix READ rawDeformMatrix NOTIFY rawDeformMatrixChanged)

    friend class BlobGroup;

public:
    explicit BlobShape(QQuickItem* parent = nullptr);
    ~BlobShape() override = default;

    [[nodiscard]] BlobGroup* group() const;
    void setGroup(BlobGroup* g);

    [[nodiscard]] qreal radius() const;
    void setRadius(qreal r);

    [[nodiscard]] QMatrix4x4 deformMatrix() const;
    [[nodiscard]] QMatrix4x4 rawDeformMatrix() const;

signals:
    void groupChanged();
    void radiusChanged();
    void deformMatrixChanged();
    void rawDeformMatrixChanged();

protected:
    void componentComplete() override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void updatePolish() override;
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;

    [[nodiscard]] virtual bool isInvertedRect() const;
    [[nodiscard]] virtual bool isExcluded(const BlobShape* other) const;
    [[nodiscard]] virtual bool isCornerExcluded(const BlobShape* other) const;

    virtual void cornerRadii(float out[4]) const;
    virtual void updatePhysics();

    virtual void registerWithGroup();
    virtual void unregisterFromGroup();
    void updateCenteredDeformMatrix();

    [[nodiscard]] QRectF localPaddedRect(float pad) const;
    [[nodiscard]] QRectF paddedSceneRect(const QPointF& scenePos, float pad) const;
    void writeRectData(BlobRectData& r, const QPointF& scenePos) const;
    void updatePaddedBounds(float pad);
    void collectNearbyRects(float pad, QVector<BlobShape*>& rectShapes);
    void computeExcludeMasks(const QVector<BlobShape*>& rectShapes);
    [[nodiscard]] bool isNearInvertedBorder(float cx, float cy, float hw, float hh, float margin) const;
    void cacheInvertedRect(float pad);
    void accumulateNeighbourFill(qsizetype index, const QVector<BlobShape*>& rectShapes, const float cornerX[4],
        const float cornerY[4], float smoothFactor, float factors[4]) const;
    void accumulateInvertedFill(
        const float cornerX[4], const float cornerY[4], float smoothFactor, float factors[4]) const;
    void applyCornerFill(float smoothFactor, const QVector<BlobShape*>& rectShapes);

    BlobGroup* m_group = nullptr;
    qreal m_radius = 0;
    QMatrix4x4 m_deformMatrix; // identity by default
    QMatrix4x4 m_centeredDeformMatrix;

    // Cached data from updatePolish
    float m_cachedPaddedX = 0;
    float m_cachedPaddedY = 0;
    float m_cachedPaddedW = 0;
    float m_cachedPaddedH = 0;
    QRectF m_localPaddedRect;
    QVector<BlobRectData> m_cachedRects;
    int m_cachedMyIndex = -2;
    float m_pendingDx = 0;
    float m_pendingDy = 0;
    bool m_cachedHasInverted = false;
    float m_cachedInvertedRadius = 0;
    float m_cachedInvertedOuter[4] = {};
    float m_cachedInvertedInner[4] = {};
};

} // namespace caelestia::blobs
