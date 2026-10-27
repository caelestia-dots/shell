#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::shell::config {

using Qt::StringLiterals::operator""_s;

class AddonsMadisonVpn : public settings::ObjectNode {
    CONFIG_NODE(AddonsMadisonVpn, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
};

class AddonsTimers : public settings::ObjectNode {
    CONFIG_NODE(AddonsTimers, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
};

class AddonsConfig : public settings::ObjectNode {
    CONFIG_NODE(AddonsConfig, settings::ObjectNode)

    CONFIG_GLOBAL_SUBOBJECT(AddonsMadisonVpn, madisonVpn)
    CONFIG_GLOBAL_SUBOBJECT(AddonsTimers, timers)
};

} // namespace caelestia::shell::config
