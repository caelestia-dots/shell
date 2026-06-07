#include "lazylistview.hpp"

#include <algorithm>
#include <qqmlcontext.h>
#include <qtimer.h>

namespace {

constexpr int ASYNC_BATCH_CREATE = 2;
constexpr int ASYNC_BATCH_DESTROY = 4;

} // namespace

namespace caelestia::components {

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

qreal LazyListView::effectiveEstimatedHeight() const {
    if (m_estimatedHeight >= 0)
        return m_estimatedHeight;
    if (m_knownHeightCount > 0)
        return m_knownHeightSum / m_knownHeightCount;
    return 40;
}

void LazyListView::trackHeight(qreal height) {
    m_knownHeightSum += height;
    ++m_knownHeightCount;
}

void LazyListView::untrackHeight(qreal height) {
    m_knownHeightSum -= height;
    --m_knownHeightCount;
}

qreal LazyListView::delegateHeight(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
    if (attached && attached->preferredHeight() >= 0)
        return attached->preferredHeight();

    return item->implicitHeight();
}

qreal LazyListView::delegateVisibleHeight(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
    if (attached) {
        if (attached->visibleHeight() >= 0)
            return attached->visibleHeight();
        if (attached->preferredHeight() >= 0)
            return attached->preferredHeight();
    }

    return item->implicitHeight();
}

bool LazyListView::isDelegateReady(QQuickItem* item) {
    if (!item)
        return false;
    auto* att = qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
    return !att || att->ready();
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

    // Flush pending inserts — make items visible and clear the adding flag
    // so enter animations begin. When readyDelay > 0 the entire insert is
    // deferred so delegates have time to lay out before appearing.
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

                    // Set initial y to visual position (based on current visible heights)
                    if (idx >= 0 && idx < static_cast<int>(m_layout.size())) {
                        qreal visualY = 0;
                        bool hasVisItem = false;
                        for (int i = 0; i < static_cast<int>(m_layout.size()); ++i) {
                            qreal h;
                            auto dit = m_delegates.find(i);
                            if (dit != m_delegates.end() && dit->item)
                                h = delegateVisibleHeight(dit->item);
                            else
                                h = m_layout[i].heightKnown ? m_layout[i].height : effectiveEstimatedHeight();
                            if (h > 0) {
                                if (hasVisItem)
                                    visualY += m_spacing;
                                hasVisItem = true;
                            }
                            if (i == idx)
                                break;
                            if (h > 0)
                                visualY += h;
                        }
                        item->setY(visualY - m_contentY);
                    }

                    item->setVisible(true);
                    auto* att =
                        qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
                    if (att) {
                        att->setAdding(false);
                        att->setReady(true);
                    }

                    // Animate from visual position to layout position
                    if (idx >= 0 && idx < static_cast<int>(m_layout.size()))
                        item->setProperty("y", m_layout[idx].targetY - m_contentY);

                    polish();
                });
            }
            continue;
        }

        entry.pendingInsert = false;
        entry.item->setVisible(true);
        auto* att = qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(entry.item, false));
        if (att) {
            att->setAdding(false);
            att->setReady(true);
        }
    }

    relayout();
    syncDelegates();

    // Clear isNew flags — the add animation only plays for items created
    // during the same polish cycle as their model insertion, not for
    // delegates created later when scrolling items into the viewport.
    for (auto& record : m_layout)
        record.isNew = false;

    // Position delegates — QML Behavior on y handles the animation
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
    // Layout positioning uses preferredHeight (final/non-animated).
    // Only add spacing between items with non-zero height.
    qreal y = 0;
    bool hasLayoutItem = false;
    for (auto& record : m_layout) {
        const qreal layoutH = record.heightKnown ? record.height : effectiveEstimatedHeight();
        if (layoutH > 0) {
            if (hasLayoutItem)
                y += m_spacing;
            hasLayoutItem = true;
            record.targetY = y;
            y += layoutH;
        } else {
            record.targetY = y;
        }
    }

    if (!qFuzzyCompare(m_layoutHeight + 1.0, y + 1.0)) {
        m_layoutHeight = y;
        emit layoutHeightChanged();
    }

    // Content height tracks actual visible heights so scrolling follows animations.
    // Only add spacing between items with non-zero visible height.
    qreal visY = 0;
    bool hasVisItem = false;
    for (int i = 0; i < static_cast<int>(m_layout.size()); ++i) {
        qreal h;
        auto dit = m_delegates.find(i);
        if (dit != m_delegates.end() && dit->item)
            h = delegateVisibleHeight(dit->item);
        else
            h = m_layout[i].heightKnown ? m_layout[i].height : effectiveEstimatedHeight();
        if (h > 0) {
            if (hasVisItem)
                visY += m_spacing;
            hasVisItem = true;
            visY += h;
        }
    }

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
    if (m_layoutHeight > 0) {
        const qreal top = std::max(vp.y(), 0.0);
        const qreal bottom = std::min(vp.y() + vp.height(), m_layoutHeight);
        if (top < bottom)
            vp = QRectF(vp.x(), top, vp.width(), bottom - top);
        else
            return {};
    }

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

    // Collect delegates to destroy — only if visually outside the viewport
    const auto vp = effectiveViewport();
    QList<int> toRemove;
    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        if (visibleIndices.contains(it.key()))
            continue;
        if (!it->item || vp.isEmpty()) {
            toRemove.append(it.key());
            continue;
        }
        const qreal itemTop = it->item->y();
        const qreal itemBottom = itemTop + delegateVisibleHeight(it->item);
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
            // Height tracking and viewport compensation are deferred
            // until the delegate signals ready via readyChanged.
            entry.pendingInsert = true;
            entry.item->setY(m_layout[i].targetY - m_contentY);
            m_itemToIndex.insert(entry.item, i);
            m_delegates.insert(i, std::move(entry));
            ++created;
        }
    }

    // Pending inserts need to become visible on the next frame, and
    // async mode may have remaining create/destroy work.
    if (created > 0 || (m_asynchronous && (destroyed < static_cast<int>(toRemove.size()) ||
                                              created < static_cast<int>(toCreate.size()))))
        polish();
}

