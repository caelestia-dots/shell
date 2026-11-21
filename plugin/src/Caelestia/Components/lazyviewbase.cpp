#include "lazyviewbase.hpp"

#include <qqmlcontext.h>
#include <qtimer.h>

#include <algorithm>
#include <ranges>

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

namespace caelestia::shell::components {

using Qt::StringLiterals::operator""_s;

// --- LazyViewAttached ---

LazyViewAttached::LazyViewAttached(QObject* parent)
    : QObject(parent) {}

qreal LazyViewAttached::preferredHeight() const {
    return m_preferredHeight;
}

void LazyViewAttached::setPreferredHeight(qreal height) {
    if (qFuzzyCompare(m_preferredHeight + 1.0, height + 1.0))
        return;
    m_preferredHeight = height;
    emit preferredHeightChanged();
}

bool LazyViewAttached::ready() const {
    return m_ready;
}

void LazyViewAttached::setReady(bool ready) {
    if (m_ready == ready)
        return;
    m_ready = ready;
    emit readyChanged();
}

bool LazyViewAttached::adding() const {
    return m_adding;
}

void LazyViewAttached::setAdding(bool adding) {
    if (m_adding == adding)
        return;
    m_adding = adding;
    emit addingChanged();
}

bool LazyViewAttached::removing() const {
    return m_removing;
}

void LazyViewAttached::setRemoving(bool removing) {
    if (m_removing == removing)
        return;
    m_removing = removing;
    emit removingChanged();
}

bool LazyViewAttached::trackViewport() const {
    return m_trackViewport;
}

void LazyViewAttached::setTrackViewport(bool track) {
    if (m_trackViewport == track)
        return;
    m_trackViewport = track;
    emit trackViewportChanged();
}

// --- LazyViewBase ---

LazyViewBase::LazyViewBase(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents, false);
}

LazyViewBase::~LazyViewBase() {
    for (auto& entry : m_delegates)
        LazyViewBase::destroyDelegate(entry);
    for (auto& entry : m_dyingDelegates)
        LazyViewBase::destroyDelegate(entry);
}

// --- Model & Delegate ---

QAbstractItemModel* LazyViewBase::model() const {
    return m_model;
}

