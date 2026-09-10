#include "lazylistview.hpp"

#include <qqmlcontext.h>
#include <qtimer.h>

#include <algorithm>

namespace {

constexpr int k_asyncBatchCreate = 2;
constexpr int k_asyncBatchDestroy = 4;
constexpr qreal k_fallbackHeight = 40;

// Clip a rect vertically to [top, bottom], empty if there is no overlap
QRectF clipVertical(const QRectF& rect, qreal top, qreal bottom) {
    const qreal newTop = std::max(rect.y(), top);
    const qreal newBottom = std::min(rect.y() + rect.height(), bottom);
    if (newTop >= newBottom)
        return {};
    return { rect.x(), newTop, rect.width(), newBottom - newTop };
}

} // namespace

namespace caelestia::components {

using Qt::StringLiterals::operator""_s;

// --- LazyListViewAttached ---

LazyListViewAttached::LazyListViewAttached(QObject* parent)
    : QObject(parent) {}

qreal LazyListViewAttached::preferredHeight() const {
    return m_preferredHeight;
}

void LazyListViewAttached::setPreferredHeight(qreal height) {
    if (qFuzzyCompare(m_preferredHeight + 1.0, height + 1.0))
        return;
    m_preferredHeight = height;
    emit preferredHeightChanged();
}

qreal LazyListViewAttached::visibleHeight() const {
    return m_visibleHeight;
}

void LazyListViewAttached::setVisibleHeight(qreal height) {
    if (qFuzzyCompare(m_visibleHeight + 1.0, height + 1.0))
        return;
    m_visibleHeight = height;
    emit visibleHeightChanged();
}

bool LazyListViewAttached::ready() const {
    return m_ready;
}

void LazyListViewAttached::setReady(bool ready) {
    if (m_ready == ready)
        return;
    m_ready = ready;
    emit readyChanged();
}

bool LazyListViewAttached::adding() const {
    return m_adding;
}

void LazyListViewAttached::setAdding(bool adding) {
    if (m_adding == adding)
        return;
    m_adding = adding;
    emit addingChanged();
}

bool LazyListViewAttached::removing() const {
    return m_removing;
}

void LazyListViewAttached::setRemoving(bool removing) {
    if (m_removing == removing)
        return;
    m_removing = removing;
    emit removingChanged();
}

bool LazyListViewAttached::trackViewport() const {
    return m_trackViewport;
}

void LazyListViewAttached::setTrackViewport(bool track) {
    if (m_trackViewport == track)
        return;
    m_trackViewport = track;
    emit trackViewportChanged();
}

// --- LazyListView ---

LazyListView::LazyListView(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents, false);
}

LazyListViewAttached* LazyListView::qmlAttachedProperties(QObject* object) {
    return new LazyListViewAttached(object);
}

LazyListView::~LazyListView() {
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
}

// --- Model & Delegate ---

QAbstractItemModel* LazyListView::model() const {
    return m_model;
}

void LazyListView::setModel(QAbstractItemModel* model) {
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

QQmlComponent* LazyListView::delegate() const {
    return m_delegate;
}

void LazyListView::setDelegate(QQmlComponent* delegate) {
    if (m_delegate == delegate)
        return;

    m_delegate = delegate;
    resetContent();
    emit delegateChanged();
}

// --- Layout ---

qreal LazyListView::spacing() const {
    return m_spacing;
}

void LazyListView::setSpacing(qreal spacing) {
    if (qFuzzyCompare(m_spacing, spacing))
        return;
    m_spacing = spacing;
    emit spacingChanged();
    polish();
}

qreal LazyListView::contentHeight() const {
    return m_contentHeight;
}

qreal LazyListView::layoutHeight() const {
    return m_layoutHeight;
}

qreal LazyListView::contentY() const {
    return m_contentY;
}

void LazyListView::setContentY(qreal contentY) {
    if (qFuzzyCompare(m_contentY, contentY))
        return;
    m_contentY = contentY;
    emit contentYChanged();
    polish();
}

// --- Viewport ---

QRectF LazyListView::viewport() const {
    return m_viewport;
}

void LazyListView::setViewport(const QRectF& viewport) {
    if (m_viewport == viewport)
        return;
    m_viewport = viewport;
    emit viewportChanged();
    if (m_useCustomViewport)
        polish();
}

bool LazyListView::useCustomViewport() const {
    return m_useCustomViewport;
}

void LazyListView::setUseCustomViewport(bool use) {
    if (m_useCustomViewport == use)
        return;
    m_useCustomViewport = use;
    emit useCustomViewportChanged();
    polish();
}

qreal LazyListView::cacheBuffer() const {
    return m_cacheBuffer;
}

void LazyListView::setCacheBuffer(qreal buffer) {
    if (qFuzzyCompare(m_cacheBuffer, buffer))
        return;
    m_cacheBuffer = buffer;
    emit cacheBufferChanged();
    polish();
}

// --- Sizing ---

qreal LazyListView::estimatedHeight() const {
    return m_estimatedHeight;
}

void LazyListView::setEstimatedHeight(qreal height) {
    if (qFuzzyCompare(m_estimatedHeight, height))
        return;
    m_estimatedHeight = height;
    emit estimatedHeightChanged();
    polish();
}

bool LazyListView::asynchronous() const {
    return m_asynchronous;
}

void LazyListView::setAsynchronous(bool async) {
    if (m_asynchronous == async)
        return;
    m_asynchronous = async;
    emit asynchronousChanged();
}

LazyListViewAttached* LazyListView::attachedFor(QQuickItem* item) {
    return qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
}

LazyListViewAttached* LazyListView::attachedForCreate(QQuickItem* item) {
    return qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, true));
}

