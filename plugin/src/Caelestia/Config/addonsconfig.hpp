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

class AddonsHydration : public settings::ObjectNode {
    CONFIG_NODE(AddonsHydration, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(int, dailyGoalMl, 3000)
    CONFIG_PROPERTY(int, reminderMinutes, 15)
    CONFIG_PROPERTY(int, presetMl0, 20)
    CONFIG_PROPERTY(int, presetMl1, 83)
    CONFIG_PROPERTY(int, presetMl2, 250)
    CONFIG_PROPERTY(int, presetMl3, 500)
};

class AddonsConfig : public settings::ObjectNode {
    CONFIG_NODE(AddonsConfig, settings::ObjectNode)

    CONFIG_GLOBAL_SUBOBJECT(AddonsMadisonVpn, madisonVpn)
    CONFIG_GLOBAL_SUBOBJECT(AddonsTimers, timers)
    CONFIG_GLOBAL_SUBOBJECT(AddonsHydration, hydration)
};

} // namespace caelestia::shell::config
