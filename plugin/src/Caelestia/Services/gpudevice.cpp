#include "gpudevice.hpp"

#include <cmath>

namespace caelestia::services {

GpuDevice::GpuDevice(QObject* parent)
    : QObject(parent) {}

QString GpuDevice::name() const {
    return m_name;
}

qreal GpuDevice::percentage() const {
    return m_percentage;
}

qreal GpuDevice::temperature() const {
    return m_temperature;
}

void GpuDevice::setName(QString value) {
    if (value == m_name) {
        return;
    }
    m_name = std::move(value);
    emit nameChanged();
}

void GpuDevice::setPercentage(qreal value) {
    if (std::abs(value - m_percentage) <= 0.0001) {
        return;
    }
    m_percentage = value;
    emit percentageChanged();
}

void GpuDevice::setTemperature(qreal value) {
    if (std::abs(value - m_temperature) <= 0.05) {
        return;
    }
    m_temperature = value;
    emit temperatureChanged();
}

} // namespace caelestia::services
