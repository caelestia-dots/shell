#include "lazygridview.hpp"

#include <algorithm>
#include <cmath>
#include <ranges>

namespace {

// Move-spring settle thresholds (px, px/s).
constexpr qreal k_settlePos = 0.5;
constexpr qreal k_settleVel = 0.5;

// Width is quantized so implicitHeight bound to width does not chase the spring and jitter
constexpr qreal k_widthStep = 0.2;

qreal quantizeWidth(qreal w) {
    return std::round(w / k_widthStep) * k_widthStep;
}

bool settled(qreal value, qreal velocity, qreal target) {
    return std::abs(value - target) < k_settlePos && std::abs(velocity) < k_settleVel;
}

// Closed-form spring step ported from androidx Compose SpringSimulation
void integrateSpring(qreal& value, qreal& velocity, qreal target, double naturalFreq, double dampingRatio, double dt) {
    const double adjustedDisplacement = value - target;
    const double dampingRatioSquared = dampingRatio * dampingRatio;
    const double r = -dampingRatio * naturalFreq;

    double displacement;
    double currentVelocity;

    if (dampingRatio > 1.0) {
        // Overdamped
        const double s = naturalFreq * std::sqrt(dampingRatioSquared - 1.0);
        const double gammaPlus = r + s;
        const double gammaMinus = r - s;

        const double coeffB = (gammaMinus * adjustedDisplacement - velocity) / (gammaMinus - gammaPlus);
        const double coeffA = adjustedDisplacement - coeffB;
        displacement = coeffA * std::exp(gammaMinus * dt) + coeffB * std::exp(gammaPlus * dt);
        currentVelocity =
            coeffA * gammaMinus * std::exp(gammaMinus * dt) + coeffB * gammaPlus * std::exp(gammaPlus * dt);
    } else if (qFuzzyCompare(dampingRatio, 1.0)) {
        // Critically damped
        const double coeffA = adjustedDisplacement;
        const double coeffB = velocity + naturalFreq * adjustedDisplacement;
        const double nFdT = -naturalFreq * dt;
        displacement = (coeffA + coeffB * dt) * std::exp(nFdT);
        currentVelocity = ((coeffA + coeffB * dt) * std::exp(nFdT) * (-naturalFreq)) + coeffB * std::exp(nFdT);
    } else {
        // Underdamped
        const double dampedFreq = naturalFreq * std::sqrt(1.0 - dampingRatioSquared);
        const double cosCoeff = adjustedDisplacement;
        const double sinCoeff = (1.0 / dampedFreq) * ((-r * adjustedDisplacement) + velocity);
        const double dFdT = dampedFreq * dt;
        displacement = std::exp(r * dt) * (cosCoeff * std::cos(dFdT) + sinCoeff * std::sin(dFdT));
        currentVelocity =
            displacement * r +
            (std::exp(r * dt) * (-dampedFreq * cosCoeff * std::sin(dFdT) + dampedFreq * sinCoeff * std::cos(dFdT)));
    }

    value = displacement + target;
    velocity = currentVelocity;
}

} // namespace