void LazyViewBase::setModel(QAbstractItemModel* model) {
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

QQmlComponent* LazyViewBase::delegate() const {
    return m_delegate;
}

void LazyViewBase::setDelegate(QQmlComponent* delegate) {
    if (m_delegate == delegate)
        return;

    m_delegate = delegate;
    resetContent();
    emit delegateChanged();
}

// --- Layout ---

qreal LazyViewBase::layoutHeight() const {
    return m_layoutHeight;
}

void LazyViewBase::setLayoutHeight(qreal height) {
    if (qFuzzyCompare(m_layoutHeight + 1.0, height + 1.0))
        return;
    m_layoutHeight = height;
    emit layoutHeightChanged();
}

qreal LazyViewBase::contentHeight() const {
    return m_contentHeight;
}

void LazyViewBase::setContentHeight(qreal height) {
    if (qFuzzyCompare(m_contentHeight + 1.0, height + 1.0))
        return;
    m_contentHeight = height;
    emit contentHeightChanged();
}

qreal LazyViewBase::dyingExtent() const {
    qreal extent = 0;
    for (const auto& dying : std::as_const(m_dyingDelegates)) {
        if (!dying.item)
            continue;
        const qreal h = visibleHeightOf(dying.item);
        if (h > 0)
            extent = std::max(extent, dying.item->y() + m_contentY + h);
    }
    return extent;
}

qreal LazyViewBase::contentY() const {
    return m_contentY;
}

void LazyViewBase::setContentY(qreal contentY) {
    if (qFuzzyCompare(m_contentY, contentY))
        return;
    m_contentY = contentY;
    emit contentYChanged();
    polish();
}

// --- Viewport ---

QRectF LazyViewBase::viewport() const {
    return m_viewport;
}

void LazyViewBase::setViewport(const QRectF& viewport) {
    if (m_viewport == viewport)
        return;
    m_viewport = viewport;
    emit viewportChanged();
    if (m_useCustomViewport)
        polish();
}

bool LazyViewBase::useCustomViewport() const {
    return m_useCustomViewport;
}

void LazyViewBase::setUseCustomViewport(bool use) {
    if (m_useCustomViewport == use)
        return;
    m_useCustomViewport = use;
    emit useCustomViewportChanged();
    polish();
}

qreal LazyViewBase::cacheBuffer() const {
    return m_cacheBuffer;
}

void LazyViewBase::setCacheBuffer(qreal buffer) {
    if (qFuzzyCompare(m_cacheBuffer, buffer))
        return;
    m_cacheBuffer = buffer;
    emit cacheBufferChanged();
    polish();
}

bool LazyViewBase::cullDelegates() const {
    return m_cullDelegates;
}

void LazyViewBase::setCullDelegates(bool cull) {
    if (m_cullDelegates == cull)
        return;
    m_cullDelegates = cull;
    emit cullDelegatesChanged();
    polish();
}

// --- Sizing ---

qreal LazyViewBase::estimatedItemHeight() const {
    return m_estimatedItemHeight;
}

void LazyViewBase::setEstimatedItemHeight(qreal height) {
    if (qFuzzyCompare(m_estimatedItemHeight, height))
        return;
    m_estimatedItemHeight = height;
    emit estimatedItemHeightChanged();
    polish();
}

bool LazyViewBase::asynchronous() const {
    return m_asynchronous;
}

void LazyViewBase::setAsynchronous(bool async) {
    if (m_asynchronous == async)
        return;
    m_asynchronous = async;
    emit asynchronousChanged();
}

qreal LazyViewBase::effectiveEstimatedHeight() const {
    if (m_estimatedItemHeight >= 0)
        return m_estimatedItemHeight;
    if (m_knownHeightCount > 0)
        return m_knownHeightSum / m_knownHeightCount;
    return k_fallbackHeight;
}

// Height used for layout positioning, falling back to the estimate while unmeasured
qreal LazyViewBase::layoutHeightAt(int index) const {
    const auto& record = m_layout[index];
    return record.heightKnown ? record.height : effectiveEstimatedHeight();
}

qreal LazyViewBase::viewportTop() const {
    return m_useCustomViewport ? m_viewport.y() : m_contentY;
}

void LazyViewBase::trackHeight(qreal height) {
    m_knownHeightSum += height;
    ++m_knownHeightCount;
}

void LazyViewBase::untrackHeight(qreal height) {
    m_knownHeightSum -= height;
    --m_knownHeightCount;
}

// Records a measured height for an item, keeping the running average in sync
qreal LazyViewBase::setKnownHeight(int index, qreal height) {
    auto& record = m_layout[index];
    const qreal previous = layoutHeightAt(index);

    if (record.heightKnown)
        untrackHeight(record.height);
    record.height = height;
    record.heightKnown = true;
    trackHeight(height);

    return previous;
}

// Records a new measurement, compensating the viewport for resizes above it
void LazyViewBase::applyMeasuredHeight(int index, qreal height) {
    if (index < 0 || index >= static_cast<int>(m_layout.size()))
        return;
    if (m_layout[index].heightKnown && qFuzzyCompare(m_layout[index].height + 1.0, height + 1.0))
        return;

    const qreal previous = setKnownHeight(index, height);
    if (!qFuzzyCompare(height + 1.0, previous + 1.0))
        adjustViewportIfAbove(index, m_delegates.value(index).item, height - previous);

    scheduleRelayout();
}

// Opted-in delegates report resizes above the viewport so the consumer can compensate scroll
void LazyViewBase::adjustViewportIfAbove(int index, QQuickItem* item, qreal delta) {
    if (!item)
        return;
    const auto* attached = attachedFor(item);
    if (attached && attached->trackViewport() && m_layout[index].top < viewportTop())
        emit viewportAdjustNeeded(delta);
}

qreal LazyViewBase::delegateHeight(QQuickItem* item) const {
    if (!item)
        return 0;

    const auto* attached = attachedFor(item);
    if (attached && attached->preferredHeight() >= 0)
        return attached->preferredHeight();

    return item->implicitHeight();
}

// --- Animation Durations ---

int LazyViewBase::removeDuration() const {
    return m_removeDuration;
}

void LazyViewBase::setRemoveDuration(int duration) {
    if (m_removeDuration == duration)
        return;
    m_removeDuration = duration;
    emit removeDurationChanged();
}

int LazyViewBase::readyDelay() const {
    return m_readyDelay;
}

void LazyViewBase::setReadyDelay(int delay) {
    if (m_readyDelay == delay)
        return;
    m_readyDelay = delay;
    emit readyDelayChanged();
}

// --- State ---

int LazyViewBase::count() const {
    return m_model ? m_model->rowCount() : 0;
}

// Always false; bind through it to re-run itemAtIndex/itemAt on mapping changes
bool LazyViewBase::itemsDirty() {
    return false;
}

// Instantiated delegate for a model index, nullptr if outside the cache
QQuickItem* LazyViewBase::itemAtIndex(int index) const {
    return m_delegates.value(index).item;
}

// Hit test against instantiated delegates at their current visual positions
QQuickItem* LazyViewBase::itemAt(qreal x, qreal y) const {
    if (x < 0 || x >= width() || y < 0)
        return nullptr;

    const auto children = childItems();
    for (auto* const item : children | std::views::reverse) {
        if (!m_itemToIndex.contains(item) || !item->isVisible())
            continue;

        const auto top = item->y() + m_contentY;
        const auto bottom = top + visibleHeightOf(item);
        const auto left = item->x();
        const auto right = left + item->width();

        if (y >= top && y < bottom && x >= left && x < right)
            return item;
    }

    return nullptr;
}

// --- Default hooks ---

void LazyViewBase::delegateCreated(DelegateEntry& entry) {
    applyMeasuredHeight(entry.modelIndex, delegateHeight(entry.item));
}

void LazyViewBase::onDelegateHeightChanged(QQuickItem* item) {
    const int idx = indexOfDelegate(item);
    if (idx < 0)
        return;
    applyMeasuredHeight(idx, delegateHeight(item));
}

void LazyViewBase::revealDelegate(DelegateEntry& entry, bool delayed) {
    Q_UNUSED(delayed)

    entry.item->setVisible(true);

    auto* attached = attachedFor(entry.item);
    if (attached) {
        attached->setAdding(false);
        attached->setReady(true);
    }
}

void LazyViewBase::delegateRemoving(DelegateEntry& entry) {
    Q_UNUSED(entry)
}

void LazyViewBase::destroyDelegate(DelegateEntry& entry) {
    if (entry.item) {
        entry.item->setParentItem(nullptr);
        entry.item->setVisible(false);
        entry.item->deleteLater();
        entry.item = nullptr;
    }
}

void LazyViewBase::viewWidthChanged(qreal newWidth, qreal oldWidth) {
    Q_UNUSED(newWidth)
    Q_UNUSED(oldWidth)
}

// --- QQuickItem Overrides ---

void LazyViewBase::componentComplete() {
    QQuickItem::componentComplete();
    m_componentComplete = true;
    resetContent();
}

void LazyViewBase::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (!m_componentComplete)
        return;

    if (!qFuzzyCompare(newGeometry.width(), oldGeometry.width()))
        viewWidthChanged(newGeometry.width(), oldGeometry.width());

    polish();
}

