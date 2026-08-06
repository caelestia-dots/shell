#include "lazygridview.hpp"

#include <algorithm>
#include <cmath>
#include <qpoint.h>
#include <qpropertyanimation.h>
#include <qqmlcontext.h>
#include <qset.h>
#include <qtimer.h>

namespace {

constexpr int ASYNC_BATCH_CREATE = 4;
constexpr int ASYNC_BATCH_DESTROY = 8;
constexpr qreal DEFAULT_ROW_HEIGHT = 100;

// Move-spring settle thresholds (px, px/s).
constexpr qreal SETTLE_POS = 0.5;
constexpr qreal SETTLE_VEL = 0.5;

// The width applied to delegates is quantized to this step to prevent jitter.
constexpr qreal WIDTH_STEP = 0.2;

qreal quantizeWidth(qreal w) {
    return std::round(w / WIDTH_STEP) * WIDTH_STEP;
}

// Analytical spring step, ported from androidx Compose SpringSimulation
// (updateValues): closed-form solution parameterised by natural frequency
// (sqrt(stiffness)) and damping ratio. Updates value/velocity in place.
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

namespace caelestia::components {

// --- LazyGridViewAttached ---

LazyGridViewAttached::LazyGridViewAttached(QObject* parent)
    : QObject(parent) {}

qreal LazyGridViewAttached::preferredHeight() const {
    return m_preferredHeight;
}

void LazyGridViewAttached::setPreferredHeight(qreal height) {
    if (qFuzzyCompare(m_preferredHeight + 1.0, height + 1.0))
        return;
    m_preferredHeight = height;
    emit preferredHeightChanged();
}

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
    : QQuickItem(parent) {
    setFlag(ItemHasContents, false);
}

LazyGridViewAttached* LazyGridView::qmlAttachedProperties(QObject* object) {
    return new LazyGridViewAttached(object);
}

LazyGridView::~LazyGridView() {
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
}

// --- Model & Delegate ---

QAbstractItemModel* LazyGridView::model() const {
    return m_model;
}

void LazyGridView::setModel(QAbstractItemModel* model) {
    if (m_model == model)
        return;

    if (m_model)
        disconnectModel();

    m_model = model;

    if (m_model)
        connectModel();

    resetContent();
    emit modelChanged();
}

QQmlComponent* LazyGridView::delegate() const {
    return m_delegate;
}

void LazyGridView::setDelegate(QQmlComponent* delegate) {
    if (m_delegate == delegate)
        return;

    m_delegate = delegate;
    resetContent();
    emit delegateChanged();
}

// --- Layout ---

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

qreal LazyGridView::estimatedRowHeight() const {
    return m_estimatedRowHeight;
}

void LazyGridView::setEstimatedRowHeight(qreal height) {
    if (qFuzzyCompare(m_estimatedRowHeight, height))
        return;
    m_estimatedRowHeight = height;
    emit estimatedRowHeightChanged();
    polish();
}

// --- Resolved layout ---

int LazyGridView::resolvedColumns() const {
    return m_resolvedColumns;
}

qreal LazyGridView::resolvedCellWidth() const {
    return m_resolvedCellWidth;
}

qreal LazyGridView::contentHeight() const {
    return m_contentHeight;
}

qreal LazyGridView::animatedContentHeight() const {
    return m_animatedContentHeight;
}

qreal LazyGridView::contentY() const {
    return m_contentY;
}

void LazyGridView::setContentY(qreal contentY) {
    if (qFuzzyCompare(m_contentY, contentY))
        return;
    m_contentY = contentY;
    emit contentYChanged();
    polish();
}

// --- Viewport ---

QRectF LazyGridView::viewport() const {
    return m_viewport;
}

void LazyGridView::setViewport(const QRectF& viewport) {
    if (m_viewport == viewport)
        return;
    m_viewport = viewport;
    emit viewportChanged();
    if (m_useCustomViewport)
        polish();
}

bool LazyGridView::useCustomViewport() const {
    return m_useCustomViewport;
}

void LazyGridView::setUseCustomViewport(bool use) {
    if (m_useCustomViewport == use)
        return;
    m_useCustomViewport = use;
    emit useCustomViewportChanged();
    polish();
}

qreal LazyGridView::cacheBuffer() const {
    return m_cacheBuffer;
}

void LazyGridView::setCacheBuffer(qreal buffer) {
    if (qFuzzyCompare(m_cacheBuffer, buffer))
        return;
    m_cacheBuffer = buffer;
    emit cacheBufferChanged();
    polish();
}

// --- Async ---

bool LazyGridView::asynchronous() const {
    return m_asynchronous;
}

void LazyGridView::setAsynchronous(bool async) {
    if (m_asynchronous == async)
        return;
    m_asynchronous = async;
    emit asynchronousChanged();
}

// --- Transitions ---

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

int LazyGridView::enterDuration() const {
    return m_enterDuration;
}

void LazyGridView::setEnterDuration(int duration) {
    if (m_enterDuration == duration)
        return;
    m_enterDuration = duration;
    emit enterDurationChanged();
}

int LazyGridView::removeDuration() const {
    return m_removeDuration;
}

void LazyGridView::setRemoveDuration(int duration) {
    if (m_removeDuration == duration)
        return;
    m_removeDuration = duration;
    emit removeDurationChanged();
}

qreal LazyGridView::enterScale() const {
    return m_enterScale;
}

void LazyGridView::setEnterScale(qreal scale) {
    if (qFuzzyCompare(m_enterScale, scale))
        return;
    m_enterScale = scale;
    emit enterScaleChanged();
}

qreal LazyGridView::exitScale() const {
    return m_exitScale;
}

void LazyGridView::setExitScale(qreal scale) {
    if (qFuzzyCompare(m_exitScale, scale))
        return;
    m_exitScale = scale;
    emit exitScaleChanged();
}

QEasingCurve LazyGridView::easing() const {
    return m_easing;
}

void LazyGridView::setEasing(const QEasingCurve& easing) {
    if (m_easing == easing)
        return;
    m_easing = easing;
    emit easingChanged();
}

// --- Deferral ---

int LazyGridView::readyDelay() const {
    return m_readyDelay;
}

void LazyGridView::setReadyDelay(int delay) {
    if (m_readyDelay == delay)
        return;
    m_readyDelay = delay;
    emit readyDelayChanged();
}

// --- State ---

int LazyGridView::count() const {
    return static_cast<int>(m_layout.size());
}

// --- Sizing helpers ---

qreal LazyGridView::effectiveEstimatedHeight() const {
    if (m_estimatedRowHeight >= 0)
        return m_estimatedRowHeight;
    if (m_knownHeightCount > 0)
        return m_knownHeightSum / m_knownHeightCount;
    return DEFAULT_ROW_HEIGHT;
}

qreal LazyGridView::delegateHeight(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = qobject_cast<LazyGridViewAttached*>(qmlAttachedPropertiesObject<LazyGridView>(item, false));
    if (attached && attached->preferredHeight() >= 0)
        return attached->preferredHeight();

    return item->implicitHeight();
}

void LazyGridView::trackHeight(qreal height) {
    m_knownHeightSum += height;
    ++m_knownHeightCount;
}

void LazyGridView::untrackHeight(qreal height) {
    m_knownHeightSum -= height;
    --m_knownHeightCount;
}

void LazyGridView::applyMeasuredHeight(int index, qreal height) {
    if (index < 0 || index >= static_cast<int>(m_layout.size()))
        return;
    if (m_layout[index].heightKnown && qFuzzyCompare(m_layout[index].height + 1.0, height + 1.0))
        return;

    if (m_layout[index].heightKnown)
        untrackHeight(m_layout[index].height);
    m_layout[index].height = height;
    m_layout[index].heightKnown = true;
    trackHeight(height);

    if (!m_relayoutPending) {
        m_relayoutPending = true;
        QTimer::singleShot(0, this, [this] {
            m_relayoutPending = false;
            relayout();
            polish();
        });
    }
}

// --- QQuickItem overrides ---

void LazyGridView::componentComplete() {
    QQuickItem::componentComplete();
    m_componentComplete = true;
    updateResolvedColumns();
    resetContent();
}

void LazyGridView::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (!m_componentComplete)
        return;

