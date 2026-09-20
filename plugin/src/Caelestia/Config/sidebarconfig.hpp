#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class SidebarConfig : public settings::ObjectNode {
    CONFIG_NODE(SidebarConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(int, minHoverThreshold, 200)
    CONFIG_PROPERTY(int, dragThreshold, 80)
};

} // namespace caelestia::config