namespace caelestia::shell::components {

// --- LazyGridViewAttached ---

LazyGridViewAttached::LazyGridViewAttached(QObject* parent)
    : LazyViewAttached(parent) {}

qreal LazyGridViewAttached::rowHeight() const {
    return m_rowHeight;
}

void LazyGridViewAttached::setRowHeight(qreal height) {
    if (qFuzzyCompare(m_rowHeight + 1.0, height + 1.0))
        return;
    m_rowHeight = height;
    emit rowHeightChanged();
}

// --- LazyGridView ---

LazyGridView::LazyGridView(QQuickItem* parent)
    : LazyViewBase(parent) {}

LazyGridViewAttached* LazyGridView::qmlAttachedProperties(QObject* object) {
    return new LazyGridViewAttached(object);
}

LazyGridViewAttached* LazyGridView::gridAttachedFor(QQuickItem* item) {
    return qobject_cast<LazyGridViewAttached*>(qmlAttachedPropertiesObject<LazyGridView>(item, false));
}

LazyViewAttached* LazyGridView::attachedFor(QQuickItem* item) const {
    return gridAttachedFor(item);
}

LazyViewAttached* LazyGridView::attachedForCreate(QQuickItem* item) const {
    return qobject_cast<LazyGridViewAttached*>(qmlAttachedPropertiesObject<LazyGridView>(item, true));
}

// --- Layout properties ---

int LazyGridView::columns() const {
    return m_columns;
}

void LazyGridView::setColumns(int columns) {
    if (m_columns == columns)
        return;
    m_columns = columns;
    emit columnsChanged();
    updateResolvedColumns();
    polish();
}

qreal LazyGridView::cellWidth() const {
    return m_cellWidth;
}

void LazyGridView::setCellWidth(qreal width) {
    if (qFuzzyCompare(m_cellWidth, width))
        return;
    m_cellWidth = width;
    emit cellWidthChanged();
    updateResolvedColumns();
    polish();
}

qreal LazyGridView::rowSpacing() const {
    return m_rowSpacing;
}

void LazyGridView::setRowSpacing(qreal spacing) {
    if (qFuzzyCompare(m_rowSpacing, spacing))
        return;
    m_rowSpacing = spacing;
    emit rowSpacingChanged();
    polish();
}

qreal LazyGridView::columnSpacing() const {
    return m_columnSpacing;
}

void LazyGridView::setColumnSpacing(qreal spacing) {
    if (qFuzzyCompare(m_columnSpacing, spacing))
        return;
    m_columnSpacing = spacing;
    emit columnSpacingChanged();
    updateResolvedColumns();
    polish();
}

int LazyGridView::resolvedColumns() const {
    return m_resolvedColumns;
}

qreal LazyGridView::resolvedCellWidth() const {
    return m_resolvedCellWidth;
}

// --- Spring properties ---

qreal LazyGridView::stiffness() const {
    return m_stiffness;
}

void LazyGridView::setStiffness(qreal stiffness) {
    if (qFuzzyCompare(m_stiffness + 1.0, stiffness + 1.0))
        return;
    m_stiffness = stiffness;
    emit stiffnessChanged();
}

qreal LazyGridView::damping() const {
    return m_damping;
}

void LazyGridView::setDamping(qreal damping) {
    if (qFuzzyCompare(m_damping + 1.0, damping + 1.0))
        return;
    m_damping = damping;
    emit dampingChanged();
}

bool LazyGridView::animating() const {
    return m_animating;
}

void LazyGridView::setAnimating(bool animating) {
    if (m_animating == animating)
        return;
    m_animating = animating;
    emit animatingChanged();
}

// --- QQuickItem overrides ---

void LazyGridView::componentComplete() {
    updateResolvedColumns();
    LazyViewBase::componentComplete();
}

void LazyGridView::viewWidthChanged(qreal newWidth, qreal oldWidth) {
    Q_UNUSED(newWidth)

    // Held until the reflow's creates finish; skipped on the initial layout
    if (oldWidth > 0 && !m_resizeAnim) {
        m_prevColumns = m_resolvedColumns;
        m_prevCellWidth = m_resolvedCellWidth;
        m_prevRowTops = m_rowTops;
        m_prevRowHeights = m_rowHeights;
        m_resizeAnim = true;
    }
    updateResolvedColumns();
}

void LazyGridView::updatePolish() {
    m_createdThisPolish = 0;
    LazyViewBase::updatePolish();

    // Reflow done once nothing more is created
    if (m_resizeAnim && m_createdThisPolish == 0) {
        m_resizeAnim = false;
        m_prevRowTops.clear();
        m_prevRowHeights.clear();
    }
}

// --- Geometry ---

void LazyGridView::updateResolvedColumns() {
    int cols;
    qreal cw;

    if (m_columns > 0) {
        // Fixed column count; cells stretch to fill the available width.
        cols = m_columns;
        const qreal avail = width() - m_columnSpacing * (cols - 1);
        cw = std::max(0.0, avail / cols);
    } else if (m_cellWidth > 0) {
        // Derived here, not bound externally, so columns and cell width change in one pass
        cols = std::max(1, static_cast<int>(std::floor(width() / m_cellWidth)));
        cw = std::max(0.0, (width() - m_columnSpacing * (cols - 1)) / cols);
    } else {
        cols = 1;
        cw = width();
    }

    if (cols != m_resolvedColumns) {
        m_resolvedColumns = cols;
        emit resolvedColumnsChanged();
    }
    if (!qFuzzyCompare(m_resolvedCellWidth + 1.0, cw + 1.0)) {
        m_resolvedCellWidth = cw;
        emit resolvedCellWidthChanged();
    }
}

void LazyGridView::relayout() {
    const int cols = std::max(1, m_resolvedColumns);
    const int count = static_cast<int>(m_layout.size());
    const int rows = count == 0 ? 0 : (count + cols - 1) / cols;

    m_rowTops.resize(rows);
    m_rowHeights.resize(rows);

    qreal y = 0;
    bool hasRow = false;
    for (int r = 0; r < rows; ++r) {
        // Row height is the tallest cell in the row.
        qreal rowH = 0;
        for (int c = 0; c < cols; ++c) {
            const int idx = r * cols + c;
            if (idx >= count)
                break;
            rowH = std::max(rowH, layoutHeightAt(idx));
        }

        m_rowHeights[r] = rowH;
        if (rowH > 0) {
            if (hasRow)
                y += m_rowSpacing;
            hasRow = true;
            m_rowTops[r] = y;
            y += rowH;
        } else {
            m_rowTops[r] = y;
        }

        for (int c = 0; c < cols; ++c) {
            const int idx = r * cols + c;
            if (idx >= count)
                break;
            m_layout[idx].top = m_rowTops[r];
        }
    }

    setLayoutHeight(y);
    updateContentHeightSpring();
    publishRowHeights();
}

void LazyGridView::publishRowHeights() {
    const int rows = static_cast<int>(m_rowHeights.size());
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        if (!it->item)
            continue;
        const int r = rowOf(it.key());
        if (r < 0 || r >= rows)
            continue;
        auto* attached = gridAttachedFor(it->item);
        if (attached)
            attached->setRowHeight(m_rowHeights[r]);
    }
}

