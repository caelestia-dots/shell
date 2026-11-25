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

namespace caelestia::shell::components {

class LazyViewAttached : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(qreal preferredHeight READ preferredHeight WRITE setPreferredHeight NOTIFY preferredHeightChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(bool adding READ adding NOTIFY addingChanged)
    Q_PROPERTY(bool removing READ removing NOTIFY removingChanged)
    Q_PROPERTY(bool trackViewport READ trackViewport WRITE setTrackViewport NOTIFY trackViewportChanged)

public:
    explicit LazyViewAttached(QObject* parent = nullptr);

    [[nodiscard]] qreal preferredHeight() const;
    void setPreferredHeight(qreal height);

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
    void readyChanged();
    void addingChanged();
    void removingChanged();
    void trackViewportChanged();

private:
    qreal m_preferredHeight = -1;
    bool m_ready = false;
    bool m_adding = false;
    bool m_removing = false;
    bool m_trackViewport = false;
};

// Shared delegate lifecycle for lazy model views; subclasses supply layout and placement
class LazyViewBase : public QQuickItem {
    Q_OBJECT
    QML_ANONYMOUS

    // Model & Delegate
    Q_PROPERTY(QAbstractItemModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QQmlComponent* delegate READ delegate WRITE setDelegate NOTIFY delegateChanged)

    // Layout: layoutHeight is the final extent, contentHeight includes delegates animating out
    Q_PROPERTY(qreal layoutHeight READ layoutHeight NOTIFY layoutHeightChanged)
    Q_PROPERTY(qreal contentHeight READ contentHeight NOTIFY contentHeightChanged)
    Q_PROPERTY(qreal contentY READ contentY WRITE setContentY NOTIFY contentYChanged)

    // Viewport & Lazy Loading
    Q_PROPERTY(QRectF viewport READ viewport WRITE setViewport NOTIFY viewportChanged)
    Q_PROPERTY(bool useCustomViewport READ useCustomViewport WRITE setUseCustomViewport NOTIFY useCustomViewportChanged)
    Q_PROPERTY(qreal cacheBuffer READ cacheBuffer WRITE setCacheBuffer NOTIFY cacheBufferChanged)
    Q_PROPERTY(bool cullDelegates READ cullDelegates WRITE setCullDelegates NOTIFY cullDelegatesChanged)

    // Sizing
    Q_PROPERTY(qreal estimatedItemHeight READ estimatedItemHeight WRITE setEstimatedItemHeight NOTIFY
            estimatedItemHeightChanged)

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
    explicit LazyViewBase(QQuickItem* parent = nullptr);
    ~LazyViewBase() override;

    // Model & Delegate
    [[nodiscard]] QAbstractItemModel* model() const;
    void setModel(QAbstractItemModel* model);

    [[nodiscard]] QQmlComponent* delegate() const;
    void setDelegate(QQmlComponent* delegate);

    // Layout
    [[nodiscard]] qreal layoutHeight() const;
    [[nodiscard]] qreal contentHeight() const;

    [[nodiscard]] qreal contentY() const;
    void setContentY(qreal contentY);

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
    [[nodiscard]] qreal estimatedItemHeight() const;
    void setEstimatedItemHeight(qreal height);

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
    void layoutHeightChanged();
    void contentHeightChanged();
    void contentYChanged();
    void viewportChanged();
    void useCustomViewportChanged();
    void cacheBufferChanged();
    void cullDelegatesChanged();
    void estimatedItemHeightChanged();
    void asynchronousChanged();
    void removeDurationChanged();
    void readyDelayChanged();
    void countChanged();
    void itemsDirtyChanged();
    void viewportAdjustNeeded(qreal delta);

protected:
    struct ItemRecord {
        qreal top = 0;
        qreal height = 0;
        bool heightKnown = false;
        bool isNew = false;
    };

    struct DelegateEntry {
        int modelIndex = -1;
        QQuickItem* item = nullptr;
        bool pendingRemoval = false;
        bool pendingInsert = false;
        bool readyDelayStarted = false;
    };

    // --- Subclass hooks ---

    // Recomputes item tops, spans and the layout/content heights.
    virtual void relayout() = 0;

    // Vertical spans searched for the visible range (list items, grid rows)
    [[nodiscard]] virtual int spanCount() const = 0;
    [[nodiscard]] virtual qreal spanTop(int span) const = 0;
    [[nodiscard]] virtual qreal spanHeight(int span) const = 0;
    [[nodiscard]] virtual std::pair<int, int> itemsForSpans(int first, int last) const = 0;

