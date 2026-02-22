#pragma once

#include <QColor>
#include <QElapsedTimer>
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
    Q_PROPERTY(int animationDuration READ animationDuration WRITE setAnimationDuration NOTIFY animationDurationChanged)

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

    int animationDuration() const;
    void setAnimationDuration(int ms);

signals:
    void barCountChanged();
    void spacingChanged();
    void smoothingChanged();
    void curvatureChanged();
    void barRadiusChanged();
    void barColorTopChanged();
    void barColorBottomChanged();
    void audioValuesChanged();
    void animationDurationChanged();

private:
    qreal spatialSmooth(int index, const QVector<qreal>& values, int radius) const;
    void ensureBuffers();

    qreal effectiveScale() const;
    qreal snapToPixel(qreal v) const;

    int m_barCount;
    qreal m_spacing;
    qreal m_smoothing;
    int m_curvature;
    qreal m_barRadius;

    QColor m_barColorTop;
    QColor m_barColorBottom;

    QVector<qreal> m_audioValues;
    QVector<qreal> m_displayValues;
    QVector<qreal> m_spatialValues;

    void startAnimation(int index, qreal target);
    void stepAnimations();

    QTimer* m_frameTimer;
    QElapsedTimer m_time;
    qint64 m_lastFrameMs;

    QVector<qreal> m_animStart;
    QVector<qreal> m_animTarget;
    QVector<qreal> m_animElapsed;
    QVector<bool> m_animActive;

    int m_animationDuration;
};

} // namespace caelestia::internal