qreal LazyGridView::contentHeightTarget() const {
    return std::max(layoutHeight(), dyingExtent());
}

void LazyGridView::updateContentHeightSpring() {
    const qreal target = contentHeightTarget();

    // First value (or springs disabled) snaps; there is nothing to animate from.
    if (!m_contentHeightPlaced || m_stiffness <= 0) {
        m_contentHeightPlaced = true;
        m_contentHeightVel = 0;
        setContentHeight(target);
        return;
    }

    if (!qFuzzyCompare(contentHeight() + 1.0, target + 1.0))
        setAnimating(true);
}

int LazyGridView::spanCount() const {
    return static_cast<int>(m_rowTops.size());
}

qreal LazyGridView::spanTop(int span) const {
    return m_rowTops[span];
}

qreal LazyGridView::spanHeight(int span) const {
    return m_rowHeights[span];
}

std::pair<int, int> LazyGridView::itemsForSpans(int first, int last) const {
    const int cols = std::max(1, m_resolvedColumns);
    return { first * cols, std::min(static_cast<int>(m_layout.size()) - 1, (last + 1) * cols - 1) };
}

int LazyGridView::rowOf(int index) const {
    return index / std::max(1, m_resolvedColumns);
}

qreal LazyGridView::rowHeightOf(int index) const {
    const int r = rowOf(index);
    if (r >= 0 && r < static_cast<int>(m_rowHeights.size()) && m_rowHeights[r] > 0)
        return m_rowHeights[r];
    return 0;
}

