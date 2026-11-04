#include "lazylistview.hpp"

#include <algorithm>

namespace caelestia::shell::components {

// --- LazyListViewAttached ---

LazyListViewAttached::LazyListViewAttached(QObject* parent)
    : LazyViewAttached(parent) {}

qreal LazyListViewAttached::visibleHeight() const {
    return m_visibleHeight;
}

void LazyListViewAttached::setVisibleHeight(qreal height) {
    if (qFuzzyCompare(m_visibleHeight + 1.0, height + 1.0))
        return;
    m_visibleHeight = height;
    emit visibleHeightChanged();
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

// --- LazyListView ---

LazyListView::LazyListView(QQuickItem* parent)
    : LazyViewBase(parent) {}

LazyListViewAttached* LazyListView::qmlAttachedProperties(QObject* object) {
    return new LazyListViewAttached(object);
}

LazyListViewAttached* LazyListView::listAttachedFor(QQuickItem* item) {
    return qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
}

LazyViewAttached* LazyListView::attachedFor(QQuickItem* item) const {
    return listAttachedFor(item);
}

LazyViewAttached* LazyListView::attachedForCreate(QQuickItem* item) const {
    return qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, true));
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

// --- Sizing ---

qreal LazyListView::delegateWidth() const {
    return width();
}

qreal LazyListView::visibleHeightOf(QQuickItem* item) const {
    if (!item)
        return 0;

    const auto* attached = listAttachedFor(item);
    if (attached && attached->visibleHeight() >= 0)
        return attached->visibleHeight();

    return delegateHeight(item);
}

// Height as currently rendered, so scrolling follows in-flight animations
qreal LazyListView::visibleHeightAt(int index) const {
    const auto it = m_delegates.find(index);
    if (it != m_delegates.end() && it->item)
        return visibleHeightOf(it->item);
    return layoutHeightAt(index);
}

// Visual position; collapsed rows add no spacing
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

bool LazyListView::isDelegateReady(QQuickItem* item) {
    if (!item)
        return false;
    const auto* attached = listAttachedFor(item);
    return !attached || attached->ready();
}

// --- Layout ---

void LazyListView::relayout() {
    updateLayoutPositions();
    updateContentHeight();
}

// Final positions; collapsed rows add no spacing
void LazyListView::updateLayoutPositions() {
    qreal y = 0;
    bool hasItem = false;
    for (int i = 0; i < static_cast<int>(m_layout.size()); ++i) {
        auto& record = m_layout[i];
        record.top = y;

        const qreal h = layoutHeightAt(i);
        if (h <= 0)
            continue;

        if (hasItem) {
            y += m_spacing;
            record.top = y;
        }
        hasItem = true;
        y += h;
    }

    setLayoutHeight(y);
}

// Content height tracks actual visible heights so scrolling follows animations
void LazyListView::updateContentHeight() {
    const int last = static_cast<int>(m_layout.size()) - 1;
    const qreal visY = last < 0 ? 0 : visualYAt(last) + visibleHeightAt(last);
    setContentHeight(std::max(visY, dyingExtent()));
}

int LazyListView::spanCount() const {
    return static_cast<int>(m_layout.size());
}

qreal LazyListView::spanTop(int span) const {
    return m_layout[span].top;
}

qreal LazyListView::spanHeight(int span) const {
    return layoutHeightAt(span);
}

std::pair<int, int> LazyListView::itemsForSpans(int first, int last) const {
    return { first, last };
}

void LazyListView::viewWidthChanged(qreal newWidth, qreal oldWidth) {
    Q_UNUSED(oldWidth)

    for (const auto& entry : std::as_const(m_delegates)) {
        if (entry.item)
            entry.item->setWidth(newWidth);
    }
}

// --- Delegates ---

void LazyListView::placeCreatedDelegate(DelegateEntry& entry) {
    entry.item->setY(m_layout[entry.modelIndex].top - m_contentY);
    updateLayoutY(entry.item, entry.modelIndex);
}

void LazyListView::positionDelegate(DelegateEntry& entry) {
    const int idx = entry.modelIndex;
    if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
        return;

    if (m_layout[idx].heightKnown && qFuzzyIsNull(m_layout[idx].height))
        return;

    // setProperty so Behaviors fire; setY bypasses them
    entry.item->setProperty("y", m_layout[idx].top - m_contentY);
    updateLayoutY(entry.item, idx);
}

// Publishes the non-animated position so delegates can read it while y animates
void LazyListView::updateLayoutY(QQuickItem* item, int index) {
    auto* attached = listAttachedFor(item);
    if (attached)
        attached->setLayoutY(m_layout[index].top - m_contentY);
}

// Height tracking is deferred until the delegate signals ready
void LazyListView::delegateCreated(DelegateEntry& entry) {
    const auto* attached = listAttachedFor(entry.item);
    if (!attached) {
        LazyViewBase::delegateCreated(entry);
        return;
    }

    auto* item = entry.item;
    connect(attached, &LazyListViewAttached::visibleHeightChanged, this, [this] {
        polish();
    });
    connect(attached, &LazyViewAttached::readyChanged, this, [this, item] {
        onDelegateHeightChanged(item);
    });
}

// Measurements are ignored until the delegate reports itself ready
void LazyListView::onDelegateHeightChanged(QQuickItem* item) {
    if (!isDelegateReady(item))
        return;
    LazyViewBase::onDelegateHeightChanged(item);
}

// Delayed reveals seed y from the visual position so the move animates
void LazyListView::revealDelegate(DelegateEntry& entry, bool delayed) {
    const int idx = entry.modelIndex;
    if (delayed && idx >= 0 && idx < static_cast<int>(m_layout.size()))
        entry.item->setY(visualYAt(idx) - m_contentY);

    LazyViewBase::revealDelegate(entry, delayed);
}

} // namespace caelestia::shell::components
