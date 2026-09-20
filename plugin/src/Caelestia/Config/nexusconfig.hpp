#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class NexusConfig : public settings::ObjectNode {
    CONFIG_NODE(NexusConfig, settings::ObjectNode)

    CONFIG_PROPERTY(int, wallpapersPerRow, 4)
    CONFIG_PROPERTY(int, maxNetworksShown, 5)
    CONFIG_GLOBAL_PROPERTY(int, networkRescanInterval, 15000)
};

} // namespace caelestia::config
