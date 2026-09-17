#pragma once

#include <qabstractitemmodel.h>
#include <qhash.h>
#include <qobject.h>
#include <qqmlcomponent.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qrect.h>
#include <qset.h>
#include <qvariant.h>
#include <qvector.h>

#include <functional>
#include <utility>

namespace caelestia::components {

class LazyListViewAttached : public QObject {
    Q_OBJECT

    Q_PROPERTY(qreal preferredHeight READ preferredHeight WRITE setPreferredHeight NOTIFY preferredHeightChanged)
    Q_PROPERTY(qreal visibleHeight READ visibleHeight WRITE setVisibleHeight NOTIFY visibleHeightChanged)
    Q_PROPERTY(qreal preferredWidth READ preferredWidth WRITE setPreferredWidth NOTIFY preferredWidthChanged)
    Q_PROPERTY(qreal visibleWidth READ visibleWidth WRITE setVisibleWidth NOTIFY visibleWidthChanged)
    Q_PROPERTY(qreal layoutY READ layoutY NOTIFY layoutYChanged)
    Q_PROPERTY(qreal layoutX READ layoutX NOTIFY layoutXChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(bool adding READ adding NOTIFY addingChanged)
    Q_PROPERTY(bool removing READ removing NOTIFY removingChanged)
    Q_PROPERTY(bool trackViewport READ trackViewport WRITE setTrackViewport NOTIFY trackViewportChanged)

public:
    explicit LazyListViewAttached(QObject* parent = nullptr);

    [[nodiscard]] qreal preferredHeight() const;
    void setPreferredHeight(qreal height);

    [[nodiscard]] qreal visibleHeight() const;
    void setVisibleHeight(qreal height);

    [[nodiscard]] qreal preferredWidth() const;
    void setPreferredWidth(qreal width);

    [[nodiscard]] qreal visibleWidth() const;
    void setVisibleWidth(qreal width);

    [[nodiscard]] qreal layoutY() const;
    void setLayoutY(qreal y);

    [[nodiscard]] qreal layoutX() const;
    void setLayoutX(qreal x);

    [[nodiscard]] bool ready() const;
    void setReady(bool ready);

    [[nodiscard]] bool adding() const;
    void setAdding(bool adding);

    [[nodiscard]] bool removing() const;
    void setRemoving(bool removing);

    [[nodiscard]] bool trackViewport() const;
    void setTrackViewport(bool track);

signals:
    void preferredHeightChanged();
    void visibleHeightChanged();
    void preferredWidthChanged();
    void visibleWidthChanged();
    void layoutYChanged();
    void layoutXChanged();
    void readyChanged();
    void addingChanged();
    void removingChanged();
    void trackViewportChanged();

private:
    qreal m_preferredHeight = -1;
    qreal m_visibleHeight = -1;
    qreal m_preferredWidth = -1;
    qreal m_visibleWidth = -1;
    qreal m_layoutY = 0;
    qreal m_layoutX = 0;
    bool m_ready = false;
    bool m_adding = false;
    bool m_removing = false;
    bool m_trackViewport = false;
};

class LazyListView : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(LazyListViewAttached)

public:
    enum Orientation { Vertical, Horizontal };
    Q_ENUM(Orientation)

    // Model & Delegate
    Q_PROPERTY(QAbstractItemModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QQmlComponent* delegate READ delegate WRITE setDelegate NOTIFY delegateChanged)

    // Layout
    Q_PROPERTY(int orientation READ orientation WRITE setOrientation NOTIFY orientationChanged)
    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    Q_PROPERTY(qreal contentHeight READ contentHeight NOTIFY contentHeightChanged)
    Q_PROPERTY(qreal layoutHeight READ layoutHeight NOTIFY layoutHeightChanged)
    Q_PROPERTY(qreal contentWidth READ contentWidth NOTIFY contentWidthChanged)
    Q_PROPERTY(qreal layoutWidth READ layoutWidth NOTIFY layoutWidthChanged)
    Q_PROPERTY(qreal contentY READ contentY WRITE setContentY NOTIFY contentYChanged)
    Q_PROPERTY(qreal contentX READ contentX WRITE setContentX NOTIFY contentXChanged)

    // Viewport & Lazy Loading
    Q_PROPERTY(QRectF viewport READ viewport WRITE setViewport NOTIFY viewportChanged)
    Q_PROPERTY(bool useCustomViewport READ useCustomViewport WRITE setUseCustomViewport NOTIFY useCustomViewportChanged)
    Q_PROPERTY(qreal cacheBuffer READ cacheBuffer WRITE setCacheBuffer NOTIFY cacheBufferChanged)
    Q_PROPERTY(bool cullDelegates READ cullDelegates WRITE setCullDelegates NOTIFY cullDelegatesChanged)

