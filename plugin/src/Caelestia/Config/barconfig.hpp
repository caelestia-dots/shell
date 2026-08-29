#pragma once

#include <qstring.h>
#include <qstringlist.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;
using settings::vmap;

class BarScrollActions : public settings::ObjectNode {
    CONFIG_NODE(BarScrollActions, settings::ObjectNode)

    CONFIG_PROPERTY(bool, workspaces, true)
    CONFIG_PROPERTY(bool, volume, true)
    CONFIG_PROPERTY(bool, brightness, true)
};

class BarPopouts : public settings::ObjectNode {
    CONFIG_NODE(BarPopouts, settings::ObjectNode)

    CONFIG_PROPERTY(bool, activeWindow, true)
    CONFIG_PROPERTY(bool, tray, true)
    CONFIG_PROPERTY(bool, statusIcons, true)
};

class BarWorkspaces : public settings::ObjectNode {
    CONFIG_NODE(BarWorkspaces, settings::ObjectNode)

    CONFIG_PROPERTY(int, shown, 5)
    CONFIG_PROPERTY(bool, activeIndicator, true)
    CONFIG_PROPERTY(bool, occupiedBg, false)
    CONFIG_PROPERTY(bool, showWindows, true)
    CONFIG_PROPERTY(bool, showWindowsOnSpecialWorkspaces, true)
    CONFIG_PROPERTY(int, maxWindowIcons, 5)
    CONFIG_PROPERTY(bool, activeTrail, false)
    CONFIG_GLOBAL_PROPERTY(bool, perMonitorWorkspaces, true)
    CONFIG_ENUM_PROPERTY(BarWorkspaceDisplay, displayType, BarWorkspaceDisplay::Shapes)
    CONFIG_PROPERTY(QString, label, u"  "_s)
    CONFIG_PROPERTY(QString, occupiedLabel, u"󰮯"_s)
    CONFIG_PROPERTY(QString, activeLabel, u"󰮯"_s)
    CONFIG_ENUM_PROPERTY(BarWorkspaceCapitalisation, capitalisation, BarWorkspaceCapitalisation::Preserve)
    CONFIG_GLOBAL_PROPERTY(QVariantList, specialWorkspaceIcons, {})
    CONFIG_GLOBAL_PROPERTY(QStringList, ignoredTags,
        DEFAULT_ARG({
            u"hide_in_bar"_s,
            u"xwl_popup"_s,
        }))
    CONFIG_GLOBAL_PROPERTY(QVariantList, windowIcons,
        DEFAULT_ARG({
            vmap({
                { u"regex"_s, u"steam(_app_(default|[0-9]+))?"_s },
                { u"icon"_s, u"sports_esports"_s },
            }),
        }))
};

class BarActiveWindow : public settings::ObjectNode {
    CONFIG_NODE(BarActiveWindow, settings::ObjectNode)

    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_PROPERTY(bool, inverted, false)
    CONFIG_PROPERTY(bool, showOnHover, true)
};

class BarTray : public settings::ObjectNode {
    CONFIG_NODE(BarTray, settings::ObjectNode)

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, recolour, false)
    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, iconSubs, {})
    CONFIG_GLOBAL_PROPERTY(QStringList, hiddenIcons, {})
};

class BarClock : public settings::ObjectNode {
    CONFIG_NODE(BarClock, settings::ObjectNode)

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, showDate, false)
    CONFIG_PROPERTY(bool, showIcon, true)
};

class BarConfig : public settings::ObjectNode {
    CONFIG_NODE(BarConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, persistent, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(int, dragThreshold, 20)
    CONFIG_SUBOBJECT(BarScrollActions, scrollActions)
    CONFIG_SUBOBJECT(BarPopouts, popouts)
    CONFIG_SUBOBJECT(BarWorkspaces, workspaces)
    CONFIG_SUBOBJECT(BarActiveWindow, activeWindow)
    CONFIG_SUBOBJECT(BarTray, tray)
    CONFIG_SUBOBJECT(BarClock, clock)
    CONFIG_LIST(EntryList, statusIcons,
        DEFAULT_ARG({
            LIST_ENTRY(lockStatus, true),
            LIST_ENTRY(audio, false),
            LIST_ENTRY(microphone, false),
            LIST_ENTRY(kbLayout, false),
            LIST_ENTRY(network, true),
            LIST_ENTRY(bluetooth, true),
            LIST_ENTRY(battery, true),
        }))
    CONFIG_LIST(EntryList, entries,
        DEFAULT_ARG({
            LIST_ENTRY(logo, true),
            LIST_ENTRY(workspaces, true),
            LIST_ENTRY(spacer, true),
            LIST_ENTRY(activeWindow, true),
            LIST_ENTRY(spacer, true),
            LIST_ENTRY(tray, true),
            LIST_ENTRY(clock, true),
            LIST_ENTRY(statusIcons, true),
            LIST_ENTRY(power, true),
        }))
    CONFIG_PROPERTY(QStringList, excludedScreens, {})
};

} // namespace caelestia::config