    if (!qFuzzyCompare(newGeometry.width(), oldGeometry.width())) {
        // Snapshot the layout from before this resize so items created by the
        // reflow can spring in from their pre-resize slot. Captured once and
        // held until the reflow's creates finish (see updatePolish). Skipped on
        // the initial layout (oldGeometry has no real width), so items appear at
        // their target instead of reflowing in.
        if (oldGeometry.width() > 0 && !m_resizeAnim) {
            m_prevColumns = m_resolvedColumns;
            m_prevCellWidth = m_resolvedCellWidth;
            m_prevRowTops = m_rowTops;
            m_prevRowHeights = m_rowHeights;
            m_resizeAnim = true;
        }
        updateResolvedColumns();
    }

    polish();
}

void LazyGridView::updatePolish() {
    if (!m_componentComplete || !m_model || !m_delegate)
        return;

    // Flush pending inserts; make items visible and start their enter
    // animation. When readyDelay > 0 the appearance is deferred so delegates
    // can lay out (and report height) before animating in.
    for (auto& entry : m_delegates) {
        if (!entry.pendingInsert || !entry.item)
            continue;

        if (m_readyDelay > 0) {
            if (!entry.readyDelayStarted) {
                entry.readyDelayStarted = true;
                auto* item = entry.item;
                QTimer::singleShot(m_readyDelay, this, [this, item] {
                    auto indexIt = m_itemToIndex.find(item);
                    if (indexIt == m_itemToIndex.end())
                        return;
                    const int idx = indexIt.value();
                    auto it = m_delegates.find(idx);
                    if (it == m_delegates.end() || it->item != item || !it->pendingInsert)
                        return;

                    it->pendingInsert = false;
                    it->readyDelayStarted = false;

                    if (it->isEnter)
                        startEnterAnimation(item);
                    else
                        item->setVisible(true);
                    it->isEnter = false;

                    positionItem(*it);
                    polish();
                });
            }
            continue;
        }

        entry.pendingInsert = false;
        if (entry.isEnter)
            startEnterAnimation(entry.item);
        else
            entry.item->setVisible(true);
        entry.isEnter = false;
    }

    relayout();
    syncDelegates();

    // Clear isNew markers; the enter animation only plays for items created
    // during the same polish cycle as their model insertion, not for
    // delegates created later when scrolling cells into the viewport.
    for (auto& record : m_layout)
        record.isNew = false;

    // Position delegates; the view springs geometry changes itself
    // (see positionItem / step).
    for (auto& entry : m_delegates) {
        if (!entry.item || entry.pendingRemoval || entry.pendingInsert)
            continue;
        positionItem(entry);
    }

    // The resize reflow is done once no more items need creating; drop the
    // pre-resize snapshot so later viewport changes place items at their target.
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
        // cellWidth is a target/minimum; the column count is derived from the
        // view's own width and cells stretch to fill the row. Deriving columns
        // here (rather than from an external binding) keeps the column count and
        // cell width in sync within a single layout pass, so a boundary-crossing
        // resize animates cleanly instead of being snapped by a trailing cycle.
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
    const int rows = m_layout.isEmpty() ? 0 : (static_cast<int>(m_layout.size()) + cols - 1) / cols;

    m_rowTops.resize(rows);
    m_rowHeights.resize(rows);

    const qreal estimate = effectiveEstimatedHeight();

    qreal y = 0;
    bool hasRow = false;
    for (int r = 0; r < rows; ++r) {
        // Row height is the tallest cell in the row.
        qreal rowH = 0;
        for (int c = 0; c < cols; ++c) {
            const int idx = r * cols + c;
            if (idx >= static_cast<int>(m_layout.size()))
                break;
            const qreal h = m_layout[idx].heightKnown ? m_layout[idx].height : estimate;
            rowH = std::max(rowH, h);
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
    }

    if (!qFuzzyCompare(m_contentHeight + 1.0, y + 1.0)) {
        m_contentHeight = y;
        emit contentHeightChanged();
        updateAnimatedContentHeight();
    }

    // Publish each live delegate's row height (LazyGridView.rowHeight). The view
    // stretches items to this height itself (see positionItem); the property is
    // exposed so delegates can read the row height they were sized to.
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        if (!it->item)
            continue;
        const int r = rowOf(it.key());
        if (r < 0 || r >= rows)
            continue;
        auto* att = qobject_cast<LazyGridViewAttached*>(qmlAttachedPropertiesObject<LazyGridView>(it->item, false));
        if (att)
            att->setRowHeight(m_rowHeights[r]);
    }
}

void LazyGridView::updateAnimatedContentHeight() {
    // First value (or springs disabled) snaps; there is nothing to animate from.
    if (!m_animatedContentHeightPlaced || m_stiffness <= 0) {
        m_animatedContentHeightPlaced = true;
        m_animatedContentHeightVel = 0;
        if (!qFuzzyCompare(m_animatedContentHeight + 1.0, m_contentHeight + 1.0)) {
            m_animatedContentHeight = m_contentHeight;
            emit animatedContentHeightChanged();
        }
        return;
    }

    // Otherwise let step() spring toward the new target.
    if (!qFuzzyCompare(m_animatedContentHeight + 1.0, m_contentHeight + 1.0))
        setAnimating(true);
}

int LazyGridView::rowOf(int index) const {
    const int cols = std::max(1, m_resolvedColumns);
    return index / cols;
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
    const int cols = std::max(1, m_resolvedColumns);
    return (index % cols) * columnStride();
}

qreal LazyGridView::itemY(int index) const {
    const int r = rowOf(index);
    if (r >= 0 && r < static_cast<int>(m_rowTops.size()))
        return m_rowTops[r];
    return 0;
}

QRectF LazyGridView::effectiveViewport() const {
    QRectF vp;
    if (m_useCustomViewport)
        vp = m_viewport;
    else
        vp = QRectF(0, m_contentY, width(), height());

    // During Flickable overshoot the viewport can extend entirely beyond the
    // content bounds, culling every delegate. Clamp so it always overlaps
    // [0, contentHeight]. Only needed for the built-in viewport.
    if (!m_useCustomViewport && m_contentHeight > 0) {
        const qreal top = std::min(vp.y(), m_contentHeight);
        const qreal bottom = std::max(vp.y() + vp.height(), 0.0);
        if (bottom > top)
            vp = QRectF(vp.x(), top, vp.width(), bottom - top);
    }

    vp.adjust(0, -m_cacheBuffer, 0, m_cacheBuffer);

    // Trim to [0, contentHeight]; nothing exists outside those bounds.
    if (m_contentHeight > 0) {
        const qreal top = std::max(vp.y(), 0.0);
        const qreal bottom = std::min(vp.y() + vp.height(), m_contentHeight);
        if (top < bottom)
            vp = QRectF(vp.x(), top, vp.width(), bottom - top);
        else
            return {};
    }

    return vp;
}

std::pair<int, int> LazyGridView::computeVisibleRange() const {
    const int cols = m_resolvedColumns;
    const int rows = static_cast<int>(m_rowTops.size());
    if (m_layout.isEmpty() || cols <= 0 || rows <= 0)
        return { -1, -1 };

    const auto vp = effectiveViewport();
    if (vp.isEmpty())
        return { -1, -1 };

    const qreal vpTop = vp.y();
    const qreal vpBottom = vp.y() + vp.height();

    // Binary search for the first visible row.
    int lo = 0;
    int hi = rows - 1;
    int firstRow = rows;
    while (lo <= hi) {
        const int mid = lo + (hi - lo) / 2;
        const qreal rowBottom = m_rowTops[mid] + m_rowHeights[mid];
        if (rowBottom >= vpTop) {
            firstRow = mid;
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }

    if (firstRow >= rows)
        return { -1, -1 };

    // Linear scan for the last visible row.
    int lastRow = firstRow;
    for (int r = firstRow; r < rows; ++r) {
        if (m_rowTops[r] > vpBottom)
            break;
        lastRow = r;
    }

    const int first = firstRow * cols;
    const int last = std::min(static_cast<int>(m_layout.size()) - 1, (lastRow + 1) * cols - 1);
    return { first, last };
}

// --- Transitions ---

void LazyGridView::step(qreal dt) {
    if (dt <= 0)
        return;
    // Clamp to avoid instability after a stall (e.g. a dropped frame).
    dt = std::min(dt, 1.0 / 30.0);

    const double naturalFreq = std::sqrt(std::max(0.0, static_cast<double>(m_stiffness)));
    const double dampingRatio = std::max(0.0, static_cast<double>(m_damping));

    bool anyActive = false;
    for (auto& entry : m_delegates) {
        if (!entry.animating || !entry.item)
            continue;

        // androidx analytical spring integration per channel.
        bool settled = true;
        for (int i = 0; i < GeomCount; ++i) {
            integrateSpring(
                entry.springVal[i], entry.springVel[i], entry.springTarget[i], naturalFreq, dampingRatio, dt);
            if (std::abs(entry.springVal[i] - entry.springTarget[i]) >= SETTLE_POS ||
                std::abs(entry.springVel[i]) >= SETTLE_VEL)
                settled = false;
        }

        if (settled) {
            for (int i = 0; i < GeomCount; ++i) {
                entry.springVal[i] = entry.springTarget[i];
                entry.springVel[i] = 0;
            }
            entry.animating = false;
        } else {
            anyActive = true;
        }

        entry.item->setX(entry.springVal[GeomX]);
        entry.item->setY(entry.springVal[GeomY]);
        entry.item->setWidth(quantizeWidth(entry.springVal[GeomW]));
        entry.item->setHeight(entry.springVal[GeomH]);
    }

    // Aggregate content height springs toward its measured target so a bound
    // implicitHeight can animate (retargeted in updateAnimatedContentHeight).
    if (m_animatedContentHeightPlaced && m_stiffness > 0 &&
        (std::abs(m_animatedContentHeight - m_contentHeight) >= SETTLE_POS ||
            std::abs(m_animatedContentHeightVel) >= SETTLE_VEL)) {
        integrateSpring(
            m_animatedContentHeight, m_animatedContentHeightVel, m_contentHeight, naturalFreq, dampingRatio, dt);
        if (std::abs(m_animatedContentHeight - m_contentHeight) < SETTLE_POS &&
            std::abs(m_animatedContentHeightVel) < SETTLE_VEL) {
            m_animatedContentHeight = m_contentHeight;
            m_animatedContentHeightVel = 0;
        } else {
            anyActive = true;
        }
        emit animatedContentHeightChanged();
    }

    if (!anyActive)
        setAnimating(false);
}

void LazyGridView::positionItem(DelegateEntry& entry) {
    auto* item = entry.item;
    const int index = entry.modelIndex;
    if (!item || index < 0 || index >= static_cast<int>(m_layout.size()))
        return;

    // Fill the row vertically: the height target is the row height (tallest
    // cell), not the item's own preferred height. Row heights derive from
    // delegateHeight (implicit/preferred), which setHeight doesn't affect, so
    // there is no feedback loop. Falls back to the item's height until the row
    // height is known.
    const qreal rowH = rowHeightOf(index);
    const qreal targets[GeomCount] = {
        itemX(index),
        itemY(index) - m_contentY,
        m_resolvedCellWidth,
        rowH > 0 ? rowH : delegateHeight(item),
    };

    // Resize-created items spring in from the pre-resize slot seeded at creation
    // (springVal already holds it); set the target and let step() animate.
    if (!entry.placed && entry.animateIn && m_stiffness > 0) {
        for (int i = 0; i < GeomCount; ++i) {
            entry.springTarget[i] = targets[i];
            entry.springVel[i] = 0;
        }
        entry.animating = true;
        entry.animateIn = false;
        entry.placed = true;
        setAnimating(true);
        return;
    }

    // First placement (or springs disabled) snaps into position.
    if (m_stiffness <= 0 || !entry.placed) {
        entry.animating = false;
        for (int i = 0; i < GeomCount; ++i) {
            entry.springVal[i] = targets[i];
            entry.springVel[i] = 0;
            entry.springTarget[i] = targets[i];
        }
        item->setX(targets[GeomX]);
        item->setY(targets[GeomY]);
        item->setWidth(quantizeWidth(targets[GeomW]));
        item->setHeight(targets[GeomH]);
        entry.placed = true;
        return;
    }

    // Nothing to do if already at rest at this target; avoids re-triggering the
    // spring on every polish (e.g. while scrolling).
    bool targetChanged = false;
    for (int i = 0; i < GeomCount; ++i) {
        if (!qFuzzyCompare(entry.springTarget[i] + 1.0, targets[i] + 1.0)) {
            targetChanged = true;
            break;
        }
    }
    if (!entry.animating && !targetChanged)
        return;

    if (!entry.animating) {
        // Seed the springs from the item's current geometry.
        entry.springVal[GeomX] = item->x();
        entry.springVal[GeomY] = item->y();
        entry.springVal[GeomW] = item->width();
        entry.springVal[GeomH] = item->height();
        for (int i = 0; i < GeomCount; ++i)
            entry.springVel[i] = 0;
        entry.animating = true;
    }
    for (int i = 0; i < GeomCount; ++i)
        entry.springTarget[i] = targets[i];
    setAnimating(true);

    entry.placed = true;
}

void LazyGridView::startEnterAnimation(QQuickItem* item) {
    item->setVisible(true);

    if (m_enterDuration <= 0)
        return;

    auto* op = new QPropertyAnimation(item, "opacity", item);
    op->setDuration(m_enterDuration);
    op->setEasingCurve(m_easing);
    op->setStartValue(0.0);
    op->setEndValue(1.0);
    item->setOpacity(0.0);
    op->start(QAbstractAnimation::DeleteWhenStopped);

    if (!qFuzzyCompare(m_enterScale, 1.0)) {
        auto* sc = new QPropertyAnimation(item, "scale", item);
        sc->setDuration(m_enterDuration);
        sc->setEasingCurve(m_easing);
        sc->setStartValue(m_enterScale);
        sc->setEndValue(1.0);
        item->setScale(m_enterScale);
        sc->start(QAbstractAnimation::DeleteWhenStopped);
    }
}

void LazyGridView::startExitAnimation(QQuickItem* item) {
    if (m_removeDuration <= 0)
        return;

    auto* op = new QPropertyAnimation(item, "opacity", item);
    op->setDuration(m_removeDuration);
    op->setEasingCurve(m_easing);
    op->setStartValue(item->opacity());
    op->setEndValue(0.0);
    op->start(QAbstractAnimation::DeleteWhenStopped);

    if (!qFuzzyCompare(m_exitScale, 1.0)) {
        auto* sc = new QPropertyAnimation(item, "scale", item);
        sc->setDuration(m_removeDuration);
        sc->setEasingCurve(m_easing);
        sc->setStartValue(item->scale());
        sc->setEndValue(m_exitScale);
        sc->start(QAbstractAnimation::DeleteWhenStopped);
    }
}

// --- Delegate lifecycle ---

void LazyGridView::syncDelegates() {
    const auto [first, last] = computeVisibleRange();

    QSet<int> visibleIndices;
    if (first >= 0) {
        for (int i = first; i <= last; ++i)
            visibleIndices.insert(i);
    }

    // Collect delegates to destroy; only if outside the buffered viewport.
    const auto vp = effectiveViewport();
    QList<int> toRemove;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        if (visibleIndices.contains(it.key()))
            continue;
        if (!it->item || vp.isEmpty()) {
            toRemove.append(it.key());
            continue;
        }
        // item->y() is in view coordinates (content position minus contentY);
        // shift back to content coordinates to match the viewport.
        const qreal itemTop = it->item->y() + m_contentY;
        const qreal itemBottom = itemTop + delegateHeight(it->item);
        if (itemBottom < vp.top() || itemTop > vp.bottom())
            toRemove.append(it.key());
    }

    // Batch destroy
    const int destroyBudget = m_asynchronous ? ASYNC_BATCH_DESTROY : static_cast<int>(toRemove.size());
    QVector<DelegateEntry> removedEntries;
    removedEntries.reserve(std::min(destroyBudget, static_cast<int>(toRemove.size())));
    int destroyed = 0;
    for (int idx : toRemove) {
        if (destroyed >= destroyBudget)
            break;
        auto entry = m_delegates.take(idx);
        if (entry.item)
            m_itemToIndex.remove(entry.item);
        removedEntries.append(std::move(entry));
        ++destroyed;
    }
    for (auto& entry : removedEntries)
        destroyDelegate(entry);

    // Collect indices to create
    QList<int> toCreate;
    if (first >= 0) {
        for (int i = first; i <= last; ++i) {
            if (!m_delegates.contains(i))
                toCreate.append(i);
        }
    }

    // Batch create
    const int createBudget = m_asynchronous ? ASYNC_BATCH_CREATE : static_cast<int>(toCreate.size());
    int created = 0;
    for (int i : toCreate) {
        if (created >= createBudget)
            break;

        auto entry = createDelegate(i);
        if (entry.item) {
            entry.pendingInsert = true;

            // Actual (post-layout) geometry. Height fills the row (see
            // positionItem); falls back to the item's height until known.
            const qreal aX = itemX(i);
            const qreal aY = itemY(i) - m_contentY;
            const qreal aW = m_resolvedCellWidth;
            const qreal rowH = rowHeightOf(i);
            const qreal aH = rowH > 0 ? rowH : delegateHeight(entry.item);

            // When a resize creates this item, spring it in from its slot in the
            // pre-resize layout. Otherwise (a plain viewport change) place it at
            // its target. Model inserts keep their own enter animation.
            bool fromVirtual = false;
            if (m_resizeAnim && m_stiffness > 0 && !entry.isEnter && m_prevColumns > 0) {
                const int pcols = m_prevColumns;
                const int prow = i / pcols;
                const int pcol = i % pcols;
                const qreal vX = pcol * (m_prevCellWidth + m_columnSpacing);
                const qreal vY = (prow < m_prevRowTops.size() ? m_prevRowTops[prow]
                                                              : prow * (effectiveEstimatedHeight() + m_rowSpacing)) -
                                 m_contentY;
                const qreal vW = m_prevCellWidth > 0 ? m_prevCellWidth : aW;
                const qreal vH =
                    (prow < m_prevRowHeights.size() && m_prevRowHeights[prow] > 0) ? m_prevRowHeights[prow] : aH;

                if (!qFuzzyCompare(vX + 1.0, aX + 1.0) || !qFuzzyCompare(vY + 1.0, aY + 1.0) ||
                    !qFuzzyCompare(vW + 1.0, aW + 1.0) || !qFuzzyCompare(vH + 1.0, aH + 1.0)) {
                    entry.springVal[GeomX] = vX;
                    entry.springVal[GeomY] = vY;
                    entry.springVal[GeomW] = vW;
                    entry.springVal[GeomH] = vH;
                    entry.animateIn = true;
                    fromVirtual = true;
                }
            }

            if (!fromVirtual) {
                entry.springVal[GeomX] = aX;
                entry.springVal[GeomY] = aY;
                entry.springVal[GeomW] = aW;
                entry.springVal[GeomH] = aH;
            }

            entry.item->setX(entry.springVal[GeomX]);
            entry.item->setY(entry.springVal[GeomY]);
            entry.item->setWidth(quantizeWidth(entry.springVal[GeomW]));
            entry.item->setHeight(entry.springVal[GeomH]);

            m_itemToIndex.insert(entry.item, i);
            m_delegates.insert(i, std::move(entry));
            ++created;
        }
    }

    m_createdThisPolish = created;

    // Pending inserts must become visible next frame; async mode may also
    // have create/destroy work still queued.
    if (created > 0 || (m_asynchronous && (destroyed < static_cast<int>(toRemove.size()) ||
                                              created < static_cast<int>(toCreate.size()))))
        polish();
}

LazyGridView::DelegateEntry LazyGridView::createDelegate(int modelIndex) {
    DelegateEntry entry;
    entry.modelIndex = modelIndex;

    if (!m_delegate || !m_model)
        return entry;

    const auto roleNames = m_model->roleNames();

    // Use the delegate component's creation context so bound components
    // (pragma ComponentBehavior: Bound) are accepted.
    auto* compContext = m_delegate->creationContext();
    if (!compContext)
        compContext = qmlContext(this);
    if (!compContext)
        return entry;

    auto* obj = m_delegate->beginCreate(compContext);
    entry.item = qobject_cast<QQuickItem*>(obj);

    if (!entry.item) {
        if (obj)
            m_delegate->completeCreate();
        delete obj;
        return entry;
    }

    // Build initial properties from model data
    const auto index = m_model->index(modelIndex, 0);
    QVariantMap initialProps;
    bool hasModelData = false;

    for (auto it = roleNames.constBegin(); it != roleNames.constEnd(); ++it) {
        const auto name = QString::fromUtf8(it.value());
        initialProps.insert(name, m_model->data(index, it.key()));
        if (name == QStringLiteral("modelData"))
            hasModelData = true;
    }
    initialProps.insert(QStringLiteral("index"), modelIndex);

    if (!hasModelData) {
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        initialProps.insert(QStringLiteral("modelData"), m_model->data(index, role));
    }

    m_delegate->setInitialProperties(entry.item, initialProps);

    entry.item->setParentItem(this);
    entry.item->setWidth(m_resolvedCellWidth);

    // Genuinely new model items animate in; viewport scroll-ins appear instantly.
    entry.isEnter = modelIndex < static_cast<int>(m_layout.size()) && m_layout[modelIndex].isNew;

    m_delegate->completeCreate();

    // Keep hidden; flushed on the next frame in updatePolish.
    entry.item->setVisible(false);

    // Measure the initial height, then keep tracking it.
    applyMeasuredHeight(modelIndex, delegateHeight(entry.item));

    auto onHeightChanged = [this, item = entry.item] {
        auto indexIt = m_itemToIndex.find(item);
        if (indexIt == m_itemToIndex.end())
            return;
        const int idx = indexIt.value();
        auto delegateIt = m_delegates.find(idx);
        if (delegateIt == m_delegates.end() || delegateIt->item != item)
            return;
        applyMeasuredHeight(idx, delegateHeight(item));
    };

    connect(entry.item, &QQuickItem::implicitHeightChanged, this, onHeightChanged);

    auto* attached = qobject_cast<LazyGridViewAttached*>(qmlAttachedPropertiesObject<LazyGridView>(entry.item, false));
    if (attached)
        connect(attached, &LazyGridViewAttached::preferredHeightChanged, this, onHeightChanged);

    return entry;
}

void LazyGridView::destroyDelegate(DelegateEntry& entry) {
    if (entry.item) {
        entry.item->setParentItem(nullptr);
        entry.item->setVisible(false);
        entry.item->deleteLater();
        entry.item = nullptr;
    }
}

void LazyGridView::updateDelegateData(DelegateEntry& entry) {
    if (!m_model || !entry.item)
        return;

    const auto roleNames = m_model->roleNames();
    const auto index = m_model->index(entry.modelIndex, 0);
    bool hasModelData = false;

    for (auto it = roleNames.constBegin(); it != roleNames.constEnd(); ++it) {
        const auto name = QString::fromUtf8(it.value());
        entry.item->setProperty(name.toUtf8().constData(), m_model->data(index, it.key()));
        if (name == QStringLiteral("modelData"))
            hasModelData = true;
    }

    entry.item->setProperty("index", entry.modelIndex);

    if (!hasModelData) {
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        entry.item->setProperty("modelData", m_model->data(index, role));
    }
}

// --- Model connection ---

void LazyGridView::connectModel() {
    if (!m_model)
        return;

    m_modelConnections = {
        connect(m_model, &QAbstractItemModel::rowsInserted, this, &LazyGridView::onRowsInserted),
        connect(m_model, &QAbstractItemModel::rowsAboutToBeRemoved, this, &LazyGridView::onRowsAboutToBeRemoved),
        connect(m_model, &QAbstractItemModel::rowsRemoved, this, &LazyGridView::onRowsRemoved),
        connect(m_model, &QAbstractItemModel::rowsMoved, this, &LazyGridView::onRowsMoved),
        connect(m_model, &QAbstractItemModel::dataChanged, this, &LazyGridView::onDataChanged),
        connect(m_model, &QAbstractItemModel::modelReset, this, &LazyGridView::onModelReset),
        connect(m_model, &QAbstractItemModel::layoutChanged, this,
            [this] {
                for (auto& entry : m_delegates)
                    updateDelegateData(entry);
                polish();
            }),
        connect(m_model, &QObject::destroyed, this,
            [this] {
                m_model = nullptr;
                resetContent();
                emit modelChanged();
            }),
    };
}

void LazyGridView::disconnectModel() {
    for (auto& conn : m_modelConnections)
        disconnect(conn);
    m_modelConnections.clear();
}

void LazyGridView::resetContent() {
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    m_delegates.clear();
    m_itemToIndex.clear();

    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
    m_dyingDelegates.clear();

    m_knownHeightSum = 0;
    m_knownHeightCount = 0;

    // Snap the content-height spring to the next layout rather than animating
    // from the torn-down content.
    m_animatedContentHeightPlaced = false;

    m_layout.clear();
    m_rowTops.clear();
    m_rowHeights.clear();

    if (m_model && m_componentComplete) {
        const int rows = m_model->rowCount();
        m_layout.resize(rows);
        emit countChanged();
    }

    relayout();
    polish();
}

void LazyGridView::onRowsInserted(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int insertCount = last - first + 1;
    m_layout.insert(first, insertCount, ItemRecord{ 0, false, true });

    // Shift existing delegate indices at or after the insertion point.
    QHash<int, DelegateEntry> shifted;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        int newIdx = it.key() >= first ? it.key() + insertCount : it.key();
        auto entry = std::move(it.value());
        entry.modelIndex = newIdx;
        if (entry.item) {
            entry.item->setProperty("index", newIdx);
            m_itemToIndex[entry.item] = newIdx;
        }
        shifted.insert(newIdx, std::move(entry));
    }
    m_delegates = std::move(shifted);

