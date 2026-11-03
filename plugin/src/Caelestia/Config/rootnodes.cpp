#include "rootnodes.hpp"

#include "core/toaster.hpp"
#include "util/i18n.hpp"
#include "common.hpp"

namespace caelestia::shell::config {

using Qt::StringLiterals::operator""_s;

namespace detail {

using util::i18n::mark;
using util::i18n::markN;

void loaded(ConfigKind kind, settings::RootNode* layer, const QString& screen) {
    if (kind != ConfigKind::Shell || !screen.isEmpty())
        return;

    const auto* config = static_cast<ConfigRoot*>(layer);
    if (!config->utilities()->toasts()->configLoaded())
        return;

    const auto issues = static_cast<int>(config->diagnostics().count());
    const auto message = issues > 0
                             ? markN(u"Config loaded with %n issue."_s, u"Config loaded with %n issues."_s, issues)
                             : mark(u"Config loaded successfully!"_s);
    Toaster::instance()->toast(mark(u"Config loaded"_s), message, issues > 0 ? u"settings_alert"_s : u"rule_settings"_s,
        issues > 0 ? Toast::Type::Warning : Toast::Type::Info);
}

void loadFailed(ConfigKind kind, const QString& error, const QString& screen) {
    QString title;
    if (kind == ConfigKind::Tokens)
        title = screen.isEmpty() ? mark(u"Failed to parse token config"_s)
                                 // TRANSLATORS: %1 = a monitor name
                                 : mark(u"Failed to parse token config for %1"_s, { screen });
    else
        title =
            // TRANSLATORS: %1 = a monitor name
            screen.isEmpty() ? mark(u"Failed to parse config"_s) : mark(u"Failed to parse config for %1"_s, { screen });
    Toaster::instance()->toast(title, error, u"settings_alert"_s, Toast::Type::Warning);
}

void saveFailed(ConfigKind kind, const QString& error, const QString& screen) {
    if (kind != ConfigKind::Shell)
        return;

    const auto title =
        // TRANSLATORS: %1 = a monitor name
        screen.isEmpty() ? mark(u"Failed to save config"_s) : mark(u"Failed to save config for %1"_s, { screen });
    Toaster::instance()->toast(title, error, u"settings_alert"_s, Toast::Type::Error);
}

} // namespace detail

ConfigRoot::ConfigRoot(const QString& path, ConfigRoot* fallback, QObject* parent)
    : RootNode(true, path, fallback, parent)
    , m_fontTokens(new FontTokens(this)) {
    bindTokens();
}

const FontTokens* ConfigRoot::fontTokens() const {
    return m_fontTokens;
}

void ConfigRoot::bindTokens() {
    const auto* tokens = TokensSingleton::instance()->appearance();
    m_appearance->rounding()->bindTokens(tokens->rounding());
    m_appearance->spacing()->bindTokens(tokens->spacing());
    m_appearance->padding()->bindTokens(tokens->padding());
    m_appearance->anim()->durations()->bindTokens(tokens->animDurations());

    m_fontTokens->bindFont(m_appearance->font());
}

TokensRoot::TokensRoot(const QString& path, TokensRoot* fallback, QObject* parent)
    : RootNode(true, path, fallback, parent) {}

SETTINGS_SINGLETON_IMPL(ConfigSingleton, ConfigRoot, configDir(), monitorConfigDir(), u"shell.json"_s,
    detail::Handler<detail::ConfigKind::Shell>)
SETTINGS_SINGLETON_IMPL(TokensSingleton, TokensRoot, configDir(), monitorConfigDir(), u"shell-tokens.json"_s,
    detail::Handler<detail::ConfigKind::Tokens>)

} // namespace caelestia::shell::config
