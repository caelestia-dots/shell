#pragma once

#include "settings/rootnode.hpp"
#include "settings/singleton.hpp"
#include "appearanceconfig.hpp"
#include "backgroundconfig.hpp"
#include "barconfig.hpp"
#include "borderconfig.hpp"
#include "common.hpp"
#include "dashboardconfig.hpp"
#include "font.hpp"
#include "generalconfig.hpp"
#include "launcherconfig.hpp"
#include "lockconfig.hpp"
#include "nexusconfig.hpp"
#include "notifsconfig.hpp"
#include "osdconfig.hpp"
#include "serviceconfig.hpp"
#include "sessionconfig.hpp"
#include "sidebarconfig.hpp"
#include "tokens.hpp"
#include "userpaths.hpp"
#include "utilitiesconfig.hpp"

namespace caelestia::shell::config {

class ConfigRoot : public settings::RootNode {
    CONFIG_NODE_NO_CTOR(ConfigRoot, settings::RootNode)
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_SUBOBJECT(AppearanceConfig, appearance)
    CONFIG_SUBOBJECT(GeneralConfig, general)
    CONFIG_SUBOBJECT(BackgroundConfig, background)
    CONFIG_SUBOBJECT(BarConfig, bar)
    CONFIG_SUBOBJECT(BorderConfig, border)
    CONFIG_SUBOBJECT(DashboardConfig, dashboard)
    CONFIG_SUBOBJECT(LauncherConfig, launcher)
    CONFIG_SUBOBJECT(LockConfig, lock)
    CONFIG_SUBOBJECT(NexusConfig, nexus)
    CONFIG_SUBOBJECT(NotifsConfig, notifs)
    CONFIG_SUBOBJECT(OsdConfig, osd)
    CONFIG_SUBOBJECT(ServiceConfig, services)
    CONFIG_SUBOBJECT(SessionConfig, session)
    CONFIG_SUBOBJECT(SidebarConfig, sidebar)
    CONFIG_SUBOBJECT(UtilitiesConfig, utilities)
    CONFIG_SUBOBJECT(UserPaths, paths)

public:
    explicit ConfigRoot(const QString& path, ConfigRoot* fallback = nullptr, QObject* parent = nullptr);

    [[nodiscard]] const FontTokens* fontTokens() const;

private:
    // Binds computed values to the global token base values
    void bindTokens();

    FontTokens* const m_fontTokens;
};

class TokensRoot : public settings::RootNode {
    CONFIG_NODE_NO_CTOR(TokensRoot, settings::RootNode)
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(AppearanceTokens, appearance)
    CONFIG_SUBOBJECT(SizeTokens, sizes)

public:
    explicit TokensRoot(const QString& path, TokensRoot* fallback = nullptr, QObject* parent = nullptr);
};

namespace detail {

enum class ConfigKind : quint8 {
    Shell,
    Tokens,
};

void loaded(ConfigKind kind, settings::RootNode* layer, const QString& screen);
void loadFailed(ConfigKind kind, const QString& error, const QString& screen);
void saveFailed(ConfigKind kind, const QString& error, const QString& screen);

template <ConfigKind Kind> struct Handler {
    static void loaded(settings::RootNode* layer, const QString& screen);
    static void loadFailed(const QString& error, const QString& screen);
    static void saveFailed(const QString& error, const QString& screen);
};

template <ConfigKind Kind> void Handler<Kind>::loaded(settings::RootNode* layer, const QString& screen) {
    detail::loaded(Kind, layer, screen);
}

template <ConfigKind Kind> void Handler<Kind>::loadFailed(const QString& error, const QString& screen) {
    detail::loadFailed(Kind, error, screen);
}

template <ConfigKind Kind> void Handler<Kind>::saveFailed(const QString& error, const QString& screen) {
    detail::saveFailed(Kind, error, screen);
}

} // namespace detail

SETTINGS_SINGLETON_DECL(ConfigSingleton, ConfigRoot, GlobalConfig)
SETTINGS_SINGLETON_DECL(TokensSingleton, TokensRoot, TokenConfig)

} // namespace caelestia::shell::config
