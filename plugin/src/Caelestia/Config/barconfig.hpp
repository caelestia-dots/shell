#pragma once

#include "configlist.hpp"
#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class BarEntry : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, id)
    CONFIG_PROPERTY(bool, enabled, true)

public:
    explicit BarEntry(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

CONFIG_LIST_TYPE(BarEntry, BarEntryList)

class BarScrollActions : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, workspaces, true)
    CONFIG_PROPERTY(bool, volume, true)
    CONFIG_PROPERTY(bool, brightness, true)

public:
    explicit BarScrollActions(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarPopouts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, activeWindow, true)
    CONFIG_PROPERTY(bool, tray, true)
    CONFIG_PROPERTY(bool, statusIcons, true)

public:
    explicit BarPopouts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarWorkspaces : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, shown, 5)
    CONFIG_PROPERTY(bool, activeIndicator, true)
    CONFIG_PROPERTY(bool, occupiedBg, false)
    CONFIG_PROPERTY(bool, showWindows, true)
    CONFIG_PROPERTY(bool, showWindowsOnSpecialWorkspaces, true)
    CONFIG_PROPERTY(int, maxWindowIcons, 5)
    CONFIG_PROPERTY(bool, activeTrail, false)
    CONFIG_GLOBAL_PROPERTY(bool, perMonitorWorkspaces, true)
    CONFIG_PROPERTY(QString, label, u"  "_s)
    CONFIG_PROPERTY(QString, occupiedLabel, u"󰮯"_s)
    CONFIG_PROPERTY(QString, activeLabel, u"󰮯"_s)
    CONFIG_PROPERTY(QString, capitalisation, u"preserve"_s)
    CONFIG_GLOBAL_PROPERTY(QVariantList, specialWorkspaceIcons)
    CONFIG_GLOBAL_PROPERTY(QVariantList, windowIcons,
        { vmap({
            { u"regex"_s, u"steam(_app_(default|[0-9]+))?"_s },
            { u"icon"_s, u"sports_esports"_s },
        }) })

public:
    explicit BarWorkspaces(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarActiveWindow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_PROPERTY(bool, inverted, false)
    CONFIG_PROPERTY(bool, showOnHover, true)

public:
    explicit BarActiveWindow(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarTray : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, recolour, false)
    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, iconSubs)
    CONFIG_GLOBAL_PROPERTY(QStringList, hiddenIcons)

public:
    explicit BarTray(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarStatus : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, showAudio, false)
    CONFIG_PROPERTY(bool, showMicrophone, false)
    CONFIG_PROPERTY(bool, showKbLayout, false)
    CONFIG_PROPERTY(bool, showNetwork, true)
    CONFIG_PROPERTY(bool, showWifi, true)
    CONFIG_PROPERTY(bool, showBluetooth, true)
    CONFIG_PROPERTY(bool, showBattery, true)
    CONFIG_PROPERTY(bool, showLockStatus, true)

public:
    explicit BarStatus(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarClock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, showDate, false)
    CONFIG_PROPERTY(bool, showIcon, true)

public:
    explicit BarClock(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, persistent, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(int, dragThreshold, 20)
    CONFIG_SUBOBJECT(BarScrollActions, scrollActions)
    CONFIG_SUBOBJECT(BarPopouts, popouts)
    CONFIG_SUBOBJECT(BarWorkspaces, workspaces)
    CONFIG_SUBOBJECT(BarActiveWindow, activeWindow)
    CONFIG_SUBOBJECT(BarTray, tray)
    CONFIG_SUBOBJECT(BarStatus, status)
    CONFIG_SUBOBJECT(BarClock, clock)
    CONFIG_LIST(BarEntryList, entries,
        {
            vmap({ { u"id"_s, u"logo"_s } }),
            vmap({ { u"id"_s, u"workspaces"_s } }),
            vmap({ { u"id"_s, u"spacer"_s } }),
            vmap({ { u"id"_s, u"activeWindow"_s } }),
            vmap({ { u"id"_s, u"spacer"_s } }),
            vmap({ { u"id"_s, u"tray"_s } }),
            vmap({ { u"id"_s, u"clock"_s } }),
            vmap({ { u"id"_s, u"statusIcons"_s } }),
            vmap({ { u"id"_s, u"power"_s } }),
        })
    CONFIG_PROPERTY(QStringList, excludedScreens)

public:
    explicit BarConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_scrollActions(new BarScrollActions(this))
        , m_popouts(new BarPopouts(this))
        , m_workspaces(new BarWorkspaces(this))
        , m_activeWindow(new BarActiveWindow(this))
        , m_tray(new BarTray(this))
        , m_status(new BarStatus(this))
        , m_clock(new BarClock(this)) {}
};

} // namespace caelestia::config
