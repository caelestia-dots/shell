#pragma once

#include <qstring.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class UtilitiesToasts : public settings::ObjectNode {
    CONFIG_NODE(UtilitiesToasts, settings::ObjectNode)

    CONFIG_PROPERTY(QString, fullscreen, u"off"_s)
    CONFIG_GLOBAL_PROPERTY(bool, configLoaded, true)
    CONFIG_GLOBAL_PROPERTY(bool, chargingChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, gameModeChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, dndChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, audioOutputChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, audioInputChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, capsLockChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, numLockChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, kbLayoutChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, kbLimit, true)
    CONFIG_GLOBAL_PROPERTY(bool, vpnChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, nowPlaying, false)
};

class UtilitiesVpn : public settings::ObjectNode {
    CONFIG_NODE(UtilitiesVpn, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, provider, {})
    CONFIG_GLOBAL_PROPERTY(QString, selectedProvider, QString())
};

class UtilitiesCards : public settings::ObjectNode {
    CONFIG_NODE(UtilitiesCards, settings::ObjectNode)

    CONFIG_PROPERTY(bool, keepAwake, true)
    CONFIG_PROPERTY(bool, recorder, true)
    CONFIG_PROPERTY(bool, quickToggles, true)
};

class UtilitiesConfig : public settings::ObjectNode {
    CONFIG_NODE(UtilitiesConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, maxToasts, 4)
    CONFIG_SUBOBJECT(UtilitiesCards, cards)
    CONFIG_SUBOBJECT(UtilitiesToasts, toasts)
    CONFIG_SUBOBJECT(UtilitiesVpn, vpn)
    CONFIG_LIST(EntryList, quickToggles,
        DEFAULT_ARG({
            LIST_ENTRY(wifi, true),
            LIST_ENTRY(bluetooth, true),
            LIST_ENTRY(mic, true),
            LIST_ENTRY(settings, true),
            LIST_ENTRY(gameMode, true),
            LIST_ENTRY(dnd, true),
            LIST_ENTRY(vpn, false),
        }))
};

} // namespace caelestia::config
