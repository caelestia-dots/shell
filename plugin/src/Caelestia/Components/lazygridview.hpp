#pragma once

#include <qabstractitemmodel.h>
#include <qeasingcurve.h>
#include <qhash.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlcomponent.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qrect.h>
#include <qvector.h>

namespace caelestia::components {

class LazyGridViewAttached : public QObject {
    Q_OBJECT

    Q_PROPERTY(qreal preferredHeight READ preferredHeight WRITE setPreferredHeight NOTIFY preferredHeightChanged)
    Q_PROPERTY(qreal rowHeight READ rowHeight NOTIFY rowHeightChanged)

public:
    explicit LazyGridViewAttached(QObject* parent = nullptr);

    [[nodiscard]] qreal preferredHeight() const;
    void setPreferredHeight(qreal height);

    [[nodiscard]] qreal rowHeight() const;
    void setRowHeight(qreal height);

signals:
    void preferredHeightChanged();
    void rowHeightChanged();

private:
    qreal m_preferredHeight = -1;
    qreal m_rowHeight = 0;
};

class LazyGridView : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(LazyGridViewAttached)

    // Model & Delegate
    Q_PROPERTY(QAbstractItemModel* model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QQmlComponent* delegate READ delegate WRITE setDelegate NOTIFY delegateChanged)

    // Layout
    Q_PROPERTY(int columns READ columns WRITE setColumns NOTIFY columnsChanged)
    Q_PROPERTY(qreal cellWidth READ cellWidth WRITE setCellWidth NOTIFY cellWidthChanged)
    Q_PROPERTY(qreal rowSpacing READ rowSpacing WRITE setRowSpacing NOTIFY rowSpacingChanged)
    Q_PROPERTY(qreal columnSpacing READ columnSpacing WRITE setColumnSpacing NOTIFY columnSpacingChanged)
    Q_PROPERTY(
        qreal estimatedRowHeight READ estimatedRowHeight WRITE setEstimatedRowHeight NOTIFY estimatedRowHeightChanged)

    // Resolved layout (read-only)
    Q_PROPERTY(int resolvedColumns READ resolvedColumns NOTIFY resolvedColumnsChanged)
    Q_PROPERTY(qreal resolvedCellWidth READ resolvedCellWidth NOTIFY resolvedCellWidthChanged)
    Q_PROPERTY(qreal contentHeight READ contentHeight NOTIFY contentHeightChanged)
    Q_PROPERTY(qreal contentY READ contentY WRITE setContentY NOTIFY contentYChanged)

    // Viewport & lazy loading
    Q_PROPERTY(QRectF viewport READ viewport WRITE setViewport NOTIFY viewportChanged)
    Q_PROPERTY(bool useCustomViewport READ useCustomViewport WRITE setUseCustomViewport NOTIFY useCustomViewportChanged)
    Q_PROPERTY(qreal cacheBuffer READ cacheBuffer WRITE setCacheBuffer NOTIFY cacheBufferChanged)

    // Async
    Q_PROPERTY(bool asynchronous READ asynchronous WRITE setAsynchronous NOTIFY asynchronousChanged)

    // Move transition; androidx-style spring (stiffness + damping ratio, no
    // mass). Drive step() from a QML FrameAnimation gated on `animating`.
    Q_PROPERTY(qreal stiffness READ stiffness WRITE setStiffness NOTIFY stiffnessChanged)
    Q_PROPERTY(qreal damping READ damping WRITE setDamping NOTIFY dampingChanged)
    Q_PROPERTY(bool animating READ animating NOTIFY animatingChanged)

    // Enter / exit transitions (QPropertyAnimation)
    Q_PROPERTY(int enterDuration READ enterDuration WRITE setEnterDuration NOTIFY enterDurationChanged)
    Q_PROPERTY(int removeDuration READ removeDuration WRITE setRemoveDuration NOTIFY removeDurationChanged)
    Q_PROPERTY(qreal enterScale READ enterScale WRITE setEnterScale NOTIFY enterScaleChanged)
    Q_PROPERTY(qreal exitScale READ exitScale WRITE setExitScale NOTIFY exitScaleChanged)
    // Easing for the enter/exit transitions
    Q_PROPERTY(QEasingCurve easing READ easing WRITE setEasing NOTIFY easingChanged)

    // Deferral
    Q_PROPERTY(int readyDelay READ readyDelay WRITE setReadyDelay NOTIFY readyDelayChanged)

    // State
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit LazyGridView(QQuickItem* parent = nullptr);
    ~LazyGridView() override;

    static LazyGridViewAttached* qmlAttachedProperties(QObject* object);

    // Model & Delegate
    [[nodiscard]] QAbstractItemModel* model() const;
    void setModel(QAbstractItemModel* model);

    [[nodiscard]] QQmlComponent* delegate() const;
    void setDelegate(QQmlComponent* delegate);

    // Layout
    [[nodiscard]] int columns() const;
    void setColumns(int columns);

    [[nodiscard]] qreal cellWidth() const;
    void setCellWidth(qreal width);

    [[nodiscard]] qreal rowSpacing() const;
    void setRowSpacing(qreal spacing);

    [[nodiscard]] qreal columnSpacing() const;
    void setColumnSpacing(qreal spacing);

    [[nodiscard]] qreal estimatedRowHeight() const;
    void setEstimatedRowHeight(qreal height);

    // Resolved layout
    [[nodiscard]] int resolvedColumns() const;
    [[nodiscard]] qreal resolvedCellWidth() const;
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