    // Sizing
    Q_PROPERTY(qreal estimatedHeight READ estimatedHeight WRITE setEstimatedHeight NOTIFY estimatedHeightChanged)

    // Async
    Q_PROPERTY(bool asynchronous READ asynchronous WRITE setAsynchronous NOTIFY asynchronousChanged)

    // Animation Durations
    Q_PROPERTY(int removeDuration READ removeDuration WRITE setRemoveDuration NOTIFY removeDurationChanged)
    Q_PROPERTY(int readyDelay READ readyDelay WRITE setReadyDelay NOTIFY readyDelayChanged)

    // State
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    // Always false; its notify fires when the index to item mapping changes
    Q_PROPERTY(bool itemsDirty READ itemsDirty NOTIFY itemsDirtyChanged)

public:
    explicit LazyListView(QQuickItem* parent = nullptr);
    ~LazyListView() override;

    static LazyListViewAttached* qmlAttachedProperties(QObject* object);

    // Model & Delegate
    [[nodiscard]] QAbstractItemModel* model() const;
    void setModel(QAbstractItemModel* model);

    [[nodiscard]] QQmlComponent* delegate() const;
    void setDelegate(QQmlComponent* delegate);

    // Layout
    [[nodiscard]] int orientation() const;
    void setOrientation(int orientation);

    [[nodiscard]] qreal spacing() const;
    void setSpacing(qreal spacing);

    [[nodiscard]] qreal contentHeight() const;
    [[nodiscard]] qreal layoutHeight() const;

    [[nodiscard]] qreal contentWidth() const;
    [[nodiscard]] qreal layoutWidth() const;

    [[nodiscard]] qreal contentY() const;
    void setContentY(qreal contentY);

    [[nodiscard]] qreal contentX() const;
    void setContentX(qreal contentX);

    // Viewport
    [[nodiscard]] QRectF viewport() const;
    void setViewport(const QRectF& viewport);

    [[nodiscard]] bool useCustomViewport() const;
    void setUseCustomViewport(bool use);

    [[nodiscard]] qreal cacheBuffer() const;
    void setCacheBuffer(qreal buffer);

    [[nodiscard]] bool cullDelegates() const;
    void setCullDelegates(bool cull);

    // Sizing
    [[nodiscard]] qreal estimatedHeight() const;
    void setEstimatedHeight(qreal height);

    // Async
    [[nodiscard]] bool asynchronous() const;
    void setAsynchronous(bool async);

    // Animation Durations
    [[nodiscard]] int removeDuration() const;
    void setRemoveDuration(int duration);

    [[nodiscard]] int readyDelay() const;
    void setReadyDelay(int delay);

    // State
    [[nodiscard]] int count() const;
    [[nodiscard]] static bool itemsDirty();

    Q_INVOKABLE [[nodiscard]] QQuickItem* itemAtIndex(int index) const;
    Q_INVOKABLE [[nodiscard]] QQuickItem* itemAt(qreal x, qreal y) const;

signals:
    void modelChanged();
    void delegateChanged();
    void orientationChanged();
    void spacingChanged();
    void contentHeightChanged();
    void layoutHeightChanged();
    void contentWidthChanged();
    void layoutWidthChanged();
    void contentYChanged();
    void contentXChanged();
    void viewportChanged();
    void useCustomViewportChanged();
    void cacheBufferChanged();
    void cullDelegatesChanged();
    void estimatedHeightChanged();
    void asynchronousChanged();
    void removeDurationChanged();
    void readyDelayChanged();
    void countChanged();
    void itemsDirtyChanged();
    void viewportAdjustNeeded(qreal delta);

protected:
    void componentComplete() override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void updatePolish() override;

private:
    struct ItemRecord {
        qreal mainPos = 0;
        qreal mainLength = 0;
        bool mainKnown = false;
        bool isNew = false;
    };

    struct DelegateEntry {
        int modelIndex = -1;
        QQuickItem* item = nullptr;
        bool pendingRemoval = false;
        bool pendingInsert = false;
        bool readyDelayStarted = false;
    };

    // Delegate properties in the order they must be applied
    using PropertyList = QList<std::pair<QString, QVariant>>;

    // Result of recording a measured delegate main length
    struct HeightUpdate {
        qreal previousLength = 0;
        bool wasKnown = false;
    };

