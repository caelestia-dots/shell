#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class UtilitiesToasts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

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

public:
    explicit UtilitiesToasts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesVpn : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, provider)

public:
    explicit UtilitiesVpn(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, maxToasts, 4)
    CONFIG_SUBOBJECT(UtilitiesToasts, toasts)
    CONFIG_SUBOBJECT(UtilitiesVpn, vpn)
    CONFIG_PROPERTY(QVariantList, quickToggles,
        {
            vmap({ { u"id"_s, u"wifi"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"bluetooth"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"mic"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"settings"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"gameMode"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"dnd"_s }, { u"enabled"_s, true } }),
            vmap({ { u"id"_s, u"vpn"_s }, { u"enabled"_s, false } }),
        })

public:
    explicit UtilitiesConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_toasts(new UtilitiesToasts(this))
        , m_vpn(new UtilitiesVpn(this)) {}
};

} // namespace caelestia::config