qreal LazyGridView::columnStride() const {
    return m_resolvedCellWidth + m_columnSpacing;
}

qreal LazyGridView::itemX(int index) const {
    return (index % std::max(1, m_resolvedColumns)) * columnStride();
}

qreal LazyGridView::delegateWidth() const {
    return m_resolvedCellWidth;
}

qreal LazyGridView::visibleHeightOf(QQuickItem* item) const {
    return item ? item->height() : 0;
}

// Height target is the row height; rows derive from implicit height so setHeight cannot feed back
void LazyGridView::targetGeometry(int index, QQuickItem* item, qreal (&out)[GeomCount]) const {
    const qreal rowH = rowHeightOf(index);
    out[GeomX] = itemX(index);
    out[GeomY] = m_layout[index].top - m_contentY;
    out[GeomW] = m_resolvedCellWidth;
    out[GeomH] = rowH > 0 ? rowH : delegateHeight(item);
}

void LazyGridView::applyGeometry(QQuickItem* item, const qreal (&geom)[GeomCount]) {
    item->setX(geom[GeomX]);
    item->setY(geom[GeomY]);
    item->setWidth(quantizeWidth(geom[GeomW]));
    item->setHeight(geom[GeomH]);
}

// --- Transitions ---

void LazyGridView::snapAllSprings() {
    for (auto it = m_springs.begin(); it != m_springs.end(); ++it) {
        auto& spring = it.value();
        if (!spring.animating)
            continue;
        std::ranges::copy(spring.target, spring.val);
        std::ranges::fill(spring.vel, 0.0);
        spring.animating = false;
        applyGeometry(it.key(), spring.val);
    }
    m_contentHeightVel = 0;
    setContentHeight(contentHeightTarget());
    setAnimating(false);
}

void LazyGridView::step(qreal dt) {
    if (dt <= 0)
        return;
    // Clamp to avoid instability after a stall (e.g. a dropped frame).
    dt = std::min(dt, 1.0 / 30.0);

    // Springs disabled mid-flight: snap everything to its target.
    if (m_stiffness <= 0) {
        snapAllSprings();
        return;
    }

    const double naturalFreq = std::sqrt(static_cast<double>(m_stiffness));
    const double dampingRatio = std::max(0.0, static_cast<double>(m_damping));

    bool anyActive = false;
    for (auto it = m_springs.begin(); it != m_springs.end(); ++it) {
        auto& spring = it.value();
        if (!spring.animating)
            continue;

        bool allSettled = true;
        for (int i = 0; i < GeomCount; ++i) {
            integrateSpring(spring.val[i], spring.vel[i], spring.target[i], naturalFreq, dampingRatio, dt);
            if (!settled(spring.val[i], spring.vel[i], spring.target[i]))
                allSettled = false;
        }

        if (allSettled) {
            for (int i = 0; i < GeomCount; ++i) {
                spring.val[i] = spring.target[i];
                spring.vel[i] = 0;
            }
            spring.animating = false;
        } else {
            anyActive = true;
        }

        applyGeometry(it.key(), spring.val);
    }

    // Content height springs too so a bound implicitHeight animates
    const qreal target = contentHeightTarget();
    qreal value = contentHeight();
    if (m_contentHeightPlaced && !settled(value, m_contentHeightVel, target)) {
        integrateSpring(value, m_contentHeightVel, target, naturalFreq, dampingRatio, dt);
        if (settled(value, m_contentHeightVel, target)) {
            value = target;
            m_contentHeightVel = 0;
        } else {
            anyActive = true;
        }
        setContentHeight(value);
    }

    if (!anyActive)
        setAnimating(false);
}

// --- Delegates ---

