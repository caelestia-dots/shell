#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::services {

class GpuDevice : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("GpuDevice is created by Gpu")

    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY percentageChanged)
    Q_PROPERTY(qreal temperature READ temperature NOTIFY temperatureChanged)

public:
    explicit GpuDevice(QObject* parent = nullptr);

    [[nodiscard]] QString name() const;
    [[nodiscard]] qreal percentage() const;
    [[nodiscard]] qreal temperature() const;

    void setName(QString value);
    void setPercentage(qreal value);
    void setTemperature(qreal value);

signals:
    void nameChanged();
    void percentageChanged();
    void temperatureChanged();

private:
    QString m_name;
    qreal m_percentage = 0.0;
    qreal m_temperature = 0.0;
};

} // namespace caelestia::services
