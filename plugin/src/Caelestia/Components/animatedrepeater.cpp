#include "animatedrepeater.hpp"

#include <qjsvalue.h>
#include <qqmlcontext.h>
#include <qtimer.h>

#include <algorithm>

namespace caelestia::components {

using Qt::StringLiterals::operator""_s;

// --- AnimatedRepeaterAttached ---

AnimatedRepeaterAttached::AnimatedRepeaterAttached(QObject* parent)
    : QObject(parent) {}

bool AnimatedRepeaterAttached::adding() const {
    return m_adding;
}

void AnimatedRepeaterAttached::setAdding(bool adding) {
    if (m_adding == adding)
        return;
    m_adding = adding;
    emit addingChanged();
}

bool AnimatedRepeaterAttached::removing() const {
    return m_removing;
}

void AnimatedRepeaterAttached::setRemoving(bool removing) {
    if (m_removing == removing)
        return;
    m_removing = removing;
    emit removingChanged();
}

// --- AnimatedRepeater ---

AnimatedRepeater::AnimatedRepeater(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents, false);
    // Invisible so positioners and layouts skip the repeater itself
    setVisible(false);
}

AnimatedRepeater::~AnimatedRepeater() {
    for (auto* item : std::as_const(m_items))
        destroyItem(item);
    for (auto* item : std::as_const(m_dyingItems))
        destroyItem(item);
}

AnimatedRepeaterAttached* AnimatedRepeater::qmlAttachedProperties(QObject* object) {
    return new AnimatedRepeaterAttached(object);
}

AnimatedRepeaterAttached* AnimatedRepeater::attachedFor(QQuickItem* item, bool create) {
    return qobject_cast<AnimatedRepeaterAttached*>(qmlAttachedPropertiesObject<AnimatedRepeater>(item, create));
}

// --- Properties ---

QVariant AnimatedRepeater::model() const {
    return m_model;
}

void AnimatedRepeater::setModel(const QVariant& model) {
    QVariant m = model;
    if (m.typeId() == qMetaTypeId<QJSValue>())
        m = m.value<QJSValue>().toVariant();

    if (m_model == m)
        return;

    disconnectModel();
    m_model = m;

    const Mode oldMode = m_mode;
    const int oldCount = m_modelCount;

    m_mode = Mode::None;
    m_itemModel = nullptr;
    m_listData.clear();
    m_modelCount = 0;

    if (auto* obj = m.value<QObject*>()) {
        if (auto* itemModel = qobject_cast<QAbstractItemModel*>(obj)) {
            m_mode = Mode::Model;
            m_itemModel = itemModel;
            connectModel();
        } else {
            // Single object instance acts as a one item model
            m_mode = Mode::List;
            m_listData = { m };
        }
    } else if (m.typeId() != QMetaType::QString && m.typeId() != QMetaType::QVariantList &&
               m.typeId() != QMetaType::QStringList && m.canConvert<int>()) {
        m_mode = Mode::Count;
        m_modelCount = std::max(0, m.toInt());
    } else if (m.canConvert<QVariantList>()) {
        m_mode = Mode::List;
        m_listData = m.toList();
    }

    // Numeric to numeric changes diff instead of rebuilding, so they animate
    if (m_componentComplete && oldMode == Mode::Count && m_mode == Mode::Count) {
        if (m_modelCount > oldCount)
            insertItems(oldCount, m_modelCount - 1, true);
        else if (m_modelCount < oldCount)
            removeItems(m_modelCount, oldCount - 1, true);
    } else {
        regenerate();
    }

    emit modelChanged();
}

QQmlComponent* AnimatedRepeater::delegate() const {
    return m_delegate;
}

void AnimatedRepeater::setDelegate(QQmlComponent* delegate) {
    if (m_delegate == delegate)
        return;

    m_delegate = delegate;
    regenerate();
    emit delegateChanged();
}

int AnimatedRepeater::count() const {
    return modelCount();
}

int AnimatedRepeater::removeDuration() const {
    return m_removeDuration;
}

void AnimatedRepeater::setRemoveDuration(int duration) {
    if (m_removeDuration == duration)
        return;
    m_removeDuration = duration;
    emit removeDurationChanged();
}

QQuickItem* AnimatedRepeater::itemAt(int index) const {
    return m_items.value(index);
}

// --- QQuickItem Overrides ---

void AnimatedRepeater::componentComplete() {
    QQuickItem::componentComplete();
    m_componentComplete = true;
    regenerate();
}

