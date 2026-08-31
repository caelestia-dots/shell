#include "rootnodes.hpp"

#include "core/toaster.hpp"
#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

namespace {

QString nameFor(const QString& key) {
    return key.isEmpty() ? u"global"_s : key;
}

QString forScreen(const QString& global, const QString& layer, const QString& screen) {
    return screen.isEmpty() ? global : layer.arg(screen);
}

} // namespace

namespace detail {

void loaded(ConfigKind kind, settings::RootNode* layer, const QString& screen) {
    if (kind != ConfigKind::Shell || !screen.isEmpty())
        return;

    auto* const config = static_cast<ConfigRoot*>(layer);
    if (!config->utilities()->toasts()->configLoaded())
        return;

    const auto issues = config->diagnostics().count();
    // TODO: tr when translations added
    const auto message = issues > 0
                             ? u"Config loaded with %1 issue%2."_s.arg(issues).arg(issues > 1 ? u"s"_s : QString())
                             : u"Config loaded successfully!"_s;
    Toaster::instance()->toast(u"Config loaded"_s, message, issues > 0 ? u"settings_alert"_s : u"rule_settings"_s,
        issues > 0 ? Toast::Type::Warning : Toast::Type::Info);
}

void loadFailed(ConfigKind kind, const QString& error, const QString& screen) {
    // TODO: tr when translations added
    const auto title =
        kind == ConfigKind::Tokens
            ? forScreen(u"Failed to parse token config"_s, u"Failed to parse token config for %1"_s, screen)
            : forScreen(u"Failed to parse config"_s, u"Failed to parse config for %1"_s, screen);
    Toaster::instance()->toast(title, error, u"settings_alert"_s, Toast::Type::Warning);
}

void saveFailed(ConfigKind kind, const QString& error, const QString& screen) {
    if (kind != ConfigKind::Shell)
        return;

    // TODO: tr when translations added
    const auto title = forScreen(u"Failed to save config"_s, u"Failed to save config for %1"_s, screen);
    Toaster::instance()->toast(title, error, u"settings_alert"_s, Toast::Type::Error);
}

} // namespace detail

ConfigRoot::ConfigRoot(const QString& path, ConfigRoot* fallback, QObject* parent)
    : RootNode(path, fallback, parent) {
    bindTokens();
    qCDebug(lcConfig) << "Created config root for" << nameFor(key());
}

void ConfigRoot::bindTokens() {
    qCDebug(lcConfig) << "Binding appearance to token values for" << nameFor(key());

    auto* const tokens = TokensSingleton::instance()->appearance();
    m_appearance->rounding()->bindTokens(tokens->rounding());
    m_appearance->spacing()->bindTokens(tokens->spacing());
    m_appearance->padding()->bindTokens(tokens->padding());
    m_appearance->anim()->durations()->bindTokens(tokens->animDurations());
}

TokensRoot::TokensRoot(const QString& path, TokensRoot* fallback, QObject* parent)
    : RootNode(path, fallback, parent) {
    qCDebug(lcConfig) << "Created tokens root for" << nameFor(key());
}

#define SINGLETON_IMPL(Type, Root, file, kind)                                                                         \
    Type* Type::instance() {                                                                                           \
        static Type instance;                                                                                          \
        return &instance;                                                                                              \
    }                                                                                                                  \
                                                                                                                       \
    Type* Type::create(QQmlEngine*, QJSEngine*) {                                                                      \
        QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);                                          \
        return instance();                                                                                             \
    }                                                                                                                  \
                                                                                                                       \
    Root* Type::forScreen(const QString& screen) {                                                                     \
        bool created;                                                                                                  \
        auto* const layer = m_layers.get(screen, this, &created);                                                      \
        if (created)                                                                                                   \
            initLayer(layer);                                                                                          \
        return layer;                                                                                                  \
    }                                                                                                                  \
                                                                                                                       \
    Type::Type(QObject* parent)                                                                                        \
        : Root(configDir() + QLatin1Char('/') + file, nullptr, parent)                                                 \
        , m_layers(monitorConfigDir(), file, this) {                                                                   \
        initLayer(this);                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
    void Type::onTreeLoaded(settings::RootNode* layer) {                                                               \
        detail::loaded(kind, layer, m_layers.nameFor(static_cast<Root*>(layer)));                                      \
    }                                                                                                                  \
                                                                                                                       \
    void Type::onTreeLoadFailed(settings::RootNode* layer, const QString& error) {                                     \
        detail::loadFailed(kind, error, m_layers.nameFor(static_cast<Root*>(layer)));                                  \
    }                                                                                                                  \
                                                                                                                       \
    void Type::onTreeSaveFailed(settings::RootNode* layer, const QString& error) {                                     \
        detail::saveFailed(kind, error, m_layers.nameFor(static_cast<Root*>(layer)));                                  \
    }                                                                                                                  \
                                                                                                                       \
    void Type::initLayer(Root* layer) {                                                                                \
        QObject::connect(layer, &Root::treeLoaded, this, &Type::onTreeLoaded);                                         \
        QObject::connect(layer, &Root::treeLoadFailed, this, &Type::onTreeLoadFailed);                                 \
        QObject::connect(layer, &Root::treeSaveFailed, this, &Type::onTreeSaveFailed);                                 \
        layer->load();                                                                                                 \
    }

SINGLETON_IMPL(ConfigSingleton, ConfigRoot, QStringLiteral("shell.json"), detail::ConfigKind::Shell)
SINGLETON_IMPL(TokensSingleton, TokensRoot, QStringLiteral("shell-tokens.json"), detail::ConfigKind::Tokens)

#undef SINGLETON_IMPL

} // namespace caelestia::config
