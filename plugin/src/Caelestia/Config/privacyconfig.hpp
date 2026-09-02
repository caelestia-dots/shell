#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class PrivacyDevices : public settings::ObjectNode {
    CONFIG_NODE(PrivacyDevices, settings::ObjectNode)

    CONFIG_PROPERTY(bool, microphone, true)
    CONFIG_PROPERTY(bool, camera, true)
    CONFIG_PROPERTY(bool, screen, true)
    CONFIG_PROPERTY(bool, location, true)
};

class PrivacyConfig : public settings::ObjectNode {
    CONFIG_NODE(PrivacyConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showIndicator, true)
    CONFIG_PROPERTY(bool, showBarIndicator, true)
    CONFIG_PROPERTY(bool, showToasts, true)
    CONFIG_PROPERTY(int, expandDuration, 3500)
    CONFIG_SUBOBJECT(PrivacyDevices, devices)
};

} // namespace caelestia::config