void AnimatedRepeater::itemChange(ItemChange change, const ItemChangeData& data) {
    QQuickItem::itemChange(change, data);

    if (change != ItemParentHasChanged)
        return;

    for (auto* item : std::as_const(m_items)) {
        if (item)
            item->setParentItem(data.item);
    }
    for (auto* item : std::as_const(m_dyingItems))
        item->setParentItem(data.item);

    restack();
}

// --- Model Access ---

int AnimatedRepeater::modelCount() const {
    switch (m_mode) {
    case Mode::Count:
        return m_modelCount;
    case Mode::List:
        return static_cast<int>(m_listData.size());
    case Mode::Model:
        return m_itemModel ? m_itemModel->rowCount() : 0;
    case Mode::None:
        return 0;
    }
    return 0;
}

// Delegate properties for a row, in the order they must be applied: every model
// role, then index, then a modelData fallback for models with no such role.
AnimatedRepeater::PropertyList AnimatedRepeater::itemProperties(int index) const {
    PropertyList props;

    if (m_mode == Mode::Model && m_itemModel) {
        const auto roleNames = m_itemModel->roleNames();
        const auto modelIndex = m_itemModel->index(index, 0);
        bool hasModelData = false;

        props.reserve(roleNames.size() + 2);

        for (auto it = roleNames.constBegin(); it != roleNames.constEnd(); ++it) {
            const auto name = QString::fromUtf8(it.value());
            props.emplaceBack(name, m_itemModel->data(modelIndex, it.key()));
            if (name == u"modelData"_s)
                hasModelData = true;
        }

        props.emplaceBack(u"index"_s, index);

        if (!hasModelData) {
            const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
            props.emplaceBack(u"modelData"_s, m_itemModel->data(modelIndex, role));
        }
    } else {
        props.emplaceBack(u"index"_s, index);
        props.emplaceBack(u"modelData"_s, m_mode == Mode::List ? m_listData.value(index) : QVariant(index));
    }

    return props;
}

void AnimatedRepeater::updateItemData(int index) {
    auto* item = m_items.value(index);
    if (!item)
        return;

    const auto props = itemProperties(index);
    for (const auto& [name, value] : props)
        item->setProperty(name.toUtf8().constData(), value);
}

// --- Item Lifecycle ---

// Full rebuild with no animations, used when the model identity or delegate changes
void AnimatedRepeater::regenerate() {
    clearItems(false);

    if (!m_componentComplete || !m_delegate)
        return;

    const int n = modelCount();
    if (n > 0)
        insertItems(0, n - 1, false);
}

QQuickItem* AnimatedRepeater::createItem(int index, bool adding) {
    if (!m_delegate)
        return nullptr;

    // Use the delegate component's creation context for beginCreate
    // so bound components (pragma ComponentBehavior: Bound) are accepted.
    auto* compContext = m_delegate->creationContext();
    if (!compContext)
        compContext = qmlContext(this);
    if (!compContext)
        return nullptr;

    auto* obj = m_delegate->beginCreate(compContext);
    auto* item = qobject_cast<QQuickItem*>(obj);

    if (!item) {
        if (obj)
            m_delegate->completeCreate();
        delete obj;
        return nullptr;
    }

    const auto props = itemProperties(index);
    QVariantMap initialProps;
    for (const auto& [name, value] : props)
        initialProps.insert(name, value);
    m_delegate->setInitialProperties(item, initialProps);

    // Cleared on the next event loop pass so enter animations trigger
    if (adding) {
        attachedFor(item, true)->setAdding(true);
        m_pendingAdds.append(item);
        scheduleAddFlush();
    }

    item->setParentItem(parentItem());
    m_delegate->completeCreate();

    return item;
}

void AnimatedRepeater::insertItems(int first, int last, bool adding) {
    for (int i = first; i <= last; ++i) {
        // Keep nullptr placeholders so indices stay aligned with the model
        auto* item = createItem(i, adding);
        m_items.insert(i, item);
    }

    updateIndices(last + 1);
    restack();

    for (int i = first; i <= last; ++i) {
        if (m_items[i])
            emit itemAdded(i, m_items[i]);
    }

    emit countChanged();
}

void AnimatedRepeater::removeItems(int first, int last, bool animate) {
    for (int i = last; i >= first; --i) {
        auto* item = m_items[i];
        m_items.remove(i);

        if (!item)
            continue;

        emit itemRemoved(i, item);
        m_pendingAdds.removeOne(item);

        if (animate && m_removeDuration > 0) {
            attachedFor(item, true)->setRemoving(true);
            m_dyingItems.append(item);

            // Schedule destruction after the remove animation duration
            QTimer::singleShot(m_removeDuration, this, [this, item] {
                if (m_dyingItems.removeOne(item))
                    destroyItem(item);
            });
        } else {
            destroyItem(item);
        }
    }

    updateIndices(first);
    emit countChanged();
}

