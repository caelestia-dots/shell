#pragma once

#include "tickingservice.hpp"

#include <qqmlintegration.h>

namespace caelestia::services {

class Cpu : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY percentageChanged)
    Q_PROPERTY(qreal temperature READ temperature NOTIFY temperatureChanged)

public:
    explicit Cpu(QObject* parent = nullptr);

    [[nodiscard]] QString name() const;
    [[nodiscard]] qreal percentage() const;
    [[nodiscard]] qreal temperature() const;

signals:
    void nameChanged();
    void percentageChanged();
    void temperatureChanged();

protected:
    void tick() override;

private:
    void readNameOnce();
    void refreshPercentage();
    void refreshTemperature();

    [[nodiscard]] static QString cleanName(QString s);

    QString m_name;
    qreal m_percentage = 0.0;
    qreal m_temperature = 0.0;
    quint64 m_lastIdle = 0;
    quint64 m_lastTotal = 0;
    bool m_nameLoaded = false;
};

} // namespace caelestia::services
