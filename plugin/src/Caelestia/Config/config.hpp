#pragma once

#include <qqmlengine.h>

#include "appearanceconfig.hpp"
#include "backgroundconfig.hpp"
#include "barconfig.hpp"
#include "borderconfig.hpp"
#include "controlcenterconfig.hpp"
#include "dashboardconfig.hpp"
#include "generalconfig.hpp"
#include "launcherconfig.hpp"
#include "lockconfig.hpp"
#include "notifsconfig.hpp"
#include "osdconfig.hpp"
#include "rootconfig.hpp"
#include "serviceconfig.hpp"
#include "sessionconfig.hpp"
#include "sidebarconfig.hpp"
#include "userpaths.hpp"
#include "utilitiesconfig.hpp"
#include "winfoconfig.hpp"

namespace caelestia::config {

class GlobalConfig : public RootConfig {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

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