qreal LazyListView::effectiveEstimatedHeight() const {
    if (m_estimatedHeight >= 0)
        return m_estimatedHeight;
    if (m_knownHeightCount > 0)
        return m_knownHeightSum / m_knownHeightCount;
    return k_fallbackHeight;
}

// Height used for layout positioning, falling back to the estimate while unmeasured
qreal LazyListView::layoutHeightAt(int index) const {
    const auto& record = m_layout[index];
    return record.heightKnown ? record.height : effectiveEstimatedHeight();
}

// Height as currently rendered, so scrolling follows in-flight animations
qreal LazyListView::visibleHeightAt(int index) const {
    const auto it = m_delegates.find(index);
    if (it != m_delegates.end() && it->item)
        return delegateVisibleHeight(it->item);
    return layoutHeightAt(index);
}

// Position of an item in visible-height space, including the spacing before it.
// Only non-zero height items participate, so collapsed rows add no spacing.
qreal LazyListView::visualYAt(int index) const {
    qreal y = 0;
    bool hasItem = false;
    for (int i = 0; i < index; ++i) {
        const qreal h = visibleHeightAt(i);
        if (h <= 0)
            continue;
        if (hasItem)
            y += m_spacing;
        hasItem = true;
        y += h;
    }
    if (hasItem && visibleHeightAt(index) > 0)
        y += m_spacing;
    return y;
}

qreal LazyListView::viewportTop() const {
    return m_useCustomViewport ? m_viewport.y() : m_contentY;
}

void LazyListView::trackHeight(qreal height) {
    m_knownHeightSum += height;
    ++m_knownHeightCount;
}

void LazyListView::untrackHeight(qreal height) {
    m_knownHeightSum -= height;
    --m_knownHeightCount;
}

// Records a measured height for an item, keeping the running average in sync
LazyListView::HeightUpdate LazyListView::setKnownHeight(int index, qreal height) {
    auto& record = m_layout[index];
    const HeightUpdate previous{ .previousHeight = layoutHeightAt(index), .wasKnown = record.heightKnown };

    if (record.heightKnown)
        untrackHeight(record.height);
    record.height = height;
    record.heightKnown = true;
    trackHeight(height);

    return previous;
}

// A resize above the viewport shifts everything below it, so opted-in delegates
// report the delta and let the consumer compensate its scroll position.
void LazyListView::adjustViewportIfAbove(int index, QQuickItem* item, qreal delta) {
    auto* attached = attachedFor(item);
    if (attached && attached->trackViewport() && m_layout[index].targetY < viewportTop())
        emit viewportAdjustNeeded(delta);
}

qreal LazyListView::delegateHeight(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = attachedFor(item);
    if (attached && attached->preferredHeight() >= 0)
        return attached->preferredHeight();

    return item->implicitHeight();
}

qreal LazyListView::delegateVisibleHeight(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = attachedFor(item);
    if (attached && attached->visibleHeight() >= 0)
        return attached->visibleHeight();

    return delegateHeight(item);
}

