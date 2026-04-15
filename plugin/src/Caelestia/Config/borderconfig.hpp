#pragma once

#include "configobject.hpp"

#include <algorithm>

namespace caelestia::config {

class BorderConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, thickness, 10)
    CONFIG_PROPERTY(int, rounding, 25)
    CONFIG_PROPERTY(int, smoothing, 32)

    Q_PROPERTY(int minThickness READ minThickness CONSTANT)
    Q_PROPERTY(int clampedThickness READ clampedThickness NOTIFY thicknessChanged)

public:
    explicit BorderConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] static int minThickness() { return 2; }

    [[nodiscard]] int clampedThickness() const { return std::max(minThickness(), m_thickness); }
};

} // namespace caelestia::config
