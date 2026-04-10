#include "blobrect.hpp"
#include "blobgroup.hpp"

#include <algorithm>
#include <cmath>

BlobRect::BlobRect(QQuickItem* parent)
    : BlobShape(parent) {}

BlobRect::~BlobRect() {
    if (m_group)
        m_group->removeShape(this);
}

void BlobRect::updatePolish() {
    BlobShape::updatePolish();

    if (m_physicsActive) {
        // Check if deformation is visually imperceptible
        float totalDelta = std::abs(m_dm00 - 1.0f) + std::abs(m_dm01) + std::abs(m_dm11 - 1.0f);
        float totalVel = std::abs(m_dmVel00) + std::abs(m_dmVel01) + std::abs(m_dmVel11);

        if (totalDelta < 0.004f && totalVel < 0.05f) {
            // Snap to rest, no visible deformation
            m_dm00 = 1.0f;
            m_dm01 = 0.0f;
            m_dm11 = 1.0f;
            m_dmVel00 = m_dmVel01 = m_dmVel11 = 0.0f;
            m_deformMatrix = QMatrix4x4();
            emit rawDeformMatrixChanged();
            updateCenteredDeformMatrix();
            m_physicsActive = false;
        } else {
            QMetaObject::invokeMethod(
                this,
                [this]() {
                    if (m_physicsActive && m_group)
                        m_group->markDirty();
                },
                Qt::QueuedConnection);
        }
    }
}

