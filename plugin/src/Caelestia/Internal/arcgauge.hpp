#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickpainteditem.h>

namespace caelestia::internal {

class ArcGauge : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qreal percentage READ percentage WRITE setPercentage NOTIFY percentageChanged)
    Q_PROPERTY(QColor accentColor READ accentColor WRITE setAccentColor NOTIFY accentColorChanged)
    Q_PROPERTY(QColor trackColor READ trackColor WRITE setTrackColor NOTIFY trackColorChanged)
    Q_PROPERTY(qreal startAngle READ startAngle WRITE setStartAngle NOTIFY startAngleChanged)
    Q_PROPERTY(qreal sweepAngle READ sweepAngle WRITE setSweepAngle NOTIFY sweepAngleChanged)
    Q_PROPERTY(qreal lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)

public:
    explicit ArcGauge(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    [[nodiscard]] qreal percentage() const;
    void setPercentage(qreal percentage);

    [[nodiscard]] QColor accentColor() const;
    void setAccentColor(const QColor& color);

    [[nodiscard]] QColor trackColor() const;
    void setTrackColor(const QColor& color);

    [[nodiscard]] qreal startAngle() const;
    void setStartAngle(qreal angle);

    [[nodiscard]] qreal sweepAngle() const;
    void setSweepAngle(qreal angle);

    [[nodiscard]] qreal lineWidth() const;
    void setLineWidth(qreal width);

signals:
    void percentageChanged();
    void accentColorChanged();
    void trackColorChanged();
    void startAngleChanged();
    void sweepAngleChanged();
    void lineWidthChanged();

private:
    qreal m_percentage = 0.0;
    QColor m_accentColor;
    QColor m_trackColor;
    qreal m_startAngle = 0.75 * M_PI;
    qreal m_sweepAngle = 1.5 * M_PI;
    qreal m_lineWidth = 10.0;
};

} // namespace caelestia::internal
