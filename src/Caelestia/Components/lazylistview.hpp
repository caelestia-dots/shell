#pragma once

#include <qabstractitemmodel.h>
#include <qhash.h>
#include <qobject.h>
#include <qqmlcomponent.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qrect.h>
#include <qvector.h>

namespace caelestia::components {

class LazyListViewAttached : public QObject {
    Q_OBJECT

    Q_PROPERTY(qreal preferredHeight READ preferredHeight WRITE setPreferredHeight NOTIFY preferredHeightChanged)
    Q_PROPERTY(qreal visibleHeight READ visibleHeight WRITE setVisibleHeight NOTIFY visibleHeightChanged)
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
    void readyChanged();
    void addingChanged();
    void removingChanged();
    void trackViewportChanged();

private:
    qreal m_preferredHeight = -1;
    qreal m_visibleHeight = -1;
    bool m_ready = false;
    bool m_adding = false;
    bool m_removing = false;
    bool m_trackViewport = false;
};

class LazyListView : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(LazyListViewAttached)

    // Model & Delegate
    Q_PROPERTY(QAbstractItemModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QQmlComponent* delegate READ delegate WRITE setDelegate NOTIFY delegateChanged)

    // Layout
    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    Q_PROPERTY(qreal contentHeight READ contentHeight NOTIFY contentHeightChanged)
    Q_PROPERTY(qreal layoutHeight READ layoutHeight NOTIFY layoutHeightChanged)
    Q_PROPERTY(qreal contentY READ contentY WRITE setContentY NOTIFY contentYChanged)

    // Viewport & Lazy Loading
    Q_PROPERTY(QRectF viewport READ viewport WRITE setViewport NOTIFY viewportChanged)
    Q_PROPERTY(bool useCustomViewport READ useCustomViewport WRITE setUseCustomViewport NOTIFY useCustomViewportChanged)
    Q_PROPERTY(qreal cacheBuffer READ cacheBuffer WRITE setCacheBuffer NOTIFY cacheBufferChanged)

    // Sizing
    Q_PROPERTY(qreal estimatedHeight READ estimatedHeight WRITE setEstimatedHeight NOTIFY estimatedHeightChanged)

    // Async
    Q_PROPERTY(bool asynchronous READ asynchronous WRITE setAsynchronous NOTIFY asynchronousChanged)

    // Animation Durations
    Q_PROPERTY(int removeDuration READ removeDuration WRITE setRemoveDuration NOTIFY removeDurationChanged)
    Q_PROPERTY(int readyDelay READ readyDelay WRITE setReadyDelay NOTIFY readyDelayChanged)

    // State
    Q_PROPERTY(int count READ count NOTIFY countChanged)

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
    [[nodiscard]] qreal spacing() const;
    void setSpacing(qreal spacing);

    [[nodiscard]] qreal contentHeight() const;
    [[nodiscard]] qreal layoutHeight() const;

    [[nodiscard]] qreal contentY() const;
    void setContentY(qreal contentY);

    // Viewport
    [[nodiscard]] QRectF viewport() const;
    void setViewport(const QRectF& viewport);

    [[nodiscard]] bool useCustomViewport() const;
    void setUseCustomViewport(bool use);

    [[nodiscard]] qreal cacheBuffer() const;
    void setCacheBuffer(qreal buffer);

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
signals:
    void modelChanged();
    void delegateChanged();
    void spacingChanged();
    void contentHeightChanged();
    void layoutHeightChanged();
    void contentYChanged();
    void viewportChanged();
    void useCustomViewportChanged();
    void cacheBufferChanged();
    void estimatedHeightChanged();
    void asynchronousChanged();
    void removeDurationChanged();
    void readyDelayChanged();
    void countChanged();
    void viewportAdjustNeeded(qreal delta);

protected:
    void componentComplete() override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void updatePolish() override;

private:
    struct ItemRecord {
        qreal targetY = 0;
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

    // Layout
    void relayout();
    [[nodiscard]] std::pair<int, int> computeVisibleRange() const;
    [[nodiscard]] QRectF effectiveViewport() const;
    [[nodiscard]] qreal effectiveEstimatedHeight() const;
    [[nodiscard]] static qreal delegateHeight(QQuickItem* item);
    [[nodiscard]] static qreal delegateVisibleHeight(QQuickItem* item);
    [[nodiscard]] static bool isDelegateReady(QQuickItem* item);
    void trackHeight(qreal height);
    void untrackHeight(qreal height);

    // Delegate lifecycle
    void syncDelegates();
    DelegateEntry createDelegate(int modelIndex);
    void destroyDelegate(DelegateEntry& entry);
    void updateDelegateData(DelegateEntry& entry);

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

    qreal m_spacing = 0;
    qreal m_contentHeight = 0;
    qreal m_layoutHeight = 0;
    qreal m_contentY = 0;

    QRectF m_viewport;
    bool m_useCustomViewport = false;
    qreal m_cacheBuffer = 0;

    qreal m_estimatedHeight = -1;
    qreal m_knownHeightSum = 0;
    int m_knownHeightCount = 0;
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
