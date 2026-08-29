#pragma once

#include <algorithm>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class BorderConfig : public settings::ObjectNode {
    CONFIG_NODE(BorderConfig, settings::ObjectNode)

    CONFIG_PROPERTY(int, thickness, 10)
    CONFIG_PROPERTY(int, rounding, 25)
    CONFIG_PROPERTY(int, smoothing, 20)

    Q_PROPERTY(int minThickness READ minThickness CONSTANT)
    Q_PROPERTY(int clampedThickness READ clampedThickness NOTIFY thicknessChanged)

public:
    [[nodiscard]] static int minThickness() { return 2; }

    [[nodiscard]] int clampedThickness() const { return std::max(minThickness(), m_thickness); }
};

} // namespace caelestia::config