bool LazyListView::isDelegateReady(QQuickItem* item) {
    if (!item)
        return false;
    auto* attached = attachedFor(item);
    return !attached || attached->ready();
}

// --- Animation Durations ---

int LazyListView::removeDuration() const {
    return m_removeDuration;
}

void LazyListView::setRemoveDuration(int duration) {
    if (m_removeDuration == duration)
        return;
    m_removeDuration = duration;
    emit removeDurationChanged();
}

int LazyListView::readyDelay() const {
    return m_readyDelay;
}

void LazyListView::setReadyDelay(int delay) {
    if (m_readyDelay == delay)
        return;
    m_readyDelay = delay;
    emit readyDelayChanged();
}

// --- State ---

int LazyListView::count() const {
    return m_model ? m_model->rowCount() : 0;
}

// --- QQuickItem Overrides ---

void LazyListView::componentComplete() {
    QQuickItem::componentComplete();
    m_componentComplete = true;
    resetContent();
}

void LazyListView::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (!m_componentComplete)
        return;

    if (!qFuzzyCompare(newGeometry.width(), oldGeometry.width())) {
        for (auto& entry : m_delegates) {
            if (entry.item)
                entry.item->setWidth(newGeometry.width());
        }
    }

    polish();
}

void LazyListView::updatePolish() {
    if (!m_componentComplete || !m_model || !m_delegate)
        return;

    flushPendingInserts();
    relayout();
    syncDelegates();

    // Clear isNew flags - the add animation only plays for items created
    // during the same polish cycle as their model insertion, not for
    // delegates created later when scrolling items into the viewport.
    for (auto& record : m_layout)
        record.isNew = false;

    positionDelegates();
}

// Makes newly created delegates visible and clears the adding flag so enter
// animations begin. When readyDelay > 0 the reveal is deferred so delegates
// have time to lay out before appearing.
void LazyListView::flushPendingInserts() {
    for (auto& entry : m_delegates) {
        if (!entry.pendingInsert || !entry.item)
            continue;

        if (m_readyDelay <= 0) {
            entry.pendingInsert = false;
            revealDelegate(entry.item);
            continue;
        }

        if (!entry.readyDelayStarted) {
            entry.readyDelayStarted = true;
            QTimer::singleShot(m_readyDelay, this, [this, item = entry.item] {
                finishDelayedInsert(item);
            });
        }
    }
}

void LazyListView::revealDelegate(QQuickItem* item) {
    item->setVisible(true);

    auto* attached = attachedFor(item);
    if (attached) {
        attached->setAdding(false);
        attached->setReady(true);
    }
}

// Reveals a delegate whose readyDelay has elapsed, seeding its y from the
// current visual position so the move to the layout position animates.
void LazyListView::finishDelayedInsert(QQuickItem* item) {
    const int idx = indexOfDelegate(item);
    if (idx < 0)
        return;

    auto& entry = m_delegates[idx];
    if (!entry.pendingInsert)
        return;

    entry.pendingInsert = false;
    entry.readyDelayStarted = false;

    if (idx < static_cast<int>(m_layout.size()))
        item->setY(visualYAt(idx) - m_contentY);

    revealDelegate(item);

    // Re-check the bounds: revealing runs QML bindings and onReady handlers,
    // which may have mutated the model out from under us.
    if (idx < static_cast<int>(m_layout.size()))
        item->setProperty("y", m_layout[idx].targetY - m_contentY); // animate to layout position

    polish();
}

void LazyListView::positionDelegates() {
    for (auto& entry : m_delegates) {
        if (!entry.item || entry.pendingRemoval || entry.pendingInsert)
            continue;

        const int idx = entry.modelIndex;
        if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
            continue;

        if (m_layout[idx].heightKnown && qFuzzyIsNull(m_layout[idx].height))
            continue;

        // Use setProperty to go through the QML property system,
        // which triggers Behaviors (setY bypasses them).
        entry.item->setProperty("y", m_layout[idx].targetY - m_contentY);
    }
}

// --- Layout Engine ---

void LazyListView::relayout() {
    updateLayoutPositions();
    updateContentHeight();
}

