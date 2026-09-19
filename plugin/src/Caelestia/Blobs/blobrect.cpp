#include "blobrect.hpp"

#include <algorithm>
#include <cmath>

#include "blobgroup.hpp"

namespace caelestia::blobs {

namespace {

// How long an imperceptible deformation takes to retire to identity.
constexpr float k_retireMs = 120.0f;

} // namespace

BlobRect::BlobRect(QQuickItem* parent)
    : BlobShape(parent) {}

BlobRect::~BlobRect() {
    if (m_group)
        m_group->removeShape(this);
}

void BlobRect::updatePolish() {
    BlobShape::updatePolish();

    if (!m_physicsActive)
        return;

    if (m_retiring) {
        const float t = std::clamp(static_cast<float>(m_retireElapsed.elapsed()) / k_retireMs, 0.0f, 1.0f);
        const float s = t * t * (3.0f - 2.0f * t); // Smoothstep: zero velocity at both ends

        if (t >= 1.0f) {
            m_dm00 = 1.0f;
            m_dm01 = 0.0f;
            m_dm11 = 1.0f;
            m_deformMatrix = QMatrix4x4();
            m_retiring = false;
            m_physicsActive = false;
        } else {
            m_dm00 = m_retire00 + (1.0f - m_retire00) * s;
            m_dm01 = m_retire01 - m_retire01 * s;
            m_dm11 = m_retire11 + (1.0f - m_retire11) * s;
            m_deformMatrix = QMatrix4x4(m_dm00, m_dm01, 0, 0, m_dm01, m_dm11, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
        }

        emit rawDeformMatrixChanged();
        updateCenteredDeformMatrix();

        if (!m_physicsActive)
            return;
    } else {
        // Deformation is visually imperceptible, so retire it. Fade rather than
        // assign identity: this matrix transforms the panel content as well as
        // the blob background, so a discrete step jolts the whole widget a beat
        // after its open animation has already finished.
        const float totalDelta = std::abs(m_dm00 - 1.0f) + std::abs(m_dm01) + std::abs(m_dm11 - 1.0f);
        const float totalVel = std::abs(m_dmVel00) + std::abs(m_dmVel01) + std::abs(m_dmVel11);

        if (totalDelta < 0.004f && totalVel < 0.05f)
            beginRetire();
    }

    QMetaObject::invokeMethod(
        this,
        [this]() {
            if (m_physicsActive && m_group)
                m_group->markDirty();
        },
        Qt::QueuedConnection);
}

void BlobRect::beginRetire() {
    m_retire00 = m_dm00;
    m_retire01 = m_dm01;
    m_retire11 = m_dm11;
    m_dmVel00 = m_dmVel01 = m_dmVel11 = 0.0f;
    m_retireElapsed.start();
    m_retiring = true;
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

    if (m_retiring) {
        // Movement resumed mid-fade: hand control back to the spring from wherever
        // the fade got to. Otherwise leave the matrix to updatePolish.
        if (speed > 5.0f)
            m_retiring = false;
        else
            return;
    }

    if (!m_physicsActive) {
        if (speed < 5.0f)
            return;
        m_physicsActive = true;
    }

    // Compute target deformation matrix from velocity
    // R(θ) * diag(stretch, compress) * R(θ)^T
    const auto stretchFactor = static_cast<float>(m_deformScale);
    constexpr float k_maxStretch = 0.35f;

    float target00 = 1.0f;
    float target01 = 0.0f;
    float target11 = 1.0f;

    if (speed > 5.0f) {
        const float targetStretch = 1.0f + std::min(speed * stretchFactor, k_maxStretch);
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

    // Underdamped spring on each matrix component. Damping is integrated implicitly
    // (the friction term uses the new velocity, solved in closed form) so the 1/(1 + c*dt)
    // factor stays in (0, 1) for any dt; an explicit -c*v*dt term would flip sign and inject
    // energy once c*dt > 1 (here dt > ~62ms), making the deformation diverge on slow frames.
    const auto stiffness = static_cast<float>(m_stiffness);
    const auto damping = static_cast<float>(m_damping);
    const float invDamp = 1.0f / (1.0f + damping * dt);

    m_dmVel00 = (m_dmVel00 - stiffness * (m_dm00 - target00) * dt) * invDamp;
    m_dm00 += m_dmVel00 * dt;

    m_dmVel01 = (m_dmVel01 - stiffness * (m_dm01 - target01) * dt) * invDamp;
    m_dm01 += m_dmVel01 * dt;

    m_dmVel11 = (m_dmVel11 - stiffness * (m_dm11 - target11) * dt) * invDamp;
    m_dm11 += m_dmVel11 * dt;

    m_deformMatrix = QMatrix4x4(m_dm00, m_dm01, 0, 0, m_dm01, m_dm11, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    emit rawDeformMatrixChanged();
    updateCenteredDeformMatrix();

    checkAtRest(speed);
}

qreal BlobRect::stiffness() const {
    return m_stiffness;
}

void BlobRect::setStiffness(qreal s) {
    if (!qFuzzyCompare(m_stiffness, s)) {
        m_stiffness = s;
        emit stiffnessChanged();
    }
}

qreal BlobRect::damping() const {
    return m_damping;
}

void BlobRect::setDamping(qreal damping) {
    if (!qFuzzyCompare(m_damping, damping)) {
        m_damping = damping;
        emit dampingChanged();
    }
}

qreal BlobRect::deformScale() const {
    return m_deformScale;
}

void BlobRect::setDeformScale(qreal s) {
    if (!qFuzzyCompare(m_deformScale, s)) {
        m_deformScale = s;
        emit deformScaleChanged();
    }
}

qreal BlobRect::topLeftRadius() const {
    return m_topLeftRadius;
}

void BlobRect::setTopLeftRadius(qreal r) {
    if (!qFuzzyCompare(m_topLeftRadius, r)) {
        m_topLeftRadius = r;
        emit topLeftRadiusChanged();
        if (m_group)
            m_group->markDirty();
    }
}

qreal BlobRect::topRightRadius() const {
    return m_topRightRadius;
}

void BlobRect::setTopRightRadius(qreal r) {
    if (!qFuzzyCompare(m_topRightRadius, r)) {
        m_topRightRadius = r;
        emit topRightRadiusChanged();
        if (m_group)
            m_group->markDirty();
    }
}

qreal BlobRect::bottomLeftRadius() const {
    return m_bottomLeftRadius;
}

void BlobRect::setBottomLeftRadius(qreal r) {
    if (!qFuzzyCompare(m_bottomLeftRadius, r)) {
        m_bottomLeftRadius = r;
        emit bottomLeftRadiusChanged();
        if (m_group)
            m_group->markDirty();
    }
}

qreal BlobRect::bottomRightRadius() const {
    return m_bottomRightRadius;
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
    const auto maxR = static_cast<float>(std::min(width(), height())) * 0.5f;
    const auto base = std::min(static_cast<float>(m_radius), maxR);
    out[0] = std::min(m_topRightRadius >= 0 ? static_cast<float>(m_topRightRadius) : base, maxR);
    out[1] = std::min(m_bottomRightRadius >= 0 ? static_cast<float>(m_bottomRightRadius) : base, maxR);
    out[2] = std::min(m_bottomLeftRadius >= 0 ? static_cast<float>(m_bottomLeftRadius) : base, maxR);
    out[3] = std::min(m_topLeftRadius >= 0 ? static_cast<float>(m_topLeftRadius) : base, maxR);
}

bool BlobRect::isExcluded(const BlobShape* other) const {
    return std::ranges::any_of(m_exclude, [other](const auto& ptr) {
        return ptr == other;
    });
}

bool BlobRect::isCornerExcluded(const BlobShape* other) const {
    return std::ranges::any_of(m_excludeCorners, [other](const auto& ptr) {
        return ptr == other;
    });
}

QQmlListProperty<BlobRect> BlobRect::exclude() {
    return { this, nullptr, &excludeAppend, &excludeCount, &excludeAt, &excludeClear, &excludeReplace,
        &excludeRemoveLast };
}

QQmlListProperty<BlobRect> BlobRect::excludeCorners() {
    return { this, nullptr, &excludeCornersAppend, &excludeCornersCount, &excludeCornersAt, &excludeCornersClear,
        &excludeCornersReplace, &excludeCornersRemoveLast };
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

void BlobRect::excludeCornersAppend(QQmlListProperty<BlobRect>* prop, BlobRect* rect) {
    auto* self = static_cast<BlobRect*>(prop->object);
    self->m_excludeCorners.append(rect);
    if (self->m_group)
        self->m_group->markDirty();
    emit self->excludeCornersChanged();
}

qsizetype BlobRect::excludeCornersCount(QQmlListProperty<BlobRect>* prop) {
    auto* self = static_cast<BlobRect*>(prop->object);
    return self->m_excludeCorners.size();
}

BlobRect* BlobRect::excludeCornersAt(QQmlListProperty<BlobRect>* prop, qsizetype index) {
    auto* self = static_cast<BlobRect*>(prop->object);
    return self->m_excludeCorners.at(index);
}

void BlobRect::excludeCornersClear(QQmlListProperty<BlobRect>* prop) {
    auto* self = static_cast<BlobRect*>(prop->object);
    if (self->m_excludeCorners.isEmpty())
        return;
    self->m_excludeCorners.clear();
    if (self->m_group)
        self->m_group->markDirty();
    emit self->excludeCornersChanged();
}

void BlobRect::excludeCornersReplace(QQmlListProperty<BlobRect>* prop, qsizetype index, BlobRect* rect) {
    auto* self = static_cast<BlobRect*>(prop->object);
    self->m_excludeCorners[index] = rect;
    if (self->m_group)
        self->m_group->markDirty();
    emit self->excludeCornersChanged();
}

void BlobRect::excludeCornersRemoveLast(QQmlListProperty<BlobRect>* prop) {
    auto* self = static_cast<BlobRect*>(prop->object);
    if (self->m_excludeCorners.isEmpty())
        return;
    self->m_excludeCorners.removeLast();
    if (self->m_group)
        self->m_group->markDirty();
    emit self->excludeCornersChanged();
}

void BlobRect::checkAtRest(float speed) {
    if (m_retiring)
        return;

    constexpr float k_epsilon = 0.002f;
    const bool atRest = std::abs(m_dm00 - 1.0f) < k_epsilon && std::abs(m_dm01) < k_epsilon &&
                        std::abs(m_dm11 - 1.0f) < k_epsilon && std::abs(m_dmVel00) < k_epsilon &&
                        std::abs(m_dmVel01) < k_epsilon && std::abs(m_dmVel11) < k_epsilon && speed < 5.0f;

    if (atRest)
        beginRetire();
}

} // namespace caelestia::blobs