    // Width given to a delegate on creation.
    [[nodiscard]] virtual qreal delegateWidth() const = 0;
    // Height as currently rendered, for culling, hit testing and contentHeight.
    [[nodiscard]] virtual qreal visibleHeightOf(QQuickItem* item) const = 0;

    // Initial geometry for a freshly created delegate.
    virtual void placeCreatedDelegate(DelegateEntry& entry) = 0;
    // Moves a live delegate to its layout position; called every polish.
    virtual void positionDelegate(DelegateEntry& entry) = 0;

    // Called once a delegate is created and connected. Default measures it now.
    virtual void delegateCreated(DelegateEntry& entry);
    // Default re-measures immediately.
    virtual void onDelegateHeightChanged(QQuickItem* item);
    // Shows the delegate and flips adding/ready; delayed when readyDelay deferred it
    virtual void revealDelegate(DelegateEntry& entry, bool delayed);
    // Called before a delegate starts animating out.
    virtual void delegateRemoving(DelegateEntry& entry);
    virtual void destroyDelegate(DelegateEntry& entry);
    virtual void viewWidthChanged(qreal newWidth, qreal oldWidth);
    virtual void resetContent();

    [[nodiscard]] virtual LazyViewAttached* attachedFor(QQuickItem* item) const = 0;
    [[nodiscard]] virtual LazyViewAttached* attachedForCreate(QQuickItem* item) const = 0;

    // --- Shared helpers ---

    void setLayoutHeight(qreal height);
    void setContentHeight(qreal height);
    // Lowest bottom edge among delegates still animating out, in content space
    [[nodiscard]] qreal dyingExtent() const;

    [[nodiscard]] qreal effectiveEstimatedHeight() const;
    [[nodiscard]] qreal layoutHeightAt(int index) const;
    [[nodiscard]] qreal delegateHeight(QQuickItem* item) const;
    [[nodiscard]] qreal viewportTop() const;
    [[nodiscard]] QRectF effectiveViewport() const;
    void applyMeasuredHeight(int index, qreal height);
    void scheduleRelayout();

    [[nodiscard]] int indexOfDelegate(QQuickItem* item) const;

    // QQuickItem overrides
    void componentComplete() override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void updatePolish() override;

    // Members
    QAbstractItemModel* m_model = nullptr;
    QQmlComponent* m_delegate = nullptr;

    qreal m_contentY = 0;
    QVector<ItemRecord> m_layout;
    QHash<int, DelegateEntry> m_delegates;
    QHash<QQuickItem*, int> m_itemToIndex;
    QVector<DelegateEntry> m_dyingDelegates;
    bool m_componentComplete = false;

private:
    // Delegate properties in the order they must be applied
    using PropertyList = QList<std::pair<QString, QVariant>>;

    // Sizing
    void trackHeight(qreal height);
    void untrackHeight(qreal height);
    // Returns the layout height the item had before the update
    qreal setKnownHeight(int index, qreal height);
    void adjustViewportIfAbove(int index, QQuickItem* item, qreal delta);

    // Layout
    [[nodiscard]] std::pair<int, int> computeVisibleRange() const;

    // Delegate lifecycle
    void syncDelegates();
    [[nodiscard]] QList<int> delegatesOutsideViewport(const QSet<int>& keep, const QRectF& viewport) const;
    [[nodiscard]] QList<int> missingDelegates(int first, int last) const;
    int destroyDelegates(const QList<int>& indices, int budget);
    int createDelegates(const QList<int>& indices, int budget);
    DelegateEntry createDelegate(int modelIndex);
    void connectDelegate(const DelegateEntry& entry);
    void flushPendingInserts();
    void finishDelayedInsert(QQuickItem* item);
    [[nodiscard]] PropertyList delegateProperties(int modelIndex) const;
    void updateDelegateData(DelegateEntry& entry);
    void remapDelegates(const std::function<int(int)>& mapIndex);

    // Model connection
    void connectModel();
    void disconnectModel();
    void onRowsInserted(const QModelIndex& parent, int first, int last);
    void onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last);
    void onRowsRemoved(const QModelIndex& parent, int first, int last);
    void onRowsMoved(const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row);
    void onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles);
    void onModelReset();

    qreal m_layoutHeight = 0;
    qreal m_contentHeight = 0;

    QRectF m_viewport;
    bool m_useCustomViewport = false;
    qreal m_cacheBuffer = 0;
    bool m_cullDelegates = true;

    qreal m_estimatedItemHeight = -1;
    qreal m_knownHeightSum = 0;
    int m_knownHeightCount = 0;
    bool m_asynchronous = false;

    int m_removeDuration = 300;
    int m_readyDelay = 0;

    bool m_relayoutPending = false;

    QList<QMetaObject::Connection> m_modelConnections;
};

} // namespace caelestia::shell::components
