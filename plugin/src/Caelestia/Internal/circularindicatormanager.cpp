#include "circularindicatormanager.hpp"
#include <qeasingcurve.h>
#include <qpoint.h>

namespace {

namespace advance {

constexpr qint32 TOTAL_CYCLES = 4;
constexpr qint32 TOTAL_DURATION_IN_MS = 5400;
constexpr qint32 DURATION_TO_EXPAND_IN_MS = 667;
constexpr qint32 DURATION_TO_COLLAPSE_IN_MS = 667;
constexpr qint32 DURATION_TO_COMPLETE_END_IN_MS = 333;
constexpr qint32 TAIL_DEGREES_OFFSET = -20;
constexpr qint32 EXTRA_DEGREES_PER_CYCLE = 250;
constexpr qint32 CONSTANT_ROTATION_DEGREES = 1520;

constexpr std::array<qint32, TOTAL_CYCLES> DELAY_TO_EXPAND_IN_MS = { 0, 1350, 2700, 4050 };
constexpr std::array<qint32, TOTAL_CYCLES> DELAY_TO_COLLAPSE_IN_MS = { 667, 2017, 3367, 4717 };

} // namespace advance

namespace retreat {

constexpr qint32 TOTAL_DURATION_IN_MS = 6000;
constexpr qint32 DURATION_SPIN_IN_MS = 500;
constexpr qint32 DURATION_GROW_ACTIVE_IN_MS = 3000;
constexpr qint32 DURATION_SHRINK_ACTIVE_IN_MS = 3000;
constexpr std::array DELAY_SPINS_IN_MS = { 0, 1500, 3000, 4500 };
constexpr qint32 DELAY_GROW_ACTIVE_IN_MS = 0;
constexpr qint32 DELAY_SHRINK_ACTIVE_IN_MS = 3000;
constexpr qint32 DURATION_TO_COMPLETE_END_IN_MS = 500;

// Constants for animation values.

// The total degrees that a constant rotation goes by.
constexpr qint32 CONSTANT_ROTATION_DEGREES = 1080;
// Despite of the constant rotation, there are also 5 extra rotations the entire animation. The
// total degrees that each extra rotation goes by.
constexpr qint32 SPIN_ROTATION_DEGREES = 90;
constexpr std::array<qreal, 2> END_FRACTION_RANGE = { 0.10, 0.87 };

} // namespace retreat

inline qreal getFractionInRange(qreal playtime, qreal start, qreal duration) {
    const auto fraction = (playtime - start) / duration;
    return std::clamp(fraction, 0.0, 1.0);
}

} // namespace