void AnimatedRepeater::clearItems(bool animate) {
    if (!m_items.isEmpty())
        removeItems(0, static_cast<int>(m_items.size()) - 1, animate);
}

void AnimatedRepeater::destroyItem(QQuickItem* item) {
    if (!item)
        return;
    item->setParentItem(nullptr);
    item->setVisible(false);
    item->deleteLater();
}

void AnimatedRepeater::updateIndices(int from) {
    for (int i = from; i < static_cast<int>(m_items.size()); ++i) {
        if (m_items[i])
            m_items[i]->setProperty("index", i);
    }
}

// Keeps delegates in model order within the parent's stacking list,
// ending just before the repeater like a real Repeater.
void AnimatedRepeater::restack() {
    if (!parentItem())
        return;

    const QQuickItem* next = this;
    for (int i = static_cast<int>(m_items.size()) - 1; i >= 0; --i) {
        auto* item = m_items[i];
        if (!item || item->parentItem() != parentItem())
            continue;
        item->stackBefore(next);
        next = item;
    }
}

void AnimatedRepeater::scheduleAddFlush() {
    if (m_addFlushPending)
        return;

    m_addFlushPending = true;
    QTimer::singleShot(0, this, [this] {
        m_addFlushPending = false;
        flushPendingAdds();
    });
}

void AnimatedRepeater::flushPendingAdds() {
    for (auto* item : std::as_const(m_pendingAdds)) {
        if (auto* attached = attachedFor(item))
            attached->setAdding(false);
    }
    m_pendingAdds.clear();
}

// --- Model Connection ---

void AnimatedRepeater::connectModel() {
    if (!m_itemModel)
        return;

    m_modelConnections = {
        connect(m_itemModel, &QAbstractItemModel::rowsInserted, this, &AnimatedRepeater::onRowsInserted),
        connect(
            m_itemModel, &QAbstractItemModel::rowsAboutToBeRemoved, this, &AnimatedRepeater::onRowsAboutToBeRemoved),
        connect(m_itemModel, &QAbstractItemModel::rowsMoved, this, &AnimatedRepeater::onRowsMoved),
        connect(m_itemModel, &QAbstractItemModel::dataChanged, this, &AnimatedRepeater::onDataChanged),
        connect(m_itemModel, &QAbstractItemModel::modelReset, this, &AnimatedRepeater::regenerate),
        connect(m_itemModel, &QAbstractItemModel::layoutChanged, this,
            [this] {
                for (int i = 0; i < static_cast<int>(m_items.size()); ++i)
                    updateItemData(i);
            }),
        connect(m_itemModel, &QObject::destroyed, this,
            [this] {
                m_itemModel = nullptr;
                m_mode = Mode::None;
                m_model.clear();
                m_modelConnections.clear();
                clearItems(false);
                emit modelChanged();
            }),
    };
}

void AnimatedRepeater::disconnectModel() {
    for (auto& conn : m_modelConnections)
        disconnect(conn);
    m_modelConnections.clear();
}

void AnimatedRepeater::onRowsInserted(const QModelIndex& parent, int first, int last) {
    if (parent.isValid() || !m_componentComplete)
        return;
    insertItems(first, last, true);
}

void AnimatedRepeater::onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid() || !m_componentComplete)
        return;
    removeItems(first, last, true);
}

void AnimatedRepeater::onRowsMoved(
    const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row) {
    if (parent.isValid() || destination.isValid() || !m_componentComplete)
        return;

    const int moveCount = end - start + 1;
    const int dest = row > start ? row - moveCount : row;

    QVector<QQuickItem*> moved;
    moved.reserve(moveCount);
    for (int i = start; i <= end; ++i)
        moved.append(m_items[i]);
    m_items.remove(start, moveCount);
    for (int i = 0; i < moveCount; ++i)
        m_items.insert(dest + i, moved[i]);

    updateIndices(std::min(start, dest));
    restack();
}

void AnimatedRepeater::onDataChanged(
    const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles) {
    Q_UNUSED(roles)

    if (topLeft.parent().isValid())
        return;

    for (int i = topLeft.row(); i <= bottomRight.row(); ++i)
        updateItemData(i);
}

} // namespace caelestia::components
