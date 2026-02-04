#pragma once

#include <QColor>
#include <QList>
#include <QQuickPaintedItem>
#include <QVector>
#include <QtQml/qqml.h>

namespace caelestia::internal {

class VisualiserBars : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int barCount READ barCount WRITE setBarCount NOTIFY barCountChanged)
    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    Q_PROPERTY(qreal smoothing READ smoothing WRITE setSmoothing NOTIFY smoothingChanged)
    Q_PROPERTY(int curvature READ curvature WRITE setCurvature NOTIFY curvatureChanged)
    Q_PROPERTY(qreal barRadius READ barRadius WRITE setBarRadius NOTIFY barRadiusChanged)

    Q_PROPERTY(QColor barColorTop READ barColorTop WRITE setBarColorTop NOTIFY barColorTopChanged)
    Q_PROPERTY(QColor barColorBottom READ barColorBottom WRITE setBarColorBottom NOTIFY barColorBottomChanged)

    Q_PROPERTY(QList<double> audioValues READ audioValues WRITE setAudioValues NOTIFY audioValuesChanged)

public:
    explicit VisualiserBars(QQuickItem* parent = nullptr);
    void paint(QPainter* painter) override;

    int barCount() const;
    void setBarCount(int count);

    qreal spacing() const;
    void setSpacing(qreal spacing);

    qreal smoothing() const;
    void setSmoothing(qreal smoothing);

    int curvature() const;
    void setCurvature(int curvature);

    qreal barRadius() const;
    void setBarRadius(qreal radius);

    QColor barColorTop() const;
    void setBarColorTop(const QColor& c);

    QColor barColorBottom() const;
    void setBarColorBottom(const QColor& c);

    QList<double> audioValues() const;
    void setAudioValues(const QList<double>& values);

signals:
    void barCountChanged();
    void spacingChanged();
    void smoothingChanged();
    void curvatureChanged();
    void barRadiusChanged();
    void barColorTopChanged();
    void barColorBottomChanged();
    void audioValuesChanged();

private:
    qreal clamp01(qreal v) const;
    qreal spatialSmooth(int index, const QVector<qreal>& values, int radius) const;
    void ensureBuffers();

    // Helper for device-pixel snapping
    qreal effectiveScale() const;
    qreal snapToPixel(qreal v) const;

    int m_barCount = 64;
    qreal m_spacing = 2.0;
    qreal m_smoothing = 0.15;
    int m_curvature = 3;
    qreal m_barRadius = 6.0;

    QColor m_barColorTop;
    QColor m_barColorBottom;

    QVector<qreal> m_audioValues;
    QVector<qreal> m_displayValues;
    QVector<qreal> m_spatialValues;
};

} // namespace caelestia::internal