// Layout positioning uses preferredHeight (final/non-animated).
// Only adds spacing between items with non-zero height.
void LazyListView::updateLayoutPositions() {
    qreal y = 0;
    bool hasItem = false;
    for (int i = 0; i < static_cast<int>(m_layout.size()); ++i) {
        auto& record = m_layout[i];
        record.targetY = y;

        const qreal h = layoutHeightAt(i);
        if (h <= 0)
            continue;

        if (hasItem) {
            y += m_spacing;
            record.targetY = y;
        }
        hasItem = true;
        y += h;
    }

    if (!qFuzzyCompare(m_layoutHeight + 1.0, y + 1.0)) {
        m_layoutHeight = y;
        emit layoutHeightChanged();
    }
}

// Content height tracks actual visible heights so scrolling follows animations
void LazyListView::updateContentHeight() {
    const int last = static_cast<int>(m_layout.size()) - 1;
    qreal visY = last < 0 ? 0 : visualYAt(last) + visibleHeightAt(last);

    // Account for dying delegates still visually present
    for (const auto& dying : std::as_const(m_dyingDelegates)) {
        if (!dying.item)
            continue;
        const qreal dyingH = delegateVisibleHeight(dying.item);
        if (dyingH > 0)
            visY = std::max(visY, dying.item->y() + dyingH);
    }

    if (!qFuzzyCompare(m_contentHeight + 1.0, visY + 1.0)) {
        m_contentHeight = visY;
        emit contentHeightChanged();
    }
}

// Coalesces height-driven relayouts into a single deferred pass
void LazyListView::scheduleRelayout() {
    if (m_relayoutPending)
        return;

    m_relayoutPending = true;
    QTimer::singleShot(0, this, [this] {
        m_relayoutPending = false;
        relayout();
        polish();
    });
}

QRectF LazyListView::effectiveViewport() const {
    QRectF vp;
    if (m_useCustomViewport)
        vp = m_viewport;
    else
        vp = QRectF(0, m_contentY, width(), height());

    // During Flickable overshoot the viewport can extend entirely beyond content bounds,
    // causing all delegates to be culled. Clamp so it always overlaps [0, layoutHeight].
    // Only needed for the built-in viewport — custom viewports represent the actual
    // visible area and may legitimately lie entirely outside the content.
    if (!m_useCustomViewport && m_layoutHeight > 0) {
        const qreal top = std::min(vp.y(), m_layoutHeight);
        const qreal bottom = std::max(vp.y() + vp.height(), 0.0);
        if (bottom > top)
            vp = QRectF(vp.x(), top, vp.width(), bottom - top);
    }

    vp.adjust(0, -m_cacheBuffer, 0, m_cacheBuffer);

    // Trim the cache-buffered viewport to [0, layoutHeight]. No items exist outside
    // those bounds, so extending past them wastes budget and can cause edge thrashing
    // when a large cache buffer reaches the opposite end of the content.
    if (m_layoutHeight > 0)
        return clipVertical(vp, 0, m_layoutHeight);

    return vp;
}

