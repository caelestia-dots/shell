#pragma once

#include "blobshape.hpp"

#include <qelapsedtimer.h>
#include <qpointer.h>
#include <qqmlengine.h>
#include <qqmllist.h>

class BlobRect : public BlobShape {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(qreal stiffness READ stiffness WRITE setStiffness NOTIFY stiffnessChanged)
    Q_PROPERTY(qreal damping READ damping WRITE setDamping NOTIFY dampingChanged)
    Q_PROPERTY(qreal deformScale READ deformScale WRITE setDeformScale NOTIFY deformScaleChanged)
    Q_PROPERTY(QQmlListProperty<BlobRect> exclude READ exclude NOTIFY excludeChanged)
    Q_PROPERTY(qreal topLeftRadius READ topLeftRadius WRITE setTopLeftRadius NOTIFY topLeftRadiusChanged)
    Q_PROPERTY(qreal topRightRadius READ topRightRadius WRITE setTopRightRadius NOTIFY topRightRadiusChanged)
    Q_PROPERTY(qreal bottomLeftRadius READ bottomLeftRadius WRITE setBottomLeftRadius NOTIFY bottomLeftRadiusChanged)
    Q_PROPERTY(
        qreal bottomRightRadius READ bottomRightRadius WRITE setBottomRightRadius NOTIFY bottomRightRadiusChanged)

public:
    explicit BlobRect(QQuickItem* parent = nullptr);
    ~BlobRect() override;

    qreal stiffness() const { return m_stiffness; }

    void setStiffness(qreal s) {
        if (!qFuzzyCompare(m_stiffness, s)) {
            m_stiffness = s;
            emit stiffnessChanged();
        }
    }

    qreal damping() const { return m_damping; }

    void setDamping(qreal d) {
        if (!qFuzzyCompare(m_damping, d)) {
            m_damping = d;
            emit dampingChanged();
        }
    }

    qreal deformScale() const { return m_deformScale; }

    void setDeformScale(qreal s) {
        if (!qFuzzyCompare(m_deformScale, s)) {
            m_deformScale = s;
            emit deformScaleChanged();
        }
    }

    QQmlListProperty<BlobRect> exclude();

    bool isExcluded(const BlobShape* other) const override;
    void cornerRadii(float out[4]) const override;

    qreal topLeftRadius() const { return m_topLeftRadius; }

    void setTopLeftRadius(qreal r);

    qreal topRightRadius() const { return m_topRightRadius; }

    void setTopRightRadius(qreal r);

    qreal bottomLeftRadius() const { return m_bottomLeftRadius; }

    void setBottomLeftRadius(qreal r);

    qreal bottomRightRadius() const { return m_bottomRightRadius; }

    void setBottomRightRadius(qreal r);

signals:
    void stiffnessChanged();
    void dampingChanged();
    void deformScaleChanged();
    void excludeChanged();
    void topLeftRadiusChanged();
    void topRightRadiusChanged();
    void bottomLeftRadiusChanged();
    void bottomRightRadiusChanged();

protected:
    void updatePolish() override;
    void updatePhysics() override;

private:
    void checkAtRest(float speed);

    // Physics state
    QPointF m_prevScenePos;
    QElapsedTimer m_elapsed;
    bool m_physicsActive = false;
    bool m_hasPrevPos = false;

    // Symmetric 2x2 deformation matrix components (3 independent: m00, m01,
    // m11) Rest state is identity: m00=1, m01=0, m11=1
    float m_dm00 = 1.0f;
    float m_dm01 = 0.0f;
    float m_dm11 = 1.0f;

    // Spring velocities for each component
    float m_dmVel00 = 0.0f;
    float m_dmVel01 = 0.0f;
    float m_dmVel11 = 0.0f;

    qreal m_stiffness = 200.0;
    qreal m_damping = 16.0;
    qreal m_deformScale = 0.0005;

    qreal m_topLeftRadius = -1;
    qreal m_topRightRadius = -1;
    qreal m_bottomLeftRadius = -1;
    qreal m_bottomRightRadius = -1;

    QList<QPointer<BlobRect>> m_exclude;

    static void excludeAppend(QQmlListProperty<BlobRect>* prop, BlobRect* rect);
    static qsizetype excludeCount(QQmlListProperty<BlobRect>* prop);
    static BlobRect* excludeAt(QQmlListProperty<BlobRect>* prop, qsizetype index);
    static void excludeClear(QQmlListProperty<BlobRect>* prop);
    static void excludeReplace(QQmlListProperty<BlobRect>* prop, qsizetype index, BlobRect* rect);
    static void excludeRemoveLast(QQmlListProperty<BlobRect>* prop);
};
