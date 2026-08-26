#pragma once

#include <qjsengine.h>
#include <qqmlengine.h>

#include "common.hpp"
#include "settings/layerregistry.hpp"
#include "settings/rootnode.hpp"

#include "appearanceconfig.hpp"
#include "backgroundconfig.hpp"
#include "barconfig.hpp"
#include "borderconfig.hpp"
#include "dashboardconfig.hpp"
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

namespace caelestia::config {

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

#define SINGLETON(Type, Root, QmlName, file, kind)                                                                     \
    class Type : public Root {                                                                                         \
        Q_OBJECT                                                                                                       \
        QML_NAMED_ELEMENT(QmlName)                                                                                     \
        QML_SINGLETON                                                                                                  \
                                                                                                                       \
    public:                                                                                                            \
        static Type* instance() {                                                                                      \
            static Type instance;                                                                                      \
            return &instance;                                                                                          \
        }                                                                                                              \
        static Type* create(QQmlEngine*, QJSEngine*) {                                                                 \
            QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);                                      \
            return instance();                                                                                         \
        }                                                                                                              \
                                                                                                                       \
        [[nodiscard]] Q_INVOKABLE Root* forScreen(const QString& screen) {                                             \
            bool created;                                                                                              \
            auto* const layer = m_layers.get(screen, this, &created);                                                  \
            if (created)                                                                                               \
                initLayer(layer);                                                                                      \
            return layer;                                                                                              \
        }                                                                                                              \
                                                                                                                       \
    private:                                                                                                           \
        explicit Type(QObject* parent = nullptr)                                                                       \
            : Root(configDir() + QLatin1Char('/') + file, nullptr, parent)                                             \
            , m_layers(monitorConfigDir(), file, this) {                                                               \
            initLayer(this);                                                                                           \
        }                                                                                                              \
                                                                                                                       \
        void onTreeLoaded(settings::RootNode* layer) {                                                                 \
            detail::loaded(kind, layer, m_layers.nameFor(static_cast<Root*>(layer)));                                  \
        }                                                                                                              \
                                                                                                                       \
        void onTreeLoadFailed(settings::RootNode* layer, const QString& error) {                                       \
            detail::loadFailed(kind, error, m_layers.nameFor(static_cast<Root*>(layer)));                              \
        }                                                                                                              \
                                                                                                                       \
        void onTreeSaveFailed(settings::RootNode* layer, const QString& error) {                                       \
            detail::saveFailed(kind, error, m_layers.nameFor(static_cast<Root*>(layer)));                              \
        }                                                                                                              \
                                                                                                                       \
        void initLayer(Root* layer) {                                                                                  \
            QObject::connect(layer, &Root::treeLoaded, this, &Type::onTreeLoaded);                                     \
            QObject::connect(layer, &Root::treeLoadFailed, this, &Type::onTreeLoadFailed);                             \
            QObject::connect(layer, &Root::treeSaveFailed, this, &Type::onTreeSaveFailed);                             \
            layer->load();                                                                                             \
        }                                                                                                              \
                                                                                                                       \
        settings::LayerRegistry<Root> m_layers;                                                                        \
    };

SINGLETON(ConfigSingleton, ConfigRoot, GlobalConfig, QStringLiteral("shell.json"), detail::ConfigKind::Shell)
SINGLETON(TokensSingleton, TokensRoot, TokenConfig, QStringLiteral("shell-tokens.json"), detail::ConfigKind::Tokens)

#undef SINGLETON

} // namespace caelestia::config