    // Attached properties
    [[nodiscard]] static LazyListViewAttached* attachedFor(QQuickItem* item);
    [[nodiscard]] static LazyListViewAttached* attachedForCreate(QQuickItem* item);

    // Layout
    void relayout();
    void updateLayoutPositions();
    void updateContentHeight();
    void scheduleRelayout();
    [[nodiscard]] std::pair<int, int> computeVisibleRange() const;
    [[nodiscard]] QRectF effectiveViewport() const;
    [[nodiscard]] qreal viewportTop() const;
    [[nodiscard]] qreal viewportLeft() const;
    [[nodiscard]] qreal effectiveEstimatedMain() const;
    [[nodiscard]] qreal layoutMainAt(int index) const;
    [[nodiscard]] qreal visibleMainAt(int index) const;
    [[nodiscard]] qreal visualMainAt(int index) const;
    [[nodiscard]] qreal layoutMainTotal() const;
    [[nodiscard]] qreal contentMain() const;
    [[nodiscard]] qreal mainCoordOf(QQuickItem* item) const;
    [[nodiscard]] static qreal delegateHeight(QQuickItem* item);
    [[nodiscard]] static qreal delegateVisibleHeight(QQuickItem* item);
    [[nodiscard]] static qreal delegateWidth(QQuickItem* item);
    [[nodiscard]] static qreal delegateVisibleWidth(QQuickItem* item);
    [[nodiscard]] qreal mainLength(QQuickItem* item) const;
    [[nodiscard]] qreal visibleMainLength(QQuickItem* item) const;
    [[nodiscard]] static bool isDelegateReady(QQuickItem* item);
    void trackMain(qreal length);
    void untrackMain(qreal length);
    HeightUpdate setKnownMain(int index, qreal length);
    void adjustViewportIfAbove(int index, QQuickItem* item, qreal delta);

    // Delegate lifecycle
    void syncDelegates();
    [[nodiscard]] QList<int> delegatesOutsideViewport(const QSet<int>& keep, const QRectF& viewport) const;
    [[nodiscard]] QList<int> missingDelegates(int first, int last) const;
    int destroyDelegates(const QList<int>& indices, int budget);
    int createDelegates(const QList<int>& indices, int budget);
    DelegateEntry createDelegate(int modelIndex);
    void connectDelegate(const DelegateEntry& entry);
    [[nodiscard]] int indexOfDelegate(QQuickItem* item) const;
    void onDelegateMainChanged(QQuickItem* item);
    void onDelegateReady(QQuickItem* item);
    static void destroyDelegate(DelegateEntry& entry);
    static void revealDelegate(QQuickItem* item);
    void flushPendingInserts();
    void finishDelayedInsert(QQuickItem* item);
    void positionDelegates();
    void publishLayoutOffset(QQuickItem* item, int index);
    [[nodiscard]] PropertyList delegateProperties(int modelIndex) const;
    void updateDelegateData(DelegateEntry& entry);
    void remapDelegates(const std::function<int(int)>& mapIndex);

    // Model connection
    void connectModel();
    void disconnectModel();
    void resetContent();
    void onRowsInserted(const QModelIndex& parent, int first, int last);
    void onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last);
    void onRowsRemoved(const QModelIndex& parent, int first, int last);
    void onRowsMoved(const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row);
    void onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles);
    void onModelReset();

    // Members
    QAbstractItemModel* m_model = nullptr;
    QQmlComponent* m_delegate = nullptr;

    Orientation m_orientation = Vertical;
    qreal m_spacing = 0;
    qreal m_contentHeight = 0;
    qreal m_layoutHeight = 0;
    qreal m_contentWidth = 0;
    qreal m_layoutWidth = 0;
    qreal m_contentY = 0;
    qreal m_contentX = 0;

    QRectF m_viewport;
    bool m_useCustomViewport = false;
    qreal m_cacheBuffer = 0;
    bool m_cullDelegates = true;

    qreal m_estimatedHeight = -1;
    qreal m_knownMainSum = 0;
    int m_knownMainCount = 0;
    bool m_asynchronous = false;

    int m_removeDuration = 300;
    int m_readyDelay = 0;

    QVector<ItemRecord> m_layout;
    QHash<int, DelegateEntry> m_delegates;
    QHash<QQuickItem*, int> m_itemToIndex;
    QVector<DelegateEntry> m_dyingDelegates;

    bool m_componentComplete = false;
    bool m_relayoutPending = false;

    QList<QMetaObject::Connection> m_modelConnections;
};

} // namespace caelestia::components
