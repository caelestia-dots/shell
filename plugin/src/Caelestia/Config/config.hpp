#pragma once

#include "rootconfig.hpp"

#include <qqmlengine.h>

namespace caelestia::config {

class AppearanceConfig;
class BackgroundConfig;
class BarConfig;
class BorderConfig;
class ControlCenterConfig;
class DashboardConfig;
class GeneralConfig;
class LauncherConfig;
class LockConfig;
class NotifsConfig;
class OsdConfig;
class ServiceConfig;
class SessionConfig;
class SidebarConfig;
class UserPaths;
class UtilitiesConfig;
class WInfoConfig;

class GlobalConfig : public RootConfig {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_MOC_INCLUDE("appearanceconfig.hpp")
    Q_MOC_INCLUDE("backgroundconfig.hpp")
    Q_MOC_INCLUDE("barconfig.hpp")
    Q_MOC_INCLUDE("borderconfig.hpp")
    Q_MOC_INCLUDE("controlcenterconfig.hpp")
    Q_MOC_INCLUDE("dashboardconfig.hpp")
    Q_MOC_INCLUDE("generalconfig.hpp")
    Q_MOC_INCLUDE("launcherconfig.hpp")
    Q_MOC_INCLUDE("lockconfig.hpp")
    Q_MOC_INCLUDE("notifsconfig.hpp")
    Q_MOC_INCLUDE("osdconfig.hpp")
    Q_MOC_INCLUDE("serviceconfig.hpp")
    Q_MOC_INCLUDE("sessionconfig.hpp")
    Q_MOC_INCLUDE("sidebarconfig.hpp")
    Q_MOC_INCLUDE("userpaths.hpp")
    Q_MOC_INCLUDE("utilitiesconfig.hpp")
    Q_MOC_INCLUDE("winfoconfig.hpp")

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_SUBOBJECT(AppearanceConfig, appearance)
    CONFIG_SUBOBJECT(GeneralConfig, general)
    CONFIG_SUBOBJECT(BackgroundConfig, background)
    CONFIG_SUBOBJECT(BarConfig, bar)
    CONFIG_SUBOBJECT(BorderConfig, border)
    CONFIG_SUBOBJECT(DashboardConfig, dashboard)
    CONFIG_SUBOBJECT(ControlCenterConfig, controlCenter)
    CONFIG_SUBOBJECT(LauncherConfig, launcher)
    CONFIG_SUBOBJECT(NotifsConfig, notifs)
    CONFIG_SUBOBJECT(OsdConfig, osd)
    CONFIG_SUBOBJECT(SessionConfig, session)
    CONFIG_SUBOBJECT(WInfoConfig, winfo)
    CONFIG_SUBOBJECT(LockConfig, lock)
    CONFIG_SUBOBJECT(UtilitiesConfig, utilities)
    CONFIG_SUBOBJECT(SidebarConfig, sidebar)
    CONFIG_SUBOBJECT(ServiceConfig, services)
    CONFIG_SUBOBJECT(UserPaths, paths)

public:
    static GlobalConfig* instance();
    [[nodiscard]] Q_INVOKABLE GlobalConfig* defaults();
    [[nodiscard]] Q_INVOKABLE static GlobalConfig* forScreen(const QString& screen);
    static GlobalConfig* create(QQmlEngine*, QJSEngine*);

    void bindAppearanceTokens();

private:
    friend class MonitorConfigManager;
    explicit GlobalConfig(QObject* parent = nullptr);
    explicit GlobalConfig(
        GlobalConfig* fallback, const QString& filePath, const QString& screen = {}, QObject* parent = nullptr);

    GlobalConfig* m_defaults = nullptr;
    bool m_tokensBound = false;
};

} // namespace caelestia::config