    // Async
    [[nodiscard]] bool asynchronous() const;
    void setAsynchronous(bool async);

    // Move transition (spring)
    [[nodiscard]] qreal stiffness() const;
    void setStiffness(qreal stiffness);

    [[nodiscard]] qreal damping() const;
    void setDamping(qreal damping);

    [[nodiscard]] bool animating() const;

    // Advances all active move springs by dt seconds. Drive this from a QML
    // FrameAnimation while `animating` is true.
    Q_INVOKABLE void step(qreal dt);

    // Enter / exit transitions
    [[nodiscard]] int enterDuration() const;
    void setEnterDuration(int duration);

    [[nodiscard]] int removeDuration() const;
    void setRemoveDuration(int duration);

    [[nodiscard]] qreal enterScale() const;
    void setEnterScale(qreal scale);

    [[nodiscard]] qreal exitScale() const;
    void setExitScale(qreal scale);

    [[nodiscard]] QEasingCurve easing() const;
    void setEasing(const QEasingCurve& easing);

    // Deferral
    [[nodiscard]] int readyDelay() const;
    void setReadyDelay(int delay);

    // State
    [[nodiscard]] int count() const;

signals:
    void modelChanged();
    void delegateChanged();
    void columnsChanged();
    void cellWidthChanged();
    void rowSpacingChanged();
    void columnSpacingChanged();
    void estimatedRowHeightChanged();
    void resolvedColumnsChanged();
    void resolvedCellWidthChanged();
    void contentHeightChanged();
    void contentYChanged();
    void viewportChanged();
    void useCustomViewportChanged();
    void cacheBufferChanged();
    void asynchronousChanged();
    void stiffnessChanged();
    void dampingChanged();
    void animatingChanged();
    void enterDurationChanged();
    void removeDurationChanged();
    void enterScaleChanged();
    void exitScaleChanged();
    void easingChanged();
    void readyDelayChanged();
    void countChanged();

protected:
    void componentComplete() override;
    void geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void updatePolish() override;

private:
    struct ItemRecord {
        qreal height = 0;
        bool heightKnown = false;
        bool isNew = false;
    };

    // Spring-animated geometry channels. The width the item receives is
    // quantized (see WIDTH_STEP) so the delegate's implicitHeight only changes
    // in coarse steps while width springs; otherwise the height/row layout it
    // feeds would chase the width every frame and jitter.
    enum GeomChannel {
        GeomX = 0,
        GeomY,
        GeomW,
        GeomH,
        GeomCount
    };

    struct DelegateEntry {
        int modelIndex = -1;
        QQuickItem* item = nullptr;
        // Move-spring state per channel (x, y, width, height); positions are in
        // view coordinates.
        qreal springVal[GeomCount] = { 0, 0, 0, 0 };
        qreal springVel[GeomCount] = { 0, 0, 0, 0 };
        qreal springTarget[GeomCount] = { 0, 0, 0, 0 };
        bool animating = false;
        bool placed = false;
        bool isEnter = false;
        bool pendingRemoval = false;
        bool pendingInsert = false;
        bool readyDelayStarted = false;
    };

    // Sizing helpers
    [[nodiscard]] qreal effectiveEstimatedHeight() const;
    [[nodiscard]] static qreal delegateHeight(QQuickItem* item);
    void trackHeight(qreal height);
    void untrackHeight(qreal height);
    void applyMeasuredHeight(int index, qreal height);

    // Geometry
    void relayout();
    [[nodiscard]] int rowOf(int index) const;
    [[nodiscard]] qreal itemX(int index) const;
    [[nodiscard]] qreal itemY(int index) const;
    [[nodiscard]] qreal columnStride() const;
    [[nodiscard]] QRectF effectiveViewport() const;
    [[nodiscard]] std::pair<int, int> computeVisibleRange() const;
    void updateResolvedColumns();

    // Transitions
    void positionItem(DelegateEntry& entry);
    void setAnimating(bool animating);
    void startEnterAnimation(QQuickItem* item);
    void startExitAnimation(QQuickItem* item);

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

    int m_columns = 0;
    qreal m_cellWidth = 0;
    qreal m_rowSpacing = 0;
    qreal m_columnSpacing = 0;
    qreal m_estimatedRowHeight = -1;

    int m_resolvedColumns = 1;
    qreal m_resolvedCellWidth = 0;
    qreal m_contentHeight = 0;
    qreal m_contentY = 0;

    qreal m_knownHeightSum = 0;
    int m_knownHeightCount = 0;

    QRectF m_viewport;
    bool m_useCustomViewport = false;
    qreal m_cacheBuffer = 0;

    bool m_asynchronous = false;

    qreal m_stiffness = 380;
    qreal m_damping = 0.8; // damping ratio (androidx SpringSimulation)
    bool m_animating = false;

    int m_enterDuration = 300;
    int m_removeDuration = 300;
    qreal m_enterScale = 0.8;
    qreal m_exitScale = 0.8;
    QEasingCurve m_easing = QEasingCurve(QEasingCurve::OutCubic);
    int m_readyDelay = 0;

    QVector<ItemRecord> m_layout;
    QVector<qreal> m_rowTops;
    QVector<qreal> m_rowHeights;

    QHash<int, DelegateEntry> m_delegates;
    QHash<QQuickItem*, int> m_itemToIndex;
    QVector<DelegateEntry> m_dyingDelegates;

    bool m_componentComplete = false;
    bool m_relayoutPending = false;

    QList<QMetaObject::Connection> m_modelConnections;
};

} // namespace caelestia::components