    emit countChanged();
    polish();
}

void LazyGridView::onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    for (int i = first; i <= last; ++i) {
        if (!m_delegates.contains(i))
            continue;

        auto entry = m_delegates.take(i);
        if (entry.item)
            m_itemToIndex.remove(entry.item);
        entry.pendingRemoval = true;

        // Never made visible; skip the exit animation.
        if (entry.pendingInsert) {
            destroyDelegate(entry);
            continue;
        }

        if (m_removeDuration > 0 && entry.item) {
            // Stop the move spring so the item holds position while fading out.
            entry.animating = false;

            startExitAnimation(entry.item);

            auto* item = entry.item;
            QTimer::singleShot(m_removeDuration, this, [this, item] {
                for (auto it = m_dyingDelegates.begin(); it != m_dyingDelegates.end(); ++it) {
                    if (it->item == item) {
                        destroyDelegate(*it);
                        m_dyingDelegates.erase(it);
                        return;
                    }
                }
            });
            m_dyingDelegates.append(std::move(entry));
        } else {
            destroyDelegate(entry);
        }
    }
}

void LazyGridView::onRowsRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int removeCount = last - first + 1;

    // Untrack known heights being removed.
    for (int i = first; i <= last; ++i) {
        if (m_layout[i].heightKnown)
            untrackHeight(m_layout[i].height);
    }

    m_layout.remove(first, removeCount);

    // Shift remaining delegate indices down.
    QHash<int, DelegateEntry> shifted;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        int newIdx = it.key() > last ? it.key() - removeCount : it.key();
        auto entry = std::move(it.value());
        entry.modelIndex = newIdx;
        if (entry.item) {
            entry.item->setProperty("index", newIdx);
            m_itemToIndex[entry.item] = newIdx;
        }
        shifted.insert(newIdx, std::move(entry));
    }
    m_delegates = std::move(shifted);

    emit countChanged();
    polish();
}