std::pair<int, int> LazyListView::computeVisibleRange() const {
    if (m_layout.isEmpty())
        return { -1, -1 };

    const auto vp = effectiveViewport();
    if (vp.isEmpty())
        return { -1, -1 };

    const qreal vpTop = vp.y();
    const qreal vpBottom = vp.y() + vp.height();

    // Binary search for first visible item
    int lo = 0;
    int hi = static_cast<int>(m_layout.size()) - 1;
    int first = static_cast<int>(m_layout.size());

    while (lo <= hi) {
        const int mid = lo + (hi - lo) / 2;
        const auto& record = m_layout[mid];
        const qreal itemBottom = record.targetY + (record.heightKnown ? record.height : effectiveEstimatedHeight());

        if (itemBottom >= vpTop) {
            first = mid;
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }

    if (first >= static_cast<int>(m_layout.size()))
        return { -1, -1 };

    // Linear scan for last visible item
    int last = first;
    for (int i = first; i < static_cast<int>(m_layout.size()); ++i) {
        if (m_layout[i].targetY > vpBottom)
            break;
        last = i;
    }

    return { first, last };
}

// --- Delegate Lifecycle ---

void LazyListView::syncDelegates() {
    const auto [first, last] = computeVisibleRange();

    // Collect indices that should be alive
    QSet<int> visibleIndices;
    if (first >= 0) {
        for (int i = first; i <= last; ++i)
            visibleIndices.insert(i);
    }

    const auto toRemove = delegatesOutsideViewport(visibleIndices, effectiveViewport());
    const int destroyed =
        destroyDelegates(toRemove, m_asynchronous ? k_asyncBatchDestroy : static_cast<int>(toRemove.size()));

    const auto toCreate = missingDelegates(first, last);
    const int created =
        createDelegates(toCreate, m_asynchronous ? k_asyncBatchCreate : static_cast<int>(toCreate.size()));

    // Pending inserts need to become visible on the next frame, and
    // async mode may have remaining create/destroy work.
    const bool workRemains = m_asynchronous && (destroyed < static_cast<int>(toRemove.size()) ||
                                                   created < static_cast<int>(toCreate.size()));
    if (created > 0 || workRemains)
        polish();
}

// Delegates safe to destroy - outside the range to keep and no longer visually
// overlapping the viewport, so nothing mid-animation disappears.
QList<int> LazyListView::delegatesOutsideViewport(const QSet<int>& keep, const QRectF& viewport) const {
    QList<int> outside;

    for (auto it = m_delegates.constBegin(); it != m_delegates.constEnd(); ++it) {
        if (keep.contains(it.key()))
            continue;

        if (!it->item || viewport.isEmpty()) {
            outside.append(it.key());
            continue;
        }

        const qreal itemTop = it->item->y();
        const qreal itemBottom = itemTop + delegateVisibleHeight(it->item);
        if (itemBottom < viewport.top() || itemTop > viewport.bottom())
            outside.append(it.key());
    }

    return outside;
}

QList<int> LazyListView::missingDelegates(int first, int last) const {
    if (first < 0)
        return {};

    QList<int> missing;
    for (int i = first; i <= last; ++i) {
        if (!m_delegates.contains(i))
            missing.append(i);
    }

    return missing;
}

int LazyListView::destroyDelegates(const QList<int>& indices, int budget) {
    // Take entries out of the maps first so destruction cannot observe
    // a delegate that is already unreachable from the view.
    QVector<DelegateEntry> removed;
    removed.reserve(std::min(budget, static_cast<int>(indices.size())));

    for (const int idx : indices) {
        if (static_cast<int>(removed.size()) >= budget)
            break;

        auto entry = m_delegates.take(idx);
        if (entry.item)
            m_itemToIndex.remove(entry.item);
        removed.append(std::move(entry));
    }

    for (auto& entry : removed)
        destroyDelegate(entry);

    return static_cast<int>(removed.size());
}

int LazyListView::createDelegates(const QList<int>& indices, int budget) {
    int created = 0;

    for (const int idx : indices) {
        if (created >= budget)
            break;

        auto entry = createDelegate(idx);
        if (!entry.item)
            continue;

        // Height tracking and viewport compensation are deferred
        // until the delegate signals ready via readyChanged.
        entry.pendingInsert = true;
        entry.item->setY(m_layout[idx].targetY - m_contentY);
        m_itemToIndex.insert(entry.item, idx);
        m_delegates.insert(idx, entry);
        ++created;
    }

    return created;
}

LazyListView::DelegateEntry LazyListView::createDelegate(int modelIndex) {
    DelegateEntry entry;
    entry.modelIndex = modelIndex;

    if (!m_delegate || !m_model)
        return entry;

    // Use the delegate component's creation context for beginCreate
    // so bound components (pragma ComponentBehavior: Bound) are accepted.
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

    const auto props = delegateProperties(modelIndex);
    QVariantMap initialProps;
    for (const auto& [name, value] : props)
        initialProps.insert(name, value);
    m_delegate->setInitialProperties(entry.item, initialProps);

    entry.item->setParentItem(this);
    entry.item->setWidth(width());

    // Only set adding = true for genuinely new model items (not viewport entries).
    // Cleared on the next frame in updatePolish when the item becomes visible.
    if (modelIndex < static_cast<int>(m_layout.size()) && m_layout[modelIndex].isNew) {
        auto* attached = attachedForCreate(entry.item);
        if (attached)
            attached->setAdding(true);
    }

    m_delegate->completeCreate();

    // Keep adding=true and hide - flushed on the next frame in updatePolish
    entry.item->setVisible(false);

    connectDelegate(entry);

    return entry;
}

void LazyListView::connectDelegate(const DelegateEntry& entry) {
    auto* item = entry.item;

    // Watch implicitHeight as fallback
    connect(item, &QQuickItem::implicitHeightChanged, this, [this, item] {
        onDelegateHeightChanged(item);
    });

    // Watch attached properties if the delegate uses them
    auto* attached = attachedFor(item);
    if (!attached)
        return;

    connect(attached, &LazyListViewAttached::preferredHeightChanged, this, [this, item] {
        onDelegateHeightChanged(item);
    });
    connect(attached, &LazyListViewAttached::visibleHeightChanged, this, [this] {
        polish();
    });
    connect(attached, &LazyListViewAttached::readyChanged, this, [this, item] {
        onDelegateReady(item);
    });
}

// Resolves a delegate item to its model index, or -1 if it is no longer the
// live delegate for that index (stale signal from a destroyed or replaced item).
int LazyListView::indexOfDelegate(QQuickItem* item) const {
    const auto indexIt = m_itemToIndex.constFind(item);
    if (indexIt == m_itemToIndex.constEnd())
        return -1;

    const int idx = indexIt.value();
    const auto delegateIt = m_delegates.constFind(idx);
    if (delegateIt == m_delegates.constEnd() || delegateIt->item != item)
        return -1;

    return idx;
}

// Re-measures a delegate whose height changed after it became ready
void LazyListView::onDelegateHeightChanged(QQuickItem* item) {
    if (!isDelegateReady(item))
        return;

    const int idx = indexOfDelegate(item);
    if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
        return;

    const qreal h = delegateHeight(item);
    if (qFuzzyCompare(m_layout[idx].height + 1.0, h + 1.0))
        return;

    const auto previous = setKnownHeight(idx, h);
    if (previous.wasKnown)
        adjustViewportIfAbove(idx, item, h - previous.previousHeight);

    scheduleRelayout();
}

// Takes the first real measurement once a delegate reports itself ready
void LazyListView::onDelegateReady(QQuickItem* item) {
    if (!isDelegateReady(item))
        return;

    const int idx = indexOfDelegate(item);
    if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
        return;

    const qreal h = delegateHeight(item);
    const auto previous = setKnownHeight(idx, h);
    if (!qFuzzyCompare(h + 1.0, previous.previousHeight + 1.0))
        adjustViewportIfAbove(idx, item, h - previous.previousHeight);

    polish();
}

void LazyListView::destroyDelegate(DelegateEntry& entry) {
    if (entry.item) {
        entry.item->setParentItem(nullptr);
        entry.item->setVisible(false);
        entry.item->deleteLater();
        entry.item = nullptr;
    }
}

// Delegate properties for a row, in the order they must be applied: every model
// role, then index, then a modelData fallback for models with no such role.
// The order is observable - an onIndexChanged handler may read modelData.
LazyListView::PropertyList LazyListView::delegateProperties(int modelIndex) const {
    PropertyList props;
    if (!m_model)
        return props;

    const auto roleNames = m_model->roleNames();
    const auto index = m_model->index(modelIndex, 0);
    bool hasModelData = false;

    props.reserve(roleNames.size() + 2);

    for (auto it = roleNames.constBegin(); it != roleNames.constEnd(); ++it) {
        const auto name = QString::fromUtf8(it.value());
        props.emplaceBack(name, m_model->data(index, it.key()));
        if (name == u"modelData"_s)
            hasModelData = true;
    }

    props.emplaceBack(u"index"_s, modelIndex);

    if (!hasModelData) {
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        props.emplaceBack(u"modelData"_s, m_model->data(index, role));
    }

    return props;
}

void LazyListView::updateDelegateData(DelegateEntry& entry) {
    if (!m_model || !entry.item)
        return;

    const auto props = delegateProperties(entry.modelIndex);
    for (const auto& [name, value] : props)
        entry.item->setProperty(name.toUtf8().constData(), value);
}

// Re-keys every delegate through mapIndex, keeping modelIndex, the reverse
// lookup and the delegate's own index property in sync.
void LazyListView::remapDelegates(const std::function<int(int)>& mapIndex) {
    QHash<int, DelegateEntry> remapped;
    remapped.reserve(m_delegates.size());

    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        const int newIdx = mapIndex(it.key());
        auto entry = it.value();
        entry.modelIndex = newIdx;
        if (entry.item) {
            entry.item->setProperty("index", newIdx);
            m_itemToIndex[entry.item] = newIdx;
        }
        remapped.insert(newIdx, entry);
    }

    m_delegates = std::move(remapped);
}

