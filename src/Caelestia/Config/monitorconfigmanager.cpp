#include "monitorconfigmanager.hpp"
#include "config.hpp"
#include "tokens.hpp"

#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString monitorConfigDir(const QString& screen) {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) +
           QStringLiteral("/caelestia/monitors/") + screen + QStringLiteral("/");
}

} // namespace

MonitorConfigManager::MonitorConfigManager(QObject* parent)
    : QObject(parent) {}

MonitorConfigManager* MonitorConfigManager::instance() {
    static MonitorConfigManager instance;
    return &instance;
}

MonitorConfigManager* MonitorConfigManager::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

GlobalConfig* MonitorConfigManager::configForScreen(const QString& screen) {
    auto& overlay = m_overlays[screen];
    if (!overlay.config) {
        auto dir = monitorConfigDir(screen);
        overlay.config = new GlobalConfig(GlobalConfig::instance(), dir + QStringLiteral("shell.json"), screen, this);

        auto* const global = GlobalConfig::instance();
        connect(overlay.config, &GlobalConfig::loaded, global, &GlobalConfig::loaded);
        connect(overlay.config, &GlobalConfig::saved, global, &GlobalConfig::saved);
        connect(overlay.config, &GlobalConfig::loadFailed, global, &GlobalConfig::loadFailed);
        connect(overlay.config, &GlobalConfig::saveFailed, global, &GlobalConfig::saveFailed);
        connect(overlay.config, &GlobalConfig::unknownOption, global, &GlobalConfig::unknownOption);
    }
    return overlay.config;
}

TokenConfig* MonitorConfigManager::tokensForScreen(const QString& screen) {
    auto& overlay = m_overlays[screen];
    if (!overlay.tokens) {
        auto dir = monitorConfigDir(screen);
        overlay.tokens =
            new TokenConfig(TokenConfig::instance(), dir + QStringLiteral("shell-tokens.json"), screen, this);

        auto* const global = TokenConfig::instance();
        connect(overlay.tokens, &TokenConfig::loaded, global, &TokenConfig::loaded);
        connect(overlay.tokens, &TokenConfig::saved, global, &TokenConfig::saved);
        connect(overlay.tokens, &TokenConfig::loadFailed, global, &TokenConfig::loadFailed);
        connect(overlay.tokens, &TokenConfig::saveFailed, global, &TokenConfig::saveFailed);
        connect(overlay.tokens, &TokenConfig::unknownOption, global, &TokenConfig::unknownOption);
    }
    return overlay.tokens;
}

} // namespace caelestia::config
