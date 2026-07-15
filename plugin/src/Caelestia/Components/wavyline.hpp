#pragma once

#include <qqmlintegration.h>
#include <qquickpainteditem.h>

namespace caelestia::controls {

class WavyLine : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged FINAL)
    Q_PROPERTY(qreal amplitudeMultiplier READ amplitudeMultiplier WRITE setAmplitudeMultiplier NOTIFY
            amplitudeMultiplierChanged FINAL)
    Q_PROPERTY(int frequency READ frequency WRITE setFrequency NOTIFY frequencyChanged FINAL)
    Q_PROPERTY(qreal startX READ startX WRITE setStartX NOTIFY startXChanged FINAL)
    Q_PROPERTY(qreal fullLength READ fullLength WRITE setFullLength NOTIFY fullLengthChanged FINAL)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged FINAL)
    Q_PROPERTY(qreal waveProgress READ waveProgress WRITE setWaveProgress NOTIFY waveProgressChanged FINAL)
    Q_PROPERTY(PathType pathType READ pathType WRITE setPathType NOTIFY pathTypeChanged FINAL)
    Q_PROPERTY(qreal startAngle READ startAngle WRITE setStartAngle NOTIFY startAngleChanged FINAL)
    Q_PROPERTY(qreal fullAngle READ fullAngle WRITE setFullAngle NOTIFY fullAngleChanged FINAL)
    Q_PROPERTY(qreal radius READ radius WRITE setRadius NOTIFY radiusChanged FINAL)
    Q_PROPERTY(qreal value READ value WRITE setValue NOTIFY valueChanged FINAL)

public:
    enum PathType {
        Linear,
        Arc
    };
    Q_ENUM(PathType)

    explicit WavyLine(QQuickItem* parent = nullptr);

    [[nodiscard]] int lineWidth() const;
    void setLineWidth(int lineWidth);

    [[nodiscard]] qreal amplitudeMultiplier() const;
    void setAmplitudeMultiplier(qreal amplitudeMultiplier);

    [[nodiscard]] int frequency() const;
    void setFrequency(int frequency);

    [[nodiscard]] qreal startX() const;
    void setStartX(qreal startX);

    [[nodiscard]] qreal fullLength() const;
    void setFullLength(qreal fullLength);

    [[nodiscard]] QColor color() const;
    void setColor(const QColor& color);

    [[nodiscard]] qreal waveProgress() const;
    void setWaveProgress(qreal progress);

    [[nodiscard]] PathType pathType() const;
    void setPathType(PathType pathType);

    [[nodiscard]] qreal startAngle() const;
    void setStartAngle(qreal startAngle);

    [[nodiscard]] qreal fullAngle() const;
    void setFullAngle(qreal fullAngle);

    [[nodiscard]] qreal radius() const;
    void setRadius(qreal radius);

    [[nodiscard]] qreal value() const;
    void setValue(qreal value);

    void paint(QPainter* painter) override;

signals:
    void lineWidthChanged();
    void amplitudeMultiplierChanged();
    void frequencyChanged();
    void startXChanged();
    void fullLengthChanged();
    void colorChanged();
    void waveProgressChanged();
    void pathTypeChanged();
    void startAngleChanged();
    void fullAngleChanged();
    void radiusChanged();
    void valueChanged();

private:
    void paintLinear(QPainter* painter);
    void paintArc(QPainter* painter);

    int m_lineWidth;
    qreal m_amplitudeMultiplier;
    int m_frequency;
    qreal m_startX;
    qreal m_fullLength;
    QColor m_color;
    qreal m_waveProgress;
    PathType m_pathType;
    qreal m_startAngle;
    qreal m_fullAngle;
    qreal m_radius;
    qreal m_value;
    qreal m_startAngleRad;
    qreal m_fullAngleRad;
};

} // namespace caelestia::controls