namespace caelestia::internal {

CircularIndicatorManager::CircularIndicatorManager(QObject* parent)
    : QObject(parent)
    , m_type(IndeterminateAnimationType::Advance)
    , m_curve(QEasingCurve(QEasingCurve::BezierSpline))
    , m_progress(0)
    , m_startFraction(0)
    , m_endFraction(0)
    , m_rotation(0)
    , m_completeEndProgress(0) {
    // Fast out slow in
    m_curve.addCubicBezierSegment({ 0.4, 0.0 }, { 0.2, 1.0 }, { 1.0, 1.0 });
}

qreal CircularIndicatorManager::startFraction() const {
    return m_startFraction;
}

qreal CircularIndicatorManager::endFraction() const {
    return m_endFraction;
}

qreal CircularIndicatorManager::rotation() const {
    return m_rotation;
}

qreal CircularIndicatorManager::progress() const {
    return m_progress;
}

void CircularIndicatorManager::setProgress(qreal progress) {
    update(progress);
}

qreal CircularIndicatorManager::duration() const {
    if (m_type == IndeterminateAnimationType::Advance) {
        return advance::TOTAL_DURATION_IN_MS;
    } else {
        return retreat::TOTAL_DURATION_IN_MS;
    }
}

qreal CircularIndicatorManager::completeEndDuration() const {
    if (m_type == IndeterminateAnimationType::Advance) {
        return advance::DURATION_TO_COMPLETE_END_IN_MS;
    } else {
        return retreat::DURATION_TO_COMPLETE_END_IN_MS;
    }
}

CircularIndicatorManager::IndeterminateAnimationType CircularIndicatorManager::indeterminateAnimationType() const {
    return m_type;
}

void CircularIndicatorManager::setIndeterminateAnimationType(IndeterminateAnimationType t) {
    if (m_type != t) {
        m_type = t;
        emit indeterminateAnimationTypeChanged();
    }
}

qreal CircularIndicatorManager::completeEndProgress() const {
    return m_completeEndProgress;
}

void CircularIndicatorManager::setCompleteEndProgress(qreal progress) {
    if (qFuzzyCompare(m_completeEndProgress + 1.0, progress + 1.0)) {
        return;
    }

    m_completeEndProgress = progress;
    emit completeEndProgressChanged();

    update(m_progress);
}

void CircularIndicatorManager::update(qreal progress) {
    if (qFuzzyCompare(m_progress + 1.0, progress + 1.0)) {
        return;
    }

    if (m_type == IndeterminateAnimationType::Advance) {
        updateAdvance(progress);
    } else {
        updateRetreat(progress);
    }

    m_progress = progress;
    emit progressChanged();
}

void CircularIndicatorManager::updateRetreat(qreal progress) {
    using namespace retreat;
    const auto playtime = progress * TOTAL_DURATION_IN_MS;

    // Constant rotation.
    const qreal constantRotation = CONSTANT_ROTATION_DEGREES * progress;
    // Extra rotation for the faster spinning.
    qreal spinRotation = 0;
    for (const int spinDelay : DELAY_SPINS_IN_MS) {
        spinRotation += m_curve.valueForProgress(getFractionInRange(playtime, spinDelay, DURATION_SPIN_IN_MS)) *
                        SPIN_ROTATION_DEGREES;
    }
    m_rotation = constantRotation + spinRotation;
    emit rotationChanged();

    // Grow active indicator.
    qreal fraction =
        m_curve.valueForProgress(getFractionInRange(playtime, DELAY_GROW_ACTIVE_IN_MS, DURATION_GROW_ACTIVE_IN_MS));
    fraction -=
        m_curve.valueForProgress(getFractionInRange(playtime, DELAY_SHRINK_ACTIVE_IN_MS, DURATION_SHRINK_ACTIVE_IN_MS));

    if (!qFuzzyIsNull(m_startFraction)) {
        m_startFraction = 0.0;
        emit startFractionChanged();
    }
    const auto oldEndFrac = m_endFraction;
    m_endFraction = std::lerp(END_FRACTION_RANGE[0], END_FRACTION_RANGE[1], fraction);

    // Completing animation.
    if (m_completeEndProgress > 0) {
        m_endFraction *= 1 - m_completeEndProgress;
    }

    if (!qFuzzyCompare(m_endFraction + 1.0, oldEndFrac + 1.0)) {
        emit endFractionChanged();
    }
}

void CircularIndicatorManager::updateAdvance(qreal progress) {
    using namespace advance;
    const auto playtime = progress * TOTAL_DURATION_IN_MS;

    // Adds constant rotation to segment positions.
    m_startFraction = CONSTANT_ROTATION_DEGREES * progress + TAIL_DEGREES_OFFSET;
    m_endFraction = CONSTANT_ROTATION_DEGREES * progress;

    // Adds cycle specific rotation to segment positions.
    for (size_t cycleIndex = 0; cycleIndex < TOTAL_CYCLES; ++cycleIndex) {
        // While expanding.
        qreal fraction = getFractionInRange(playtime, DELAY_TO_EXPAND_IN_MS[cycleIndex], DURATION_TO_EXPAND_IN_MS);
        m_endFraction += m_curve.valueForProgress(fraction) * EXTRA_DEGREES_PER_CYCLE;

        // While collapsing.
        fraction = getFractionInRange(playtime, DELAY_TO_COLLAPSE_IN_MS[cycleIndex], DURATION_TO_COLLAPSE_IN_MS);
        m_startFraction += m_curve.valueForProgress(fraction) * EXTRA_DEGREES_PER_CYCLE;
    }

    // Closes the gap between head and tail for complete end.
    m_startFraction += (m_endFraction - m_startFraction) * m_completeEndProgress;

    m_startFraction /= 360.0;
    m_endFraction /= 360.0;

    emit startFractionChanged();
    emit endFractionChanged();
}

} // namespace caelestia::internal
