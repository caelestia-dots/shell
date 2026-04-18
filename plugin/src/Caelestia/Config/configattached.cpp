#include "configattached.hpp"
#include "config.hpp"
#include "monitorconfigmanager.hpp"

#include <qquickitem.h>

namespace caelestia::config {

Config::Config(QObject* parent)
    : QQuickAttachedPropertyPropagator(parent) {
    initialize();
}

void Config::classBegin() {}

void Config::componentComplete() {
    m_complete = true;
}

QString Config::screen() const {
    return m_screen;
}

void Config::inheritScreen(const QString& screen) {
    if (screen == m_screen)
        return;

    m_screen = screen;

    if (m_screen.isEmpty())
        m_config = nullptr;
    else
        m_config = MonitorConfigManager::instance()->configForScreen(m_screen);

    propagateScreen();
    emit sourceChanged();
}

void Config::propagateScreen() {
    const auto children = attachedChildren();
    for (auto* const child : children) {
        auto* const config = qobject_cast<Config*>(child);
        if (config)
            config->inheritScreen(m_screen);
    }
}

void Config::attachedParentChange(
    QQuickAttachedPropertyPropagator* newParent, QQuickAttachedPropertyPropagator* oldParent) {
    Q_UNUSED(oldParent);
    auto* const config = qobject_cast<Config*>(newParent);
    if (config)
        inheritScreen(config->screen());
}

#define CONFIG_ATTACHED_GETTER(Type, name)                                                                             \
    const Type* Config::name() const {                                                                                 \
        if (m_config)                                                                                                  \
            return m_config->name();                                                                                   \
        /* Suppress warnings before component is complete if attached to a QQuickItem. */                              \
        /* Raw QObjects are unable to inherit the screen (only QQuickItems can). */                                    \
        if ((m_complete || !qobject_cast<QQuickItem*>(parent())) && parent())                                          \
            qCWarning(lcConfig, "Config.%s accessed without a screen set on %s", #name,                                \
                parent()->metaObject()->className());                                                                  \
        return GlobalConfig::instance()->name();                                                                       \
    }

CONFIG_ATTACHED_GETTER(AppearanceConfig, appearance)
CONFIG_ATTACHED_GETTER(GeneralConfig, general)
CONFIG_ATTACHED_GETTER(BackgroundConfig, background)
CONFIG_ATTACHED_GETTER(BarConfig, bar)
CONFIG_ATTACHED_GETTER(BorderConfig, border)
CONFIG_ATTACHED_GETTER(DashboardConfig, dashboard)
CONFIG_ATTACHED_GETTER(ControlCenterConfig, controlCenter)
CONFIG_ATTACHED_GETTER(LauncherConfig, launcher)
CONFIG_ATTACHED_GETTER(NotifsConfig, notifs)
CONFIG_ATTACHED_GETTER(OsdConfig, osd)
CONFIG_ATTACHED_GETTER(SessionConfig, session)
CONFIG_ATTACHED_GETTER(WInfoConfig, winfo)
CONFIG_ATTACHED_GETTER(LockConfig, lock)
CONFIG_ATTACHED_GETTER(UtilitiesConfig, utilities)
CONFIG_ATTACHED_GETTER(SidebarConfig, sidebar)
CONFIG_ATTACHED_GETTER(ServiceConfig, services)
CONFIG_ATTACHED_GETTER(UserPaths, paths)

#undef CONFIG_ATTACHED_GETTER

GlobalConfig* Config::forScreen(const QString& screen) {
    return GlobalConfig::forScreen(screen);
}

Config* Config::qmlAttachedProperties(QObject* object) {
    return new Config(object);
}

} // namespace caelestia::config
