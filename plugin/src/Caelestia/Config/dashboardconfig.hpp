#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class DashboardPerformance : public settings::ObjectNode {
    CONFIG_NODE(DashboardPerformance, settings::ObjectNode)

    CONFIG_PROPERTY(bool, showBattery, true)
    CONFIG_PROPERTY(bool, showGpu, true)
    CONFIG_PROPERTY(bool, showCpu, true)
    CONFIG_PROPERTY(bool, showMemory, true)
    CONFIG_PROPERTY(bool, showStorage, true)
    CONFIG_PROPERTY(bool, showNetwork, true)
};

class DashboardConfig : public settings::ObjectNode {
    CONFIG_NODE(DashboardConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(bool, showDashboard, true)
    CONFIG_PROPERTY(bool, showMedia, true)
    CONFIG_PROPERTY(bool, showPerformance, true)
    CONFIG_PROPERTY(bool, showWeather, true)
    CONFIG_GLOBAL_PROPERTY(int, mediaUpdateInterval, 500)
    CONFIG_GLOBAL_PROPERTY(int, resourceUpdateInterval, 1000)
    CONFIG_PROPERTY(int, dragThreshold, 50)
    CONFIG_SUBOBJECT(DashboardPerformance, performance)
};

} // namespace caelestia::config
