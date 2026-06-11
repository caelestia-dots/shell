#pragma once

#include "tickingservice.hpp"

#include <qprocess.h>
#include <qqmlintegration.h>

namespace caelestia::services {

class Gpu : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum Type {
        Auto,    // user override is empty (config "") — defer to detected autoType
        None,    // no usable GPU
        Nvidia,  // queried via nvidia-smi
        Generic, // queried via /sys/class/drm/card*/device/gpu_busy_percent
    };
    Q_ENUM(Type)

private:
    Q_PROPERTY(Type type READ type NOTIFY typeChanged)
    Q_PROPERTY(Type userType READ userType NOTIFY userTypeChanged)
    Q_PROPERTY(Type autoType READ autoType NOTIFY autoTypeChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY percentageChanged)
    Q_PROPERTY(qreal temperature READ temperature NOTIFY temperatureChanged)

public:
    explicit Gpu(QObject* parent = nullptr);

    [[nodiscard]] Type type() const;
    [[nodiscard]] Type userType() const;
    [[nodiscard]] Type autoType() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] qreal percentage() const;
    [[nodiscard]] qreal temperature() const;

signals:
    void typeChanged();
    void userTypeChanged();
    void autoTypeChanged();
    void nameChanged();
    void percentageChanged();
    void temperatureChanged();

protected:
    void tick() override;

private:
    void detectTypeOnce();
    void detectNameOnce();
    void readGenericUsage();
    void startNvidiaUsage();
    void readGpuTemperature();

    void setUserType(Type value);
    void setAutoType(Type value);
    void setName(QString value);

    [[nodiscard]] static Type parseType(const QString& s);
    [[nodiscard]] static QString cleanName(QString s);

    Type m_userType = Auto;
    Type m_autoType = None;
    QString m_name;
    qreal m_percentage = 0.0;
    qreal m_temperature = 0.0;

    QProcess* m_typeProc = nullptr;
    QProcess* m_nameProc = nullptr;
    QProcess* m_nvidiaProc = nullptr;
};

} // namespace caelestia::services
