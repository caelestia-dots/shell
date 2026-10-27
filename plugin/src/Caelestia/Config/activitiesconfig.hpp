#pragma once

#include <qstring.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "util/i18n.hpp"
#include "common.hpp"

namespace caelestia::shell::config {

using Qt::StringLiterals::operator""_s;
using settings::vmap;
using util::i18n::mark;

class ActivityEntry : public settings::ObjectNode {
    CONFIG_NODE(ActivityEntry, settings::ObjectNode)

    CONFIG_PROPERTY(QString, id, {})
    CONFIG_PROPERTY(QString, name, {})
    CONFIG_PROPERTY(QString, icon, u"home"_s)
    CONFIG_PROPERTY(int, workspaceCount, 1)

    // Per-activity look. Empty / -1 = inherit from Principal.
    CONFIG_PROPERTY(QString, wallpaper, {})
    CONFIG_PROPERTY(QString, scheme, {})
    CONFIG_PROPERTY(QString, flavour, {})
    CONFIG_PROPERTY(QString, variant, {})
    CONFIG_PROPERTY(QString, mode, {}) // "" | "dark" | "light"
    CONFIG_PROPERTY(int, transparency, -1) // -1 inherit, 0 off, 1 on
    CONFIG_PROPERTY(int, lightApps, -1) // -1 inherit, 0 off, 1 on
};
CONFIG_LIST_TYPE(ActivityEntry, ActivityEntryList)

class ActivityAppRule : public settings::ObjectNode {
    CONFIG_NODE(ActivityAppRule, settings::ObjectNode)

    CONFIG_PROPERTY(QString, classMatch, {})
    CONFIG_PROPERTY(QString, activityId, {})
    CONFIG_PROPERTY(int, workspaceIndex, 0) // 0-based within the activity
};
CONFIG_LIST_TYPE(ActivityAppRule, ActivityAppRuleList)

class ActivitiesConfig : public settings::ObjectNode {
    CONFIG_NODE(ActivitiesConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showWindowIcons, true)
    // When false (default), workspace next/prev stay inside the current activity
    CONFIG_PROPERTY(bool, crossActivityWorkspaces, false)
    CONFIG_GLOBAL_LIST(ActivityEntryList, activities,
        DEFAULT_ARG({
            vmap({
                { u"id"_s, u"principal"_s },
                { u"name"_s, mark(u"Home"_s) },
                { u"icon"_s, u"home"_s },
                { u"workspaceCount"_s, 2 },
            }),
            vmap({
                { u"id"_s, u"games"_s },
                { u"name"_s, mark(u"Games"_s) },
                { u"icon"_s, u"sports_esports"_s },
                { u"workspaceCount"_s, 1 },
            }),
            vmap({
                { u"id"_s, u"work"_s },
                { u"name"_s, mark(u"Work"_s) },
                { u"icon"_s, u"work"_s },
                { u"workspaceCount"_s, 2 },
            }),
        }))
    CONFIG_GLOBAL_LIST(ActivityAppRuleList, appRules, DEFAULT_ARG({}))
};

} // namespace caelestia::shell::config
