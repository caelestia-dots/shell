#include "linearindicatormanager.hpp"

#include <qpoint.h>

namespace {

// See
// https://github.com/material-components/material-components-android/blob/master/lib/java/com/google/android/material/progressindicator/LinearIndeterminateDisjointAnimatorDelegate.java#L44-L46
constexpr int TOTAL_DURATION_IN_MS = 1800;
constexpr std::array DURATION_TO_MOVE_SEGMENT_ENDS = { 533, 567, 850, 750 };
constexpr std::array DELAY_TO_MOVE_SEGMENT_ENDS = { 1267, 1000, 333, 0 };

QEasingCurve curve(const QPointF& c1, const QPointF& c2) {
    QEasingCurve curve(QEasingCurve::BezierSpline);
    curve.addCubicBezierSegment(c1, c2, { 1.0, 1.0 });
    return curve;
}

qreal getFractionInRange(qreal playtime, int start, int duration) {
    const auto fraction = static_cast<qreal>(playtime - start) / duration;
    return std::clamp(fraction, 0.0, 1.0);
}

} // namespace

namespace caelestia::controls {

LinearIndicatorSegment::LinearIndicatorSegment(int gap, QObject* parent)
    : QObject(parent)
    , m_startFraction(0)
    , m_endFraction(0)
    , m_gapSize(gap) {}

qreal LinearIndicatorSegment::startFraction() const {
    return m_startFraction;
}

qreal LinearIndicatorSegment::endFraction() const {
    return m_endFraction;
}

int LinearIndicatorSegment::gapSize() const {
    return m_gapSize;
}

LinearIndicatorManager::LinearIndicatorManager(QObject* parent)
    : QObject(parent)
    , m_interpolators({
          curve({ 0.2, 0.0 }, { 0.8, 1.0 }),
          curve({ 0.4, 0.0 }, { 1.0, 1.0 }),
          curve({ 0.0, 0.0 }, { 0.65, 1.0 }),
          curve({ 0.1, 0.0 }, { 0.45, 1.0 }),
      })
    , m_progress(0)
    , m_completeEndProgress(0)
    , m_gap(4)
    , m_activeIndicators({
          new LinearIndicatorSegment(m_gap, this),
          new LinearIndicatorSegment(m_gap, this),
      }) {
    for (auto el : m_activeIndicators)
        QObject::connect(this, &LinearIndicatorManager::updated, el, &LinearIndicatorSegment::updated);
}

QList<LinearIndicatorSegment*> LinearIndicatorManager::activeIndicators() const {
    return { m_activeIndicators.cbegin(), m_activeIndicators.cend() };
}

qreal LinearIndicatorManager::progress() const {
    return m_progress;
}

qreal LinearIndicatorManager::completeEndProgress() const {
    return m_completeEndProgress;
}

int LinearIndicatorManager::gap() const {
    return m_gap;
}

void LinearIndicatorManager::setGap(int gap) {
    m_gap = gap;
    for (auto el : m_activeIndicators)
        el->m_gapSize = m_gap;
    update(m_progress);
}

int LinearIndicatorManager::duration() const {
    return TOTAL_DURATION_IN_MS;
}

int LinearIndicatorManager::completeEndDuration() const {
    return TOTAL_DURATION_IN_MS;
}

void LinearIndicatorManager::update(qreal progress) {
    const auto playtime = progress * TOTAL_DURATION_IN_MS;
    for (size_t i = 0; i < SEGMENTS; i++) {
        const auto di = i * 2;
        auto* const indicator = m_activeIndicators[i];

        auto fraction = getFractionInRange(playtime, DELAY_TO_MOVE_SEGMENT_ENDS[di], DURATION_TO_MOVE_SEGMENT_ENDS[di]);
        indicator->m_startFraction = std::clamp(m_interpolators[di].valueForProgress(fraction), 0.0, 1.0);

        fraction =
            getFractionInRange(playtime, DELAY_TO_MOVE_SEGMENT_ENDS[di + 1], DURATION_TO_MOVE_SEGMENT_ENDS[di + 1]);
        indicator->m_endFraction = std::clamp(m_interpolators[di + 1].valueForProgress(fraction), 0.0, 1.0);
    }

    m_progress = progress;
    emit updated();
}

void LinearIndicatorManager::updateCompleteEndProgress(qreal progress) {
    m_completeEndProgress = progress;
    update(m_progress);
}

} // namespace caelestia::controls
