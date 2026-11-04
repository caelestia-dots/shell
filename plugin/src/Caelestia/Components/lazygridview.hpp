#pragma once

#include <qhash.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qvector.h>

#include <cstdint>

#include "lazyviewbase.hpp"

namespace caelestia::shell::components {

class LazyGridViewAttached : public LazyViewAttached {
    Q_OBJECT

    Q_PROPERTY(qreal rowHeight READ rowHeight NOTIFY rowHeightChanged)

public:
    explicit LazyGridViewAttached(QObject* parent = nullptr);

    [[nodiscard]] qreal rowHeight() const;
    void setRowHeight(qreal height);

signals:
    void rowHeightChanged();

private:
    qreal m_rowHeight = 0;
};

// Grid that springs delegate geometry itself; drive step() from a FrameAnimation gated on animating
class LazyGridView : public LazyViewBase {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(LazyGridViewAttached)

    // Layout
    Q_PROPERTY(int columns READ columns WRITE setColumns NOTIFY columnsChanged)
    Q_PROPERTY(qreal cellWidth READ cellWidth WRITE setCellWidth NOTIFY cellWidthChanged)
    Q_PROPERTY(qreal rowSpacing READ rowSpacing WRITE setRowSpacing NOTIFY rowSpacingChanged)
    Q_PROPERTY(qreal columnSpacing READ columnSpacing WRITE setColumnSpacing NOTIFY columnSpacingChanged)

    // Resolved layout (read-only)
    Q_PROPERTY(int resolvedColumns READ resolvedColumns NOTIFY resolvedColumnsChanged)
    Q_PROPERTY(qreal resolvedCellWidth READ resolvedCellWidth NOTIFY resolvedCellWidthChanged)

    // Move transition
    Q_PROPERTY(qreal stiffness READ stiffness WRITE setStiffness NOTIFY stiffnessChanged)
    Q_PROPERTY(qreal damping READ damping WRITE setDamping NOTIFY dampingChanged)
    Q_PROPERTY(bool animating READ animating NOTIFY animatingChanged)

public:
    explicit LazyGridView(QQuickItem* parent = nullptr);

    static LazyGridViewAttached* qmlAttachedProperties(QObject* object);

    [[nodiscard]] int columns() const;
    void setColumns(int columns);

    [[nodiscard]] qreal cellWidth() const;
    void setCellWidth(qreal width);

    [[nodiscard]] qreal rowSpacing() const;
    void setRowSpacing(qreal spacing);

    [[nodiscard]] qreal columnSpacing() const;
    void setColumnSpacing(qreal spacing);

    [[nodiscard]] int resolvedColumns() const;
    [[nodiscard]] qreal resolvedCellWidth() const;

    [[nodiscard]] qreal stiffness() const;
    void setStiffness(qreal stiffness);

    [[nodiscard]] qreal damping() const;
    void setDamping(qreal damping);

    [[nodiscard]] bool animating() const;

    // Advances all active springs by dt seconds
    Q_INVOKABLE void step(qreal dt);

signals:
    void columnsChanged();
    void cellWidthChanged();
    void rowSpacingChanged();
    void columnSpacingChanged();
    void resolvedColumnsChanged();
    void resolvedCellWidthChanged();
    void stiffnessChanged();
    void dampingChanged();
    void animatingChanged();

protected:
    void relayout() override;
    [[nodiscard]] int spanCount() const override;
    [[nodiscard]] qreal spanTop(int span) const override;
    [[nodiscard]] qreal spanHeight(int span) const override;
    [[nodiscard]] std::pair<int, int> itemsForSpans(int first, int last) const override;
    [[nodiscard]] qreal delegateWidth() const override;
    [[nodiscard]] qreal visibleHeightOf(QQuickItem* item) const override;
    void placeCreatedDelegate(DelegateEntry& entry) override;
    void positionDelegate(DelegateEntry& entry) override;
    void delegateRemoving(DelegateEntry& entry) override;
    void destroyDelegate(DelegateEntry& entry) override;
    void viewWidthChanged(qreal newWidth, qreal oldWidth) override;
    void resetContent() override;
    [[nodiscard]] LazyViewAttached* attachedFor(QQuickItem* item) const override;
    [[nodiscard]] LazyViewAttached* attachedForCreate(QQuickItem* item) const override;

    void componentComplete() override;
    void updatePolish() override;

private:
    // Spring-animated geometry channels
    enum GeomChannel : std::uint8_t {
        GeomX = 0,
        GeomY,
        GeomW,
        GeomH,
        GeomCount,
    };

    // Per-delegate spring state; positions are in view coordinates
    struct SpringState {
        qreal val[GeomCount] = { 0, 0, 0, 0 };
        qreal vel[GeomCount] = { 0, 0, 0, 0 };
        qreal target[GeomCount] = { 0, 0, 0, 0 };
        bool animating = false;
        bool placed = false;
        bool animateIn = false;
    };

    [[nodiscard]] static LazyGridViewAttached* gridAttachedFor(QQuickItem* item);
    static void applyGeometry(QQuickItem* item, const qreal (&geom)[GeomCount]);

    // Geometry
    [[nodiscard]] int rowOf(int index) const;
    [[nodiscard]] qreal rowHeightOf(int index) const;
    [[nodiscard]] qreal itemX(int index) const;
    [[nodiscard]] qreal columnStride() const;
    void updateResolvedColumns();
    void publishRowHeights();
    void targetGeometry(int index, QQuickItem* item, qreal (&out)[GeomCount]) const;

    // Transitions
    void setAnimating(bool animating);
    void snapAllSprings();
    [[nodiscard]] qreal contentHeightTarget() const;
    void updateContentHeightSpring();

    int m_columns = 0;
    qreal m_cellWidth = 0;
    qreal m_rowSpacing = 0;
    qreal m_columnSpacing = 0;

    int m_resolvedColumns = 1;
    qreal m_resolvedCellWidth = 0;

    qreal m_stiffness = 380;
    qreal m_damping = 0.8; // damping ratio (androidx SpringSimulation)
    bool m_animating = false;

    qreal m_contentHeightVel = 0;
    bool m_contentHeightPlaced = false;

    QVector<qreal> m_rowTops;
    QVector<qreal> m_rowHeights;

    // Pre-resize layout, so reflow-created items spring in from their old slot
    bool m_resizeAnim = false;
    int m_prevColumns = 0;
    qreal m_prevCellWidth = 0;
    QVector<qreal> m_prevRowTops;
    QVector<qreal> m_prevRowHeights;
    int m_createdThisPolish = 0;

    QHash<QQuickItem*, SpringState> m_springs;
};

} // namespace caelestia::shell::components