// --- Model Connection ---

void LazyListView::connectModel() {
    if (!m_model)
        return;

    m_modelConnections = {
        connect(m_model, &QAbstractItemModel::rowsInserted, this, &LazyListView::onRowsInserted),
        connect(m_model, &QAbstractItemModel::rowsAboutToBeRemoved, this, &LazyListView::onRowsAboutToBeRemoved),
        connect(m_model, &QAbstractItemModel::rowsRemoved, this, &LazyListView::onRowsRemoved),
        connect(m_model, &QAbstractItemModel::rowsMoved, this, &LazyListView::onRowsMoved),
        connect(m_model, &QAbstractItemModel::dataChanged, this, &LazyListView::onDataChanged),
        connect(m_model, &QAbstractItemModel::modelReset, this, &LazyListView::onModelReset),
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

void LazyListView::disconnectModel() {
    for (auto& conn : m_modelConnections)
        disconnect(conn);
    m_modelConnections.clear();
}

void LazyListView::resetContent() {
    // Stop all animations and destroy all delegates
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    m_delegates.clear();
    m_itemToIndex.clear();

    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
    m_dyingDelegates.clear();

    // Reset pending state
    m_knownHeightSum = 0;
    m_knownHeightCount = 0;

    // Rebuild layout from model
    m_layout.clear();
    if (m_model && m_componentComplete) {
        m_layout.resize(m_model->rowCount());
        emit countChanged();
    }

    polish();
}

void LazyListView::onRowsInserted(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int insertCount = last - first + 1;
    // Insert new layout records
    m_layout.insert(first, insertCount, ItemRecord{ .targetY = 0, .height = 0, .heightKnown = false, .isNew = true });

    // Shift existing delegate indices
    remapDelegates([first, insertCount](int idx) {
        return idx >= first ? idx + insertCount : idx;
    });

    emit countChanged();
    polish();
}

void LazyListView::onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    for (int i = first; i <= last; ++i) {
        if (!m_delegates.contains(i))
            continue;

        auto entry = m_delegates.take(i);
        if (entry.item)
            m_itemToIndex.remove(entry.item);
        entry.pendingRemoval = true;

        // Never made visible — skip remove animation
        if (entry.pendingInsert) {
            destroyDelegate(entry);
            continue;
        }

        if (m_removeDuration > 0 && entry.item) {
            auto* attached = attachedFor(entry.item);
            if (attached)
                attached->setRemoving(true);

            // Schedule destruction after the remove animation duration
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

void LazyListView::onRowsRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int removeCount = last - first + 1;

    // Untrack known heights being removed
    for (int i = first; i <= last; ++i) {
        if (m_layout[i].heightKnown)
            untrackHeight(m_layout[i].height);
    }

    // Remove layout records
    m_layout.remove(first, removeCount);

    // Shift remaining delegate indices down
    remapDelegates([last, removeCount](int idx) {
        return idx > last ? idx - removeCount : idx;
    });

    emit countChanged();
    polish();
}

void LazyListView::onRowsMoved(const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row) {
    if (parent.isValid() || destination.isValid())
        return;

    const int count = end - start + 1;
    const int dest = row > start ? row - count : row;

    // Reorder layout records
    QVector<ItemRecord> moved;
    moved.reserve(count);
    for (int i = start; i <= end; ++i)
        moved.append(m_layout[i]);
    m_layout.remove(start, count);
    for (int i = 0; i < count; ++i)
        m_layout.insert(dest + i, moved[i]);

    // Remap delegate indices to match new model order
    remapDelegates([start, end, dest, count](int idx) {
        if (idx >= start && idx <= end)
            return dest + (idx - start);

        int newIdx = idx > end ? idx - count : idx;
        if (newIdx >= dest)
            newIdx += count;
        return newIdx;
    });

    polish();
}

void LazyListView::onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles) {
    Q_UNUSED(roles)

    if (topLeft.parent().isValid())
        return;

    for (int i = topLeft.row(); i <= bottomRight.row(); ++i) {
        if (m_delegates.contains(i))
            updateDelegateData(m_delegates[i]);
    }
}

void LazyListView::onModelReset() {
    if (!m_model) {
        resetContent();
        return;
    }

    const int newRows = m_model->rowCount();
    const int oldRows = static_cast<int>(m_layout.size());

    // Check if the model data actually changed
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
            // Model content unchanged, just refresh delegate data
            for (auto& entry : m_delegates)
                updateDelegateData(entry);
            return;
        }
    }

    resetContent();
}

} // namespace caelestia::components
