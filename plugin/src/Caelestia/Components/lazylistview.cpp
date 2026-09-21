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

// Clip a rect horizontally to [left, right], empty if there is no overlap
QRectF clipHorizontal(const QRectF& rect, qreal left, qreal right) {
    const qreal newLeft = std::max(rect.x(), left);
    const qreal newRight = std::min(rect.x() + rect.width(), right);
    if (newLeft >= newRight)
        return {};
    return { newLeft, rect.y(), newRight - newLeft, rect.height() };
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

qreal LazyListViewAttached::preferredWidth() const {
    return m_preferredWidth;
}

void LazyListViewAttached::setPreferredWidth(qreal width) {
    if (qFuzzyCompare(m_preferredWidth + 1.0, width + 1.0))
        return;
    m_preferredWidth = width;
    emit preferredWidthChanged();
}

qreal LazyListViewAttached::visibleWidth() const {
    return m_visibleWidth;
}

void LazyListViewAttached::setVisibleWidth(qreal width) {
    if (qFuzzyCompare(m_visibleWidth + 1.0, width + 1.0))
        return;
    m_visibleWidth = width;
    emit visibleWidthChanged();
}

qreal LazyListViewAttached::layoutY() const {
    return m_layoutY;
}

void LazyListViewAttached::setLayoutY(qreal y) {
    if (qFuzzyCompare(m_layoutY + 1.0, y + 1.0))
        return;
    m_layoutY = y;
    emit layoutYChanged();
}

qreal LazyListViewAttached::layoutX() const {
    return m_layoutX;
}

void LazyListViewAttached::setLayoutX(qreal x) {
    if (qFuzzyCompare(m_layoutX + 1.0, x + 1.0))
        return;
    m_layoutX = x;
    emit layoutXChanged();
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

LazyListView::Orientation LazyListView::orientation() const {
    return m_orientation;
}

void LazyListView::setOrientation(Orientation orientation) {
    if (orientation == m_orientation)
        return;
    if (orientation != Orientation::Vertical && orientation != Orientation::Horizontal)
        return;
    m_orientation = orientation;
    emit orientationChanged();
    resetContent();
}

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

qreal LazyListView::contentWidth() const {
    return m_contentWidth;
}

qreal LazyListView::layoutWidth() const {
    return m_layoutWidth;
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

qreal LazyListView::contentX() const {
    return m_contentX;
}

void LazyListView::setContentX(qreal contentX) {
    if (qFuzzyCompare(m_contentX, contentX))
        return;
    m_contentX = contentX;
    emit contentXChanged();
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

bool LazyListView::cullDelegates() const {
    return m_cullDelegates;
}

void LazyListView::setCullDelegates(bool cull) {
    if (m_cullDelegates == cull)
        return;
    m_cullDelegates = cull;
    emit cullDelegatesChanged();
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

qreal LazyListView::effectiveEstimatedMain() const {
    if (m_estimatedHeight >= 0)
        return m_estimatedHeight;
    if (m_knownMainCount > 0)
        return m_knownMainSum / m_knownMainCount;
    return k_fallbackHeight;
}

qreal LazyListView::layoutMainAt(int index) const {
    const auto& record = m_layout[index];
    return record.mainKnown ? record.mainLength : effectiveEstimatedMain();
}

qreal LazyListView::visibleMainAt(int index) const {
    const auto it = m_delegates.find(index);
    if (it != m_delegates.end() && it->item)
        return visibleMainLength(it->item);
    return layoutMainAt(index);
}

qreal LazyListView::visualMainAt(int index) const {
    qreal pos = 0;
    bool hasItem = false;
    for (int i = 0; i < index; ++i) {
        const qreal len = visibleMainAt(i);
        if (len <= 0)
            continue;
        if (hasItem)
            pos += m_spacing;
        hasItem = true;
        pos += len;
    }
    if (hasItem && visibleMainAt(index) > 0)
        pos += m_spacing;
    return pos;
}

qreal LazyListView::layoutMainTotal() const {
    return m_orientation == Orientation::Horizontal ? m_layoutWidth : m_layoutHeight;
}

qreal LazyListView::contentMain() const {
    return m_orientation == Orientation::Horizontal ? m_contentX : m_contentY;
}

qreal LazyListView::mainCoordOf(QQuickItem* item) const {
    return m_orientation == Orientation::Horizontal ? item->x() : item->y();
}

qreal LazyListView::viewportTop() const {
    return m_useCustomViewport ? m_viewport.y() : m_contentY;
}

qreal LazyListView::viewportLeft() const {
    return m_useCustomViewport ? m_viewport.x() : m_contentX;
}

void LazyListView::trackMain(qreal length) {
    m_knownMainSum += length;
    ++m_knownMainCount;
}

void LazyListView::untrackMain(qreal length) {
    m_knownMainSum -= length;
    --m_knownMainCount;
}

LazyListView::HeightUpdate LazyListView::setKnownMain(int index, qreal length) {
    auto& record = m_layout[index];
    const HeightUpdate previous{ .previousLength = layoutMainAt(index), .wasKnown = record.mainKnown };

    if (record.mainKnown)
        untrackMain(record.mainLength);
    record.mainLength = length;
    record.mainKnown = true;
    trackMain(length);

    return previous;
}

void LazyListView::adjustViewportIfAbove(int index, QQuickItem* item, qreal delta) {
    auto* attached = attachedFor(item);
    if (attached && attached->trackViewport() &&
        m_layout[index].mainPos < (m_orientation == Orientation::Horizontal ? viewportLeft() : viewportTop()))
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

qreal LazyListView::delegateWidth(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = attachedFor(item);
    if (attached && attached->preferredWidth() >= 0)
        return attached->preferredWidth();

    return item->implicitWidth();
}

qreal LazyListView::delegateVisibleWidth(QQuickItem* item) {
    if (!item)
        return 0;

    auto* attached = attachedFor(item);
    if (attached && attached->visibleWidth() >= 0)
        return attached->visibleWidth();

    return delegateWidth(item);
}

qreal LazyListView::mainLength(QQuickItem* item) const {
    return m_orientation == Orientation::Horizontal ? delegateWidth(item) : delegateHeight(item);
}

qreal LazyListView::visibleMainLength(QQuickItem* item) const {
    return m_orientation == Orientation::Horizontal ? delegateVisibleWidth(item) : delegateVisibleHeight(item);
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

// Always false; bind through it to re-run itemAtIndex/itemAt on mapping changes
bool LazyListView::itemsDirty() {
    return false;
}

// Instantiated delegate for a model index, nullptr if outside the cache
QQuickItem* LazyListView::itemAtIndex(int index) const {
    return m_delegates.value(index).item;
}

// Hit test against instantiated delegates at their current visual positions
QQuickItem* LazyListView::itemAt(qreal x, qreal y) const {
    if (x < 0 || y < 0)
        return nullptr;

    if (m_orientation == Orientation::Horizontal) {
        if (y >= height())
            return nullptr;
    } else if (x >= width()) {
        return nullptr;
    }

    const auto children = childItems();
    for (auto* const item : children | std::views::reverse) {
        if (!m_itemToIndex.contains(item) || !item->isVisible())
            continue;

        const auto start = m_orientation == Orientation::Horizontal ? item->x() + m_contentX : item->y() + m_contentY;
        const auto end = start + visibleMainLength(item);

        if (m_orientation == Orientation::Horizontal ? (x >= start && x < end) : (y >= start && y < end))
            return item;
    }

    return nullptr;
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

    if (m_orientation == Orientation::Horizontal) {
        if (!qFuzzyCompare(newGeometry.height(), oldGeometry.height())) {
            for (auto& entry : m_delegates) {
                if (entry.item)
                    entry.item->setHeight(newGeometry.height());
            }
        }
    } else {
        if (!qFuzzyCompare(newGeometry.width(), oldGeometry.width())) {
            for (auto& entry : m_delegates) {
                if (entry.item)
                    entry.item->setWidth(newGeometry.width());
            }
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

    if (idx < static_cast<int>(m_layout.size())) {
        const qreal target = visualMainAt(idx) - contentMain();
        if (m_orientation == Orientation::Horizontal)
            item->setX(target);
        else
            item->setY(target);
    }

    revealDelegate(item);

    // Re-check the bounds: revealing runs QML bindings and onReady handlers,
    // which may have mutated the model out from under us.
    if (idx < static_cast<int>(m_layout.size())) {
        const qreal target = m_layout[idx].mainPos - contentMain();
        const char* prop = m_orientation == Orientation::Horizontal ? "x" : "y";
        item->setProperty(prop, target); // animate to layout position
        publishLayoutOffset(item, idx);
    }

    polish();
}

void LazyListView::positionDelegates() {
    for (auto& entry : m_delegates) {
        if (!entry.item || entry.pendingRemoval || entry.pendingInsert)
            continue;

        const int idx = entry.modelIndex;
        if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
            continue;

        if (m_layout[idx].mainKnown && qFuzzyIsNull(m_layout[idx].mainLength))
            continue;

        // Use setProperty to go through the QML property system,
        // which triggers Behaviors (setY/setX bypasses them).
        const qreal target = m_layout[idx].mainPos - contentMain();
        const char* prop = m_orientation == Orientation::Horizontal ? "x" : "y";
        entry.item->setProperty(prop, target);
        publishLayoutOffset(entry.item, idx);
    }
}

// Publishes the non-animated position so delegates can read it while the
// main-axis property animates
void LazyListView::publishLayoutOffset(QQuickItem* item, int index) {
    auto* attached = attachedFor(item);
    if (attached) {
        const qreal offset = m_layout[index].mainPos - contentMain();
        if (m_orientation == Orientation::Horizontal)
            attached->setLayoutX(offset);
        else
            attached->setLayoutY(offset);
    }
}

// --- Layout Engine ---

void LazyListView::relayout() {
    updateLayoutPositions();
    updateContentHeight();
}

// Layout positioning uses mainLength (final/non-animated).
// Only adds spacing between items with non-zero main length.
void LazyListView::updateLayoutPositions() {
    qreal pos = 0;
    bool hasItem = false;
    for (int i = 0; i < static_cast<int>(m_layout.size()); ++i) {
        auto& record = m_layout[i];
        record.mainPos = pos;

        const qreal len = layoutMainAt(i);
        if (len <= 0)
            continue;

        if (hasItem) {
            pos += m_spacing;
            record.mainPos = pos;
        }
        hasItem = true;
        pos += len;
    }

    if (m_orientation == Orientation::Horizontal) {
        if (!qFuzzyCompare(m_layoutWidth + 1.0, pos + 1.0)) {
            m_layoutWidth = pos;
            emit layoutWidthChanged();
        }
        if (!qFuzzyCompare(m_layoutHeight + 1.0, height() + 1.0)) {
            m_layoutHeight = height();
            emit layoutHeightChanged();
        }
    } else {
        if (!qFuzzyCompare(m_layoutHeight + 1.0, pos + 1.0)) {
            m_layoutHeight = pos;
            emit layoutHeightChanged();
        }
        if (!qFuzzyCompare(m_layoutWidth + 1.0, width() + 1.0)) {
            m_layoutWidth = width();
            emit layoutWidthChanged();
        }
    }
}

// Content height tracks actual visible heights so scrolling follows animations
void LazyListView::updateContentHeight() {
    const int last = static_cast<int>(m_layout.size()) - 1;
    qreal visPos = last < 0 ? 0 : visualMainAt(last) + visibleMainAt(last);

    // Account for dying delegates still visually present
    for (const auto& dying : std::as_const(m_dyingDelegates)) {
        if (!dying.item)
            continue;
        const qreal dyingLen = visibleMainLength(dying.item);
        if (dyingLen > 0)
            visPos = std::max(visPos, mainCoordOf(dying.item) + dyingLen);
    }

    if (m_orientation == Orientation::Horizontal) {
        if (!qFuzzyCompare(m_contentWidth + 1.0, visPos + 1.0)) {
            m_contentWidth = visPos;
            emit contentWidthChanged();
        }
        if (!qFuzzyCompare(m_contentHeight + 1.0, height() + 1.0)) {
            m_contentHeight = height();
            emit contentHeightChanged();
        }
    } else {
        if (!qFuzzyCompare(m_contentHeight + 1.0, visPos + 1.0)) {
            m_contentHeight = visPos;
            emit contentHeightChanged();
        }
        if (!qFuzzyCompare(m_contentWidth + 1.0, width() + 1.0)) {
            m_contentWidth = width();
            emit contentWidthChanged();
        }
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
    else if (m_orientation == Orientation::Horizontal)
        vp = QRectF(m_contentX, 0, width(), height());
    else
        vp = QRectF(0, m_contentY, width(), height());

    // During Flickable overshoot the viewport can extend entirely beyond content bounds,
    // causing all delegates to be culled. Clamp so it always overlaps [0, layoutMain].
    // Only needed for the built-in viewport — custom viewports represent the actual
    // visible area and may legitimately lie entirely outside the content.
    const qreal total = layoutMainTotal();
    if (!m_useCustomViewport && total > 0) {
        if (m_orientation == Orientation::Horizontal) {
            const qreal left = std::min(vp.x(), total);
            const qreal right = std::max(vp.x() + vp.width(), 0.0);
            if (right > left)
                vp = QRectF(left, vp.y(), right - left, vp.height());
        } else {
            const qreal top = std::min(vp.y(), total);
            const qreal bottom = std::max(vp.y() + vp.height(), 0.0);
            if (bottom > top)
                vp = QRectF(vp.x(), top, vp.width(), bottom - top);
        }
    }

    if (m_orientation == Orientation::Horizontal)
        vp = QRectF(vp.x() - m_cacheBuffer, vp.y(), vp.width() + m_cacheBuffer * 2, vp.height());
    else
        vp.adjust(0, -m_cacheBuffer, 0, m_cacheBuffer);

    // Trim the cache-buffered viewport to [0, layoutMain]. No items exist outside
    // those bounds, so extending past them wastes budget and can cause edge thrashing
    // when a large cache buffer reaches the opposite end of the content.
    if (total > 0) {
        if (m_orientation == Orientation::Horizontal)
            return clipHorizontal(vp, 0, total);
        return clipVertical(vp, 0, total);
    }

    return vp;
}

std::pair<int, int> LazyListView::computeVisibleRange() const {
    if (m_layout.isEmpty())
        return { -1, -1 };

    // Culling disabled: keep every delegate alive
    if (!m_cullDelegates)
        return { 0, static_cast<int>(m_layout.size()) - 1 };

    const auto vp = effectiveViewport();
    if (vp.isEmpty())
        return { -1, -1 };

    const bool horiz = m_orientation == Orientation::Horizontal;
    const qreal vpStart = horiz ? vp.x() : vp.y();
    const qreal vpEnd = horiz ? vp.x() + vp.width() : vp.y() + vp.height();

    // Binary search for first visible item
    int lo = 0;
    int hi = static_cast<int>(m_layout.size()) - 1;
    int first = static_cast<int>(m_layout.size());

    while (lo <= hi) {
        const int mid = lo + (hi - lo) / 2;
        const auto& record = m_layout[mid];
        const qreal itemEnd = record.mainPos + (record.mainKnown ? record.mainLength : effectiveEstimatedMain());

        if (itemEnd >= vpStart) {
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
        if (m_layout[i].mainPos > vpEnd)
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

    if (created > 0 || destroyed > 0)
        emit itemsDirtyChanged();
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

        const qreal itemStart = mainCoordOf(it->item);
        const qreal itemEnd = itemStart + visibleMainLength(it->item);
        const qreal vpStart = m_orientation == Orientation::Horizontal ? viewport.left() : viewport.top();
        const qreal vpEnd = m_orientation == Orientation::Horizontal ? viewport.right() : viewport.bottom();
        if (itemEnd < vpStart || itemStart > vpEnd)
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

        // Content tracking and viewport compensation are deferred
        // until the delegate signals ready via readyChanged.
        entry.pendingInsert = true;
        const qreal target = m_layout[idx].mainPos - contentMain();
        if (m_orientation == Orientation::Horizontal)
            entry.item->setX(target);
        else
            entry.item->setY(target);
        publishLayoutOffset(entry.item, idx);
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
    if (m_orientation == Orientation::Horizontal)
        entry.item->setHeight(height());
    else
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

    // Watch implicit sizes as fallback
    connect(item, &QQuickItem::implicitHeightChanged, this, [this, item] {
        onDelegateMainChanged(item);
    });
    connect(item, &QQuickItem::implicitWidthChanged, this, [this, item] {
        onDelegateMainChanged(item);
    });

    // Watch attached properties if the delegate uses them
    auto* attached = attachedFor(item);
    if (!attached)
        return;

    connect(attached, &LazyListViewAttached::preferredHeightChanged, this, [this, item] {
        onDelegateMainChanged(item);
    });
    connect(attached, &LazyListViewAttached::preferredWidthChanged, this, [this, item] {
        onDelegateMainChanged(item);
    });
    connect(attached, &LazyListViewAttached::visibleHeightChanged, this, [this] {
        polish();
    });
    connect(attached, &LazyListViewAttached::visibleWidthChanged, this, [this] {
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

// Re-measures a delegate whose main length changed after it became ready
void LazyListView::onDelegateMainChanged(QQuickItem* item) {
    if (!isDelegateReady(item))
        return;

    const int idx = indexOfDelegate(item);
    if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
        return;

    const qreal len = mainLength(item);
    if (qFuzzyCompare(m_layout[idx].mainLength + 1.0, len + 1.0))
        return;

    const auto previous = setKnownMain(idx, len);
    if (previous.wasKnown)
        adjustViewportIfAbove(idx, item, len - previous.previousLength);

    scheduleRelayout();
}

// Takes the first real measurement once a delegate reports itself ready
void LazyListView::onDelegateReady(QQuickItem* item) {
    if (!isDelegateReady(item))
        return;

    const int idx = indexOfDelegate(item);
    if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
        return;

    const qreal len = mainLength(item);
    const auto previous = setKnownMain(idx, len);
    if (!qFuzzyCompare(len + 1.0, previous.previousLength + 1.0))
        adjustViewportIfAbove(idx, item, len - previous.previousLength);

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
    emit itemsDirtyChanged();
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
    m_knownMainSum = 0;
    m_knownMainCount = 0;
    m_contentWidth = 0;
    m_layoutWidth = 0;

    // Rebuild layout from model
    m_layout.clear();
    if (m_model && m_componentComplete) {
        m_layout.resize(m_model->rowCount());
        emit countChanged();
    }

    emit itemsDirtyChanged();
    polish();
}

void LazyListView::onRowsInserted(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int insertCount = last - first + 1;
    // Insert new layout records
    m_layout.insert(first, insertCount, ItemRecord{ .mainPos = 0, .mainLength = 0, .mainKnown = false, .isNew = true });

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

    // Untrack known main lengths being removed
    for (int i = first; i <= last; ++i) {
        if (m_layout[i].mainKnown)
            untrackMain(m_layout[i].mainLength);
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
