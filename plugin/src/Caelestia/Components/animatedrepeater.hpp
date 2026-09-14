#pragma once

#include <qabstractitemmodel.h>
#include <qqmlcomponent.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qvariant.h>
#include <qvector.h>

#include <utility>

namespace caelestia::components {

class AnimatedRepeaterAttached : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool adding READ adding NOTIFY addingChanged)
    Q_PROPERTY(bool removing READ removing NOTIFY removingChanged)

public:
    explicit AnimatedRepeaterAttached(QObject* parent = nullptr);

    [[nodiscard]] bool adding() const;
    void setAdding(bool adding);

    [[nodiscard]] bool removing() const;
    void setRemoving(bool removing);

signals:
    void addingChanged();
    void removingChanged();

private:
    bool m_adding = false;
    bool m_removing = false;
};

class AnimatedRepeater : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(AnimatedRepeaterAttached)
    Q_CLASSINFO("DefaultProperty", "delegate")

    Q_PROPERTY(QVariant model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QQmlComponent* delegate READ delegate WRITE setDelegate NOTIFY delegateChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int removeDuration READ removeDuration WRITE setRemoveDuration NOTIFY removeDurationChanged)

public:
    explicit AnimatedRepeater(QQuickItem* parent = nullptr);
    ~AnimatedRepeater() override;

    static AnimatedRepeaterAttached* qmlAttachedProperties(QObject* object);

    [[nodiscard]] QVariant model() const;
    void setModel(const QVariant& model);

    [[nodiscard]] QQmlComponent* delegate() const;
    void setDelegate(QQmlComponent* delegate);

    [[nodiscard]] int count() const;

    [[nodiscard]] int removeDuration() const;
    void setRemoveDuration(int duration);

    Q_INVOKABLE [[nodiscard]] QQuickItem* itemAt(int index) const;

signals:
    void modelChanged();
    void delegateChanged();
    void countChanged();
    void removeDurationChanged();
    void itemAdded(int index, QQuickItem* item);
    void itemRemoved(int index, QQuickItem* item);

protected:
    void componentComplete() override;
    void itemChange(ItemChange change, const ItemChangeData& data) override;

private:
    enum class Mode : quint8 {
        None,
        Count,
        List,
        Model
    };

    // Delegate properties in the order they must be applied
    using PropertyList = QList<std::pair<QString, QVariant>>;

    // Attached properties
    [[nodiscard]] static AnimatedRepeaterAttached* attachedFor(QQuickItem* item, bool create = false);

    // Model access
    [[nodiscard]] int modelCount() const;
    [[nodiscard]] PropertyList itemProperties(int index) const;
    void updateItemData(int index);

    // Item lifecycle
    void regenerate();
    [[nodiscard]] QQuickItem* createItem(int index, bool adding);
    void insertItems(int first, int last, bool adding);
    void removeItems(int first, int last, bool animate);
    void clearItems(bool animate);
    static void destroyItem(QQuickItem* item);
    void updateIndices(int from);
    void restack();
    void scheduleAddFlush();
    void flushPendingAdds();

    // Model connection
    void connectModel();
    void disconnectModel();
    void onRowsInserted(const QModelIndex& parent, int first, int last);
    void onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last);
    void onRowsMoved(const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row);
    void onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles);

    QVariant m_model;
    Mode m_mode = Mode::None;
    QAbstractItemModel* m_itemModel = nullptr;
    QVariantList m_listData;
    int m_modelCount = 0;

    QQmlComponent* m_delegate = nullptr;
    int m_removeDuration = 0;

    QVector<QQuickItem*> m_items;
    QVector<QQuickItem*> m_dyingItems;
    QVector<QQuickItem*> m_pendingAdds;

    bool m_componentComplete = false;
    bool m_addFlushPending = false;

    QList<QMetaObject::Connection> m_modelConnections;
};

} // namespace caelestia::components