void LazyGridView::placeCreatedDelegate(DelegateEntry& entry) {
    const int index = entry.modelIndex;
    auto* item = entry.item;

    SpringState spring;
    qreal actual[GeomCount];
    targetGeometry(index, item, actual);

    // Resize-created items spring in from their pre-resize slot
    bool fromVirtual = false;
    if (m_resizeAnim && m_stiffness > 0 && m_prevColumns > 0) {
        const int prow = index / m_prevColumns;
        const int pcol = index % m_prevColumns;
        const qreal virt[GeomCount] = {
            pcol * (m_prevCellWidth + m_columnSpacing),
            (prow < m_prevRowTops.size() ? m_prevRowTops[prow] : prow * (effectiveEstimatedHeight() + m_rowSpacing)) -
                m_contentY,
            m_prevCellWidth > 0 ? m_prevCellWidth : actual[GeomW],
            (prow < m_prevRowHeights.size() && m_prevRowHeights[prow] > 0) ? m_prevRowHeights[prow] : actual[GeomH],
        };

        for (int i = 0; i < GeomCount; ++i) {
            if (!qFuzzyCompare(virt[i] + 1.0, actual[i] + 1.0)) {
                fromVirtual = true;
                break;
            }
        }

        if (fromVirtual) {
            std::ranges::copy(virt, spring.val);
            spring.animateIn = true;
        }
    }

    if (!fromVirtual)
        std::ranges::copy(actual, spring.val);

    applyGeometry(item, spring.val);
    m_springs.insert(item, spring);
    ++m_createdThisPolish;
}

void LazyGridView::positionDelegate(DelegateEntry& entry) {
    auto* item = entry.item;
    const int index = entry.modelIndex;
    if (!item || index < 0 || index >= static_cast<int>(m_layout.size()))
        return;

    const auto springIt = m_springs.find(item);
    if (springIt == m_springs.end())
        return;
    auto& spring = springIt.value();

    qreal targets[GeomCount];
    targetGeometry(index, item, targets);

    // val already holds the pre-resize slot; just retarget
    if (!spring.placed && spring.animateIn && m_stiffness > 0) {
        std::ranges::copy(targets, spring.target);
        std::ranges::fill(spring.vel, 0.0);
        spring.animating = true;
        spring.animateIn = false;
        spring.placed = true;
        setAnimating(true);
        return;
    }

    // First placement (or springs disabled) snaps into position.
    if (m_stiffness <= 0 || !spring.placed) {
        spring.animating = false;
        std::ranges::copy(targets, spring.val);
        std::ranges::copy(targets, spring.target);
        std::ranges::fill(spring.vel, 0.0);
        applyGeometry(item, targets);
        spring.placed = true;
        return;
    }

    // At rest at this target; skip so scrolling polishes do not retrigger
    bool targetChanged = false;
    for (int i = 0; i < GeomCount; ++i) {
        if (!qFuzzyCompare(spring.target[i] + 1.0, targets[i] + 1.0)) {
            targetChanged = true;
            break;
        }
    }
    if (!spring.animating && !targetChanged)
        return;

    if (!spring.animating) {
        // Seed the springs from the item's current geometry.
        spring.val[GeomX] = item->x();
        spring.val[GeomY] = item->y();
        spring.val[GeomW] = item->width();
        spring.val[GeomH] = item->height();
        std::ranges::fill(spring.vel, 0.0);
        spring.animating = true;
    }
    std::ranges::copy(targets, spring.target);
    setAnimating(true);
}

// Stop the move spring so the item holds position while animating out
void LazyGridView::delegateRemoving(DelegateEntry& entry) {
    m_springs.remove(entry.item);
}

void LazyGridView::destroyDelegate(DelegateEntry& entry) {
    m_springs.remove(entry.item);
    LazyViewBase::destroyDelegate(entry);
}

void LazyGridView::resetContent() {
    LazyViewBase::resetContent();

    m_springs.clear();
    m_rowTops.clear();
    m_rowHeights.clear();
    m_resizeAnim = false;
    m_prevRowTops.clear();
    m_prevRowHeights.clear();

    // Snap rather than animate from torn-down content
    m_contentHeightPlaced = false;
    m_contentHeightVel = 0;

    relayout();
}

} // namespace caelestia::shell::components
