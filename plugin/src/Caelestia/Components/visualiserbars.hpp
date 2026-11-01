#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qsggeometry.h>
#include <qsgnode.h>
#include <qvector.h>

namespace caelestia::components {

class VisualiserBars : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVector<double> values READ values WRITE setValues NOTIFY valuesChanged)
    Q_PROPERTY(QColor primaryColor READ primaryColor WRITE setPrimaryColor NOTIFY primaryColorChanged)
    Q_PROPERTY(QColor secondaryColor READ secondaryColor WRITE setSecondaryColor NOTIFY secondaryColorChanged)
    Q_PROPERTY(qreal rounding READ rounding WRITE setRounding NOTIFY roundingChanged)
    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    Q_PROPERTY(int animationDuration READ animationDuration WRITE setAnimationDuration NOTIFY animationDurationChanged)
    Q_PROPERTY(bool settled READ settled NOTIFY settledChanged)

public:
    explicit VisualiserBars(QQuickItem* parent = nullptr);

    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override;

    Q_INVOKABLE void advance(qreal dt);

    [[nodiscard]] QVector<double> values() const;
    void setValues(const QVector<double>& values);

    [[nodiscard]] QColor primaryColor() const;
    void setPrimaryColor(const QColor& color);

    [[nodiscard]] QColor secondaryColor() const;
    void setSecondaryColor(const QColor& color);

    [[nodiscard]] qreal rounding() const;
    void setRounding(qreal rounding);

    [[nodiscard]] qreal spacing() const;
    void setSpacing(qreal spacing);

    [[nodiscard]] int animationDuration() const;
    void setAnimationDuration(int duration);

    [[nodiscard]] bool settled() const;

signals:
    void valuesChanged();
    void primaryColorChanged();
    void secondaryColorChanged();
    void roundingChanged();
    void spacingChanged();
    void animationDurationChanged();
    void settledChanged();

private:
    // Appends the triangles of one bar (rounded top, flat bottom) to the vertex list
    void appendBar(QSGGeometry::ColoredPoint2D* out, qsizetype& index, qreal x, qreal y, qreal barWidth,
        qreal barHeight, qreal h) const;
    [[nodiscard]] QSGGeometry::ColoredPoint2D colouredPoint(qreal x, qreal y, qreal h) const;

    QVector<double> m_targetValues;
    QVector<double> m_displayValues;
    QColor m_primaryColor;
    QColor m_secondaryColor;
    qreal m_rounding = 0.0;
    qreal m_spacing = 0.0;
    int m_animationDuration = 200;
    bool m_settled = true;
};

} // namespace caelestia::components