void BlobRect::updatePhysics() {
    const QPointF scenePos = mapToScene(QPointF(width() / 2.0, height() / 2.0));

    if (!m_hasPrevPos) {
        m_prevScenePos = scenePos;
        m_elapsed.start();
        m_hasPrevPos = true;
        return;
    }

    const float dt = static_cast<float>(m_elapsed.restart()) / 1000.0f;
    if (dt > 0.1f || dt < 0.001f) {
        m_prevScenePos = scenePos;
        // Still check atRest on skipped frames to avoid getting stuck
        if (m_physicsActive)
            checkAtRest(0.0f);
        return;
    }

    const float velX = static_cast<float>(scenePos.x() - m_prevScenePos.x()) / dt;
    const float velY = static_cast<float>(scenePos.y() - m_prevScenePos.y()) / dt;
    m_prevScenePos = scenePos;

    const float speed = std::sqrt(velX * velX + velY * velY);

    if (!m_physicsActive) {
        if (speed < 5.0f)
            return;
        m_physicsActive = true;
    }

    // Compute target deformation matrix from velocity
    // R(θ) * diag(stretch, compress) * R(θ)^T
    const float kStretchFactor = static_cast<float>(m_deformScale);
    constexpr float kMaxStretch = 0.35f;

    float target00 = 1.0f;
    float target01 = 0.0f;
    float target11 = 1.0f;

    if (speed > 5.0f) {
        const float targetStretch = 1.0f + std::min(speed * kStretchFactor, kMaxStretch);
        const float targetCompress = 1.0f / targetStretch;

        const float cosA = velX / speed;
        const float sinA = velY / speed;
        const float cos2 = cosA * cosA;
        const float sin2 = sinA * sinA;
        const float cs = cosA * sinA;

        target00 = targetStretch * cos2 + targetCompress * sin2;
        target01 = (targetStretch - targetCompress) * cs;
        target11 = targetStretch * sin2 + targetCompress * cos2;
    }

    // Underdamped spring on each matrix component
    const float kStiffness = static_cast<float>(m_stiffness);
    const float kDamping = static_cast<float>(m_damping);

    const float accel00 = -kStiffness * (m_dm00 - target00) - kDamping * m_dmVel00;
    m_dmVel00 += accel00 * dt;
    m_dm00 += m_dmVel00 * dt;

    const float accel01 = -kStiffness * (m_dm01 - target01) - kDamping * m_dmVel01;
    m_dmVel01 += accel01 * dt;
    m_dm01 += m_dmVel01 * dt;

    const float accel11 = -kStiffness * (m_dm11 - target11) - kDamping * m_dmVel11;
    m_dmVel11 += accel11 * dt;
    m_dm11 += m_dmVel11 * dt;

    m_deformMatrix = QMatrix4x4(m_dm00, m_dm01, 0, 0, m_dm01, m_dm11, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    emit rawDeformMatrixChanged();
    updateCenteredDeformMatrix();

    checkAtRest(speed);
}

void BlobRect::setTopLeftRadius(qreal r) {
    if (!qFuzzyCompare(m_topLeftRadius, r)) {
        m_topLeftRadius = r;
        emit topLeftRadiusChanged();
        if (m_group)
            m_group->markDirty();
    }
}

void BlobRect::setTopRightRadius(qreal r) {
    if (!qFuzzyCompare(m_topRightRadius, r)) {
        m_topRightRadius = r;
        emit topRightRadiusChanged();
        if (m_group)
            m_group->markDirty();
    }
}

void BlobRect::setBottomLeftRadius(qreal r) {
    if (!qFuzzyCompare(m_bottomLeftRadius, r)) {
        m_bottomLeftRadius = r;
        emit bottomLeftRadiusChanged();
        if (m_group)
            m_group->markDirty();
    }
}

void BlobRect::setBottomRightRadius(qreal r) {
    if (!qFuzzyCompare(m_bottomRightRadius, r)) {
        m_bottomRightRadius = r;
        emit bottomRightRadiusChanged();
        if (m_group)
            m_group->markDirty();
    }
}

void BlobRect::cornerRadii(float out[4]) const {
    const auto base = static_cast<float>(m_radius);
    out[0] = m_topRightRadius >= 0 ? static_cast<float>(m_topRightRadius) : base;
    out[1] = m_bottomRightRadius >= 0 ? static_cast<float>(m_bottomRightRadius) : base;
    out[2] = m_bottomLeftRadius >= 0 ? static_cast<float>(m_bottomLeftRadius) : base;
    out[3] = m_topLeftRadius >= 0 ? static_cast<float>(m_topLeftRadius) : base;
}

bool BlobRect::isExcluded(const BlobShape* other) const {
    for (const auto& ptr : m_exclude) {
        if (ptr == other)
            return true;
    }
    return false;
}

QQmlListProperty<BlobRect> BlobRect::exclude() {
    return QQmlListProperty<BlobRect>(
        this, nullptr, &excludeAppend, &excludeCount, &excludeAt, &excludeClear, &excludeReplace, &excludeRemoveLast);
}

void BlobRect::excludeAppend(QQmlListProperty<BlobRect>* prop, BlobRect* rect) {
    auto* self = static_cast<BlobRect*>(prop->object);
    self->m_exclude.append(rect);
    if (self->m_group)
        self->m_group->markDirty();
    emit self->excludeChanged();
}

qsizetype BlobRect::excludeCount(QQmlListProperty<BlobRect>* prop) {
    auto* self = static_cast<BlobRect*>(prop->object);
    return self->m_exclude.size();
}

BlobRect* BlobRect::excludeAt(QQmlListProperty<BlobRect>* prop, qsizetype index) {
    auto* self = static_cast<BlobRect*>(prop->object);
    return self->m_exclude.at(index);
}

void BlobRect::excludeClear(QQmlListProperty<BlobRect>* prop) {
    auto* self = static_cast<BlobRect*>(prop->object);
    if (self->m_exclude.isEmpty())
        return;
    self->m_exclude.clear();
    if (self->m_group)
        self->m_group->markDirty();
    emit self->excludeChanged();
}

void BlobRect::excludeReplace(QQmlListProperty<BlobRect>* prop, qsizetype index, BlobRect* rect) {
    auto* self = static_cast<BlobRect*>(prop->object);
    self->m_exclude[index] = rect;
    if (self->m_group)
        self->m_group->markDirty();
    emit self->excludeChanged();
}

void BlobRect::excludeRemoveLast(QQmlListProperty<BlobRect>* prop) {
    auto* self = static_cast<BlobRect*>(prop->object);
    if (self->m_exclude.isEmpty())
        return;
    self->m_exclude.removeLast();
    if (self->m_group)
        self->m_group->markDirty();
    emit self->excludeChanged();
}

void BlobRect::checkAtRest(float speed) {
    constexpr float kEpsilon = 0.002f;
    const bool atRest = std::abs(m_dm00 - 1.0f) < kEpsilon && std::abs(m_dm01) < kEpsilon &&
                        std::abs(m_dm11 - 1.0f) < kEpsilon && std::abs(m_dmVel00) < kEpsilon &&
                        std::abs(m_dmVel01) < kEpsilon && std::abs(m_dmVel11) < kEpsilon && speed < 5.0f;

    if (atRest) {
        m_dm00 = 1.0f;
        m_dm01 = 0.0f;
        m_dm11 = 1.0f;
        m_dmVel00 = 0.0f;
        m_dmVel01 = 0.0f;
        m_dmVel11 = 0.0f;
        m_deformMatrix = QMatrix4x4(); // identity
        emit rawDeformMatrixChanged();
        updateCenteredDeformMatrix();
        m_physicsActive = false;
    }
}