void LazyViewBase::updatePolish() {
    if (!m_componentComplete || !m_model || !m_delegate)
        return;

    flushPendingInserts();
    relayout();
    syncDelegates();

    // Add animation only plays for delegates created in the insertion's polish
    for (auto& record : m_layout)
        record.isNew = false;

    for (auto& entry : m_delegates) {
        if (!entry.item || entry.pendingRemoval || entry.pendingInsert)
            continue;
        positionDelegate(entry);
    }
}

// Reveals new delegates, deferred by readyDelay so they can lay out first
void LazyViewBase::flushPendingInserts() {
    QList<QQuickItem*> pending;
    for (const auto& entry : std::as_const(m_delegates)) {
        if (entry.pendingInsert && entry.item)
            pending.append(entry.item);
    }

    // Re-resolve per item; reveal handlers may mutate the model and rebuild m_delegates
    for (auto* item : std::as_const(pending)) {
        const int idx = indexOfDelegate(item);
        if (idx < 0)
            continue;

        auto& entry = m_delegates[idx];
        if (!entry.pendingInsert)
            continue;

        if (m_readyDelay <= 0) {
            entry.pendingInsert = false;
            revealDelegate(entry, false);
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

void LazyViewBase::finishDelayedInsert(QQuickItem* item) {
    int idx = indexOfDelegate(item);
    if (idx < 0)
        return;

    auto& entry = m_delegates[idx];
    if (!entry.pendingInsert)
        return;

    entry.pendingInsert = false;
    entry.readyDelayStarted = false;
    revealDelegate(entry, true);

    // Re-resolve; onReady handlers may have mutated the model
    idx = indexOfDelegate(item);
    if (idx >= 0 && idx < static_cast<int>(m_layout.size()))
        positionDelegate(m_delegates[idx]);

    polish();
}

// Coalesces height-driven relayouts into a single deferred pass
void LazyViewBase::scheduleRelayout() {
    if (m_relayoutPending)
        return;

    m_relayoutPending = true;
    QTimer::singleShot(0, this, [this] {
        m_relayoutPending = false;
        relayout();
        polish();
    });
}

QRectF LazyViewBase::effectiveViewport() const {
    QRectF vp;
    if (m_useCustomViewport)
        vp = m_viewport;
    else
        vp = QRectF(0, m_contentY, width(), height());

    // Flickable overshoot can push the viewport fully outside the content; keep it overlapping
    if (!m_useCustomViewport && m_layoutHeight > 0) {
        const qreal top = std::min(vp.y(), m_layoutHeight);
        const qreal bottom = std::max(vp.y() + vp.height(), 0.0);
        if (bottom > top)
            vp = QRectF(vp.x(), top, vp.width(), bottom - top);
    }

    vp.adjust(0, -m_cacheBuffer, 0, m_cacheBuffer);

    // Clip to content bounds so a large cache buffer cannot thrash the far edge
    if (m_layoutHeight > 0)
        return clipVertical(vp, 0, m_layoutHeight);

    return vp;
}

std::pair<int, int> LazyViewBase::computeVisibleRange() const {
    if (m_layout.isEmpty())
        return { -1, -1 };

    // Culling disabled: keep every delegate alive
    if (!m_cullDelegates)
        return { 0, static_cast<int>(m_layout.size()) - 1 };

    const int spans = spanCount();
    if (spans <= 0)
        return { -1, -1 };

    const auto vp = effectiveViewport();
    if (vp.isEmpty())
        return { -1, -1 };

    const qreal vpTop = vp.y();
    const qreal vpBottom = vp.y() + vp.height();

    // Binary search for first visible span
    int lo = 0;
    int hi = spans - 1;
    int first = spans;

    while (lo <= hi) {
        const int mid = lo + (hi - lo) / 2;
        if (spanTop(mid) + spanHeight(mid) >= vpTop) {
            first = mid;
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }

    if (first >= spans)
        return { -1, -1 };

    // Linear scan for last visible span
    int last = first;
    for (int i = first; i < spans; ++i) {
        if (spanTop(i) > vpBottom)
            break;
        last = i;
    }

    return itemsForSpans(first, last);
}

// --- Delegate Lifecycle ---

void LazyViewBase::syncDelegates() {
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

    const bool workRemains = m_asynchronous && (destroyed < static_cast<int>(toRemove.size()) ||
                                                   created < static_cast<int>(toCreate.size()));
    if (created > 0 || workRemains)
        polish();

    if (created > 0 || destroyed > 0)
        emit itemsDirtyChanged();
}

// Outside the keep range and no longer overlapping the viewport, so mid-animation items stay
QList<int> LazyViewBase::delegatesOutsideViewport(const QSet<int>& keep, const QRectF& viewport) const {
    QList<int> outside;

    for (auto it = m_delegates.constBegin(); it != m_delegates.constEnd(); ++it) {
        if (keep.contains(it.key()))
            continue;

        if (!it->item || viewport.isEmpty()) {
            outside.append(it.key());
            continue;
        }

        // item->y() is in view coordinates; shift back to content space to match the viewport
        const qreal itemTop = it->item->y() + m_contentY;
        const qreal itemBottom = itemTop + visibleHeightOf(it->item);
        if (itemBottom < viewport.top() || itemTop > viewport.bottom())
            outside.append(it.key());
    }

    return outside;
}

QList<int> LazyViewBase::missingDelegates(int first, int last) const {
    if (first < 0)
        return {};

    QList<int> missing;
    for (int i = first; i <= last; ++i) {
        if (!m_delegates.contains(i))
            missing.append(i);
    }

    return missing;
}

int LazyViewBase::destroyDelegates(const QList<int>& indices, int budget) {
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

int LazyViewBase::createDelegates(const QList<int>& indices, int budget) {
    int created = 0;

    for (const int idx : indices) {
        if (created >= budget)
            break;

        auto entry = createDelegate(idx);
        if (!entry.item)
            continue;

        entry.pendingInsert = true;
        m_itemToIndex.insert(entry.item, idx);
        auto& stored = m_delegates[idx];
        stored = entry;
        placeCreatedDelegate(stored);
        connectDelegate(stored);
        delegateCreated(stored);
        ++created;
    }

    return created;
}

LazyViewBase::DelegateEntry LazyViewBase::createDelegate(int modelIndex) {
    DelegateEntry entry;
    entry.modelIndex = modelIndex;

    if (!m_delegate || !m_model)
        return entry;

    // Creation context so ComponentBehavior: Bound delegates are accepted
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
    entry.item->setWidth(delegateWidth());

    // adding only for new model items, not viewport entries
    if (modelIndex < static_cast<int>(m_layout.size()) && m_layout[modelIndex].isNew) {
        auto* attached = attachedForCreate(entry.item);
        if (attached)
            attached->setAdding(true);
    }

    m_delegate->completeCreate();

    // Keep adding=true and hide - flushed on the next frame in updatePolish
    entry.item->setVisible(false);

    return entry;
}

void LazyViewBase::connectDelegate(const DelegateEntry& entry) {
    auto* item = entry.item;

    // Watch implicitHeight as fallback
    connect(item, &QQuickItem::implicitHeightChanged, this, [this, item] {
        onDelegateHeightChanged(item);
    });

    const auto* attached = attachedFor(item);
    if (!attached)
        return;

    connect(attached, &LazyViewAttached::preferredHeightChanged, this, [this, item] {
        onDelegateHeightChanged(item);
    });
}

// Model index of a live delegate, -1 for a stale signal from a replaced item
int LazyViewBase::indexOfDelegate(QQuickItem* item) const {
    const auto indexIt = m_itemToIndex.constFind(item);
    if (indexIt == m_itemToIndex.constEnd())
        return -1;

    const int idx = indexIt.value();
    const auto delegateIt = m_delegates.constFind(idx);
    if (delegateIt == m_delegates.constEnd() || delegateIt->item != item)
        return -1;

    return idx;
}

// Order is observable: roles, then index, then modelData fallback
LazyViewBase::PropertyList LazyViewBase::delegateProperties(int modelIndex) const {
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
        if (name == u"modelData")
            hasModelData = true;
    }

    props.emplaceBack(u"index"_s, modelIndex);

    if (!hasModelData) {
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        props.emplaceBack(u"modelData"_s, m_model->data(index, role));
    }

    return props;
}

void LazyViewBase::updateDelegateData(DelegateEntry& entry) {
    if (!m_model || !entry.item)
        return;

    const auto props = delegateProperties(entry.modelIndex);
    for (const auto& [name, value] : props)
        entry.item->setProperty(name.toUtf8().constData(), value);
}

void LazyViewBase::remapDelegates(const std::function<int(int)>& mapIndex) {
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
    emit itemsDirtyChanged();
}

// --- Model Connection ---

void LazyViewBase::connectModel() {
    if (!m_model)
        return;

    m_modelConnections = {
        connect(m_model, &QAbstractItemModel::rowsInserted, this, &LazyViewBase::onRowsInserted),
        connect(m_model, &QAbstractItemModel::rowsAboutToBeRemoved, this, &LazyViewBase::onRowsAboutToBeRemoved),
        connect(m_model, &QAbstractItemModel::rowsRemoved, this, &LazyViewBase::onRowsRemoved),
        connect(m_model, &QAbstractItemModel::rowsMoved, this, &LazyViewBase::onRowsMoved),
        connect(m_model, &QAbstractItemModel::dataChanged, this, &LazyViewBase::onDataChanged),
        connect(m_model, &QAbstractItemModel::modelReset, this, &LazyViewBase::onModelReset),
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

void LazyViewBase::disconnectModel() {
    for (const auto& conn : std::as_const(m_modelConnections))
        disconnect(conn);
    m_modelConnections.clear();
}

void LazyViewBase::resetContent() {
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    m_delegates.clear();
    m_itemToIndex.clear();

    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
    m_dyingDelegates.clear();

    m_knownHeightSum = 0;
    m_knownHeightCount = 0;

    m_layout.clear();
    if (m_model && m_componentComplete) {
        m_layout.resize(m_model->rowCount());
        emit countChanged();
    }

    emit itemsDirtyChanged();
    polish();
}

void LazyViewBase::onRowsInserted(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int insertCount = last - first + 1;
    m_layout.insert(first, insertCount, ItemRecord{ .top = 0, .height = 0, .heightKnown = false, .isNew = true });

    remapDelegates([first, insertCount](int idx) {
        return idx >= first ? idx + insertCount : idx;
    });

    emit countChanged();
    polish();
}

void LazyViewBase::onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    for (int i = first; i <= last; ++i) {
        if (!m_delegates.contains(i))
            continue;

        auto entry = m_delegates.take(i);
        if (entry.item)
            m_itemToIndex.remove(entry.item);
        entry.pendingRemoval = true;

        // Never made visible, skip remove animation
        if (entry.pendingInsert) {
            destroyDelegate(entry);
            continue;
        }

        if (m_removeDuration > 0 && entry.item) {
            delegateRemoving(entry);

            auto* attached = attachedFor(entry.item);
            if (attached)
                attached->setRemoving(true);

            // Schedule destruction after the remove animation duration
            const auto* item = entry.item;
            QTimer::singleShot(m_removeDuration, this, [this, item] {
                for (auto it = m_dyingDelegates.begin(); it != m_dyingDelegates.end(); ++it) {
                    if (it->item == item) {
                        destroyDelegate(*it);
                        m_dyingDelegates.erase(it);
                        polish();
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

void LazyViewBase::onRowsRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int removeCount = last - first + 1;

    for (int i = first; i <= last; ++i) {
        if (m_layout[i].heightKnown)
            untrackHeight(m_layout[i].height);
    }

    m_layout.remove(first, removeCount);

    remapDelegates([last, removeCount](int idx) {
        return idx > last ? idx - removeCount : idx;
    });

    emit countChanged();
    polish();
}

void LazyViewBase::onRowsMoved(const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row) {
    if (parent.isValid() || destination.isValid())
        return;

    const int count = end - start + 1;
    const int dest = row > start ? row - count : row;

    QVector<ItemRecord> moved;
    moved.reserve(count);
    for (int i = start; i <= end; ++i)
        moved.append(m_layout[i]);
    m_layout.remove(start, count);
    for (int i = 0; i < count; ++i)
        m_layout.insert(dest + i, moved[i]);

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

void LazyViewBase::onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles) {
    Q_UNUSED(roles)

    if (topLeft.parent().isValid())
        return;

    for (int i = topLeft.row(); i <= bottomRight.row(); ++i) {
        if (m_delegates.contains(i))
            updateDelegateData(m_delegates[i]);
    }
}

void LazyViewBase::onModelReset() {
    if (!m_model) {
        resetContent();
        return;
    }

    const int newRows = m_model->rowCount();
    const int oldRows = static_cast<int>(m_layout.size());

    // Same rows and data: refresh in place instead of tearing down delegates
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

} // namespace caelestia::shell::components