LazyListView::DelegateEntry LazyListView::createDelegate(int modelIndex) {
    DelegateEntry entry;
    entry.modelIndex = modelIndex;

    if (!m_delegate || !m_model)
        return entry;

    const auto roleNames = m_model->roleNames();

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
    entry.item->setWidth(width());

    // Only set adding = true for genuinely new model items (not viewport entries).
    // Cleared on the next frame in updatePolish when the item becomes visible.
    if (modelIndex < static_cast<int>(m_layout.size()) && m_layout[modelIndex].isNew) {
        auto* addingAttached =
            qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(entry.item, true));
        if (addingAttached)
            addingAttached->setAdding(true);
    }

    m_delegate->completeCreate();

    // Keep adding=true and hide — flushed on the next frame in updatePolish
    entry.item->setVisible(false);

    // Height-change handler — uses m_itemToIndex for O(1) lookup.
    // Ignored while the delegate is not yet ready.
    auto onHeightChanged = [this, item = entry.item] {
        if (!isDelegateReady(item))
            return;
        auto indexIt = m_itemToIndex.find(item);
        if (indexIt == m_itemToIndex.end())
            return;
        const int idx = indexIt.value();
        auto delegateIt = m_delegates.find(idx);
        if (delegateIt == m_delegates.end() || delegateIt->item != item)
            return;
        const qreal h = delegateHeight(item);
        if (idx < static_cast<int>(m_layout.size()) && !qFuzzyCompare(m_layout[idx].height + 1.0, h + 1.0)) {
            const qreal oldH = m_layout[idx].height;
            const bool wasKnown = m_layout[idx].heightKnown;
            m_layout[idx].height = h;
            m_layout[idx].heightKnown = true;
            if (wasKnown)
                untrackHeight(oldH);
            trackHeight(h);

            // If this tracked item is above the viewport, emit a
            // compensation delta so the consumer can adjust scroll.
            if (wasKnown) {
                auto* att = qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
                if (att && att->trackViewport()) {
                    const qreal vpTop = m_useCustomViewport ? m_viewport.y() : m_contentY;
                    if (m_layout[idx].targetY < vpTop)
                        emit viewportAdjustNeeded(h - oldH);
                }
            }

            if (!m_relayoutPending) {
                m_relayoutPending = true;
                QTimer::singleShot(0, this, [this] {
                    m_relayoutPending = false;
                    relayout();
                    polish();
                });
            }
        }
    };

    // Watch implicitHeight as fallback
    connect(entry.item, &QQuickItem::implicitHeightChanged, this, onHeightChanged);

    // Watch attached properties if the delegate uses them
    auto* attached = qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(entry.item, false));
    if (attached) {
        connect(attached, &LazyListViewAttached::preferredHeightChanged, this, onHeightChanged);
        connect(attached, &LazyListViewAttached::visibleHeightChanged, this, [this] {
            polish();
        });
        connect(attached, &LazyListViewAttached::readyChanged, this, [this, item = entry.item] {
            auto indexIt = m_itemToIndex.find(item);
            if (indexIt == m_itemToIndex.end())
                return;
            const int idx = indexIt.value();
            if (idx >= static_cast<int>(m_layout.size()))
                return;
            auto* att = qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
            if (!att || !att->ready())
                return;

            const qreal h = delegateHeight(item);
            const qreal oldLayoutH = m_layout[idx].heightKnown ? m_layout[idx].height : effectiveEstimatedHeight();
            if (m_layout[idx].heightKnown)
                untrackHeight(m_layout[idx].height);
            m_layout[idx].height = h;
            m_layout[idx].heightKnown = true;
            trackHeight(h);

            if (att->trackViewport() && !qFuzzyCompare(h + 1.0, oldLayoutH + 1.0)) {
                const qreal vpTop = m_useCustomViewport ? m_viewport.y() : m_contentY;
                if (m_layout[idx].targetY < vpTop)
                    emit viewportAdjustNeeded(h - oldLayoutH);
            }

            polish();
        });
    }

    return entry;
}

void LazyListView::destroyDelegate(DelegateEntry& entry) {
    if (entry.item) {
        entry.item->setParentItem(nullptr);
        entry.item->setVisible(false);
        entry.item->deleteLater();
        entry.item = nullptr;
    }
}

void LazyListView::updateDelegateData(DelegateEntry& entry) {
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
        const int rows = m_model->rowCount();
        m_layout.resize(rows);
        for (int i = 0; i < rows; ++i) {
            m_layout[i].height = 0;
            m_layout[i].heightKnown = false;
        }
        emit countChanged();
    }

    polish();
}

void LazyListView::onRowsInserted(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int insertCount = last - first + 1;
    // Insert new layout records
    m_layout.insert(first, insertCount, ItemRecord{ 0, 0, false, true });

    // Shift existing delegate indices
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
            auto* attached =
                qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(entry.item, false));
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
