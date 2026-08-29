#pragma once

#include <qjsengine.h>
#include <qqmlengine.h>

#include "settings/layerregistry.hpp"
#include "settings/rootnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class AppearanceConfig;
class AppearanceTokens;
class BackgroundConfig;
class BarConfig;
class BorderConfig;
class DashboardConfig;
class GeneralConfig;
class LauncherConfig;
class LockConfig;
class NexusConfig;
class NotifsConfig;
class OsdConfig;
class ServiceConfig;
class SessionConfig;
class SidebarConfig;
class SizeTokens;
class UserPaths;
class UtilitiesConfig;

Q_MOC_INCLUDE("appearanceconfig.hpp")
Q_MOC_INCLUDE("backgroundconfig.hpp")
Q_MOC_INCLUDE("barconfig.hpp")
Q_MOC_INCLUDE("borderconfig.hpp")
Q_MOC_INCLUDE("dashboardconfig.hpp")
Q_MOC_INCLUDE("generalconfig.hpp")
Q_MOC_INCLUDE("launcherconfig.hpp")
Q_MOC_INCLUDE("lockconfig.hpp")
Q_MOC_INCLUDE("nexusconfig.hpp")
Q_MOC_INCLUDE("notifsconfig.hpp")
Q_MOC_INCLUDE("osdconfig.hpp")
Q_MOC_INCLUDE("serviceconfig.hpp")
Q_MOC_INCLUDE("sessionconfig.hpp")
Q_MOC_INCLUDE("sidebarconfig.hpp")
Q_MOC_INCLUDE("tokens.hpp")
Q_MOC_INCLUDE("userpaths.hpp")
Q_MOC_INCLUDE("utilitiesconfig.hpp")

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

private:
    // Binds the computed appearance values to the global token base values
    void bindTokens();
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

enum class ConfigKind {
    Shell,
    Tokens
};

void loaded(ConfigKind kind, settings::RootNode* layer, const QString& screen);
void loadFailed(ConfigKind kind, const QString& error, const QString& screen);
void saveFailed(ConfigKind kind, const QString& error, const QString& screen);

} // namespace detail

#define SINGLETON_DECL(Type, Root, QmlName)                                                                            \
    class Type : public Root {                                                                                         \
        Q_OBJECT                                                                                                       \
        QML_NAMED_ELEMENT(QmlName)                                                                                     \
        QML_SINGLETON                                                                                                  \
                                                                                                                       \
    public:                                                                                                            \
        static Type* instance();                                                                                       \
        static Type* create(QQmlEngine*, QJSEngine*);                                                                  \
                                                                                                                       \
        [[nodiscard]] Q_INVOKABLE Root* forScreen(const QString& screen);                                              \
                                                                                                                       \
    private:                                                                                                           \
        explicit Type(QObject* parent = nullptr);                                                                      \
                                                                                                                       \
        void onTreeLoaded(settings::RootNode* layer);                                                                  \
        void onTreeLoadFailed(settings::RootNode* layer, const QString& error);                                        \
        void onTreeSaveFailed(settings::RootNode* layer, const QString& error);                                        \
                                                                                                                       \
        void initLayer(Root* layer);                                                                                   \
                                                                                                                       \
        settings::LayerRegistry<Root> m_layers;                                                                        \
    };

SINGLETON_DECL(ConfigSingleton, ConfigRoot, GlobalConfig)
SINGLETON_DECL(TokensSingleton, TokensRoot, TokenConfig)

#undef SINGLETON_DECL

} // namespace caelestia::config