void LazyGridView::onRowsMoved(const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row) {
    if (parent.isValid() || destination.isValid())
        return;

    const int count = end - start + 1;
    const int dest = row > start ? row - count : row;

    // Reorder layout records.
    QVector<ItemRecord> moved;
    moved.reserve(count);
    for (int i = start; i <= end; ++i)
        moved.append(m_layout[i]);
    m_layout.remove(start, count);
    for (int i = 0; i < count; ++i)
        m_layout.insert(dest + i, moved[i]);

    // Remap delegate indices to match the new model order.
    QHash<int, DelegateEntry> remapped;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        int oldIdx = it.key();
        int newIdx = oldIdx;

        if (oldIdx >= start && oldIdx <= end) {
            newIdx = dest + (oldIdx - start);
        } else {
            if (oldIdx > end)
                newIdx -= count;
            if (newIdx >= dest)
                newIdx += count;
        }

        auto entry = std::move(it.value());
        entry.modelIndex = newIdx;
        if (entry.item) {
            entry.item->setProperty("index", newIdx);
            m_itemToIndex[entry.item] = newIdx;
        }
        remapped.insert(newIdx, std::move(entry));
    }
    m_delegates = std::move(remapped);

    polish();
}

void LazyGridView::onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles) {
    Q_UNUSED(roles)

    if (topLeft.parent().isValid())
        return;

    for (int i = topLeft.row(); i <= bottomRight.row(); ++i) {
        if (m_delegates.contains(i))
            updateDelegateData(m_delegates[i]);
    }
}

void LazyGridView::onModelReset() {
    if (!m_model) {
        resetContent();
        return;
    }

    const int newRows = m_model->rowCount();
    const int oldRows = static_cast<int>(m_layout.size());

    // If the row count and per-item data are unchanged, refresh in place to
    // avoid tearing down every delegate.
    if (newRows == oldRows) {
        const auto roleNames = m_model->roleNames();
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        bool changed = false;

        for (auto it = m_delegates.constBegin(); it != m_delegates.constEnd(); ++it) {
            if (!it->item || it.key() >= newRows) {
                changed = true;
                break;
            }
            const auto newData = m_model->data(m_model->index(it.key(), 0), role);
            const auto oldData = it->item->property("modelData");
            if (newData != oldData) {
                changed = true;
                break;
            }
        }

        if (!changed) {
            for (auto& entry : m_delegates)
                updateDelegateData(entry);
            return;
        }
    }

    resetContent();
}

} // namespace caelestia::components
