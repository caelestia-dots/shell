#pragma once

#include <qqmlintegration.h>
#include <qquickitem.h>

#include "lazyviewbase.hpp"

namespace caelestia::shell::components {

class LazyListViewAttached : public LazyViewAttached {
    Q_OBJECT

    Q_PROPERTY(qreal visibleHeight READ visibleHeight WRITE setVisibleHeight NOTIFY visibleHeightChanged)
    Q_PROPERTY(qreal layoutY READ layoutY NOTIFY layoutYChanged)

public:
    explicit LazyListViewAttached(QObject* parent = nullptr);

    [[nodiscard]] qreal visibleHeight() const;
    void setVisibleHeight(qreal height);

    [[nodiscard]] qreal layoutY() const;
    void setLayoutY(qreal y);

signals:
    void visibleHeightChanged();
    void layoutYChanged();

private:
    qreal m_visibleHeight = -1;
    qreal m_layoutY = 0;
};

// List whose delegates animate themselves: y goes through Behaviors, visibleHeight is reported back
class LazyListView : public LazyViewBase {
    Q_OBJECT
    QML_ELEMENT
    QML_ATTACHED(LazyListViewAttached)

    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)

public:
    explicit LazyListView(QQuickItem* parent = nullptr);

    static LazyListViewAttached* qmlAttachedProperties(QObject* object);

    [[nodiscard]] qreal spacing() const;
    void setSpacing(qreal spacing);

signals:
    void spacingChanged();

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
    void delegateCreated(DelegateEntry& entry) override;
    void onDelegateHeightChanged(QQuickItem* item) override;
    void revealDelegate(DelegateEntry& entry, bool delayed) override;
    void viewWidthChanged(qreal newWidth, qreal oldWidth) override;
    [[nodiscard]] LazyViewAttached* attachedFor(QQuickItem* item) const override;
    [[nodiscard]] LazyViewAttached* attachedForCreate(QQuickItem* item) const override;

private:
    [[nodiscard]] static LazyListViewAttached* listAttachedFor(QQuickItem* item);
    [[nodiscard]] static bool isDelegateReady(QQuickItem* item);
    [[nodiscard]] qreal visibleHeightAt(int index) const;
    [[nodiscard]] qreal visualYAt(int index) const;
    void updateLayoutPositions();
    void updateContentHeight();
    void updateLayoutY(QQuickItem* item, int index);

    qreal m_spacing = 0;
};

} // namespace caelestia::shell::components
