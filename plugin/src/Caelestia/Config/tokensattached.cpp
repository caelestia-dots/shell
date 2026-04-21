#include "tokensattached.hpp"
#include "anim.hpp"
#include "appearanceconfig.hpp"
#include "config.hpp"
#include "monitorconfigmanager.hpp"
#include "tokens.hpp"

#include <qquickitem.h>

namespace caelestia::config {

namespace {

const AppearanceConfig* resolveAppearance(GlobalConfig* config, bool complete, const char* prop, QObject* parent) {
    if (config)
        return config->appearance();
    if ((complete || !qobject_cast<QQuickItem*>(parent)) && parent)
        qCWarning(lcConfig, "Tokens.%s accessed without a screen set on %s", prop, parent->metaObject()->className());
    return GlobalConfig::instance()->appearance();
}

} // namespace

Tokens::Tokens(QObject* parent)
    : QQuickAttachedPropertyPropagator(parent)
    , m_anim(new AnimTokens(this)) {
    bindAnim();
    initialize();
}

void Tokens::classBegin() {}

void Tokens::componentComplete() {
    m_complete = true;
}

QString Tokens::screen() const {
    return m_screen;
}

void Tokens::inheritScreen(const QString& screen) {
    if (screen == m_screen)
        return;

    m_screen = screen;

    if (m_screen.isEmpty()) {
        m_config = nullptr;
        m_tokens = nullptr;
    } else {
        m_config = MonitorConfigManager::instance()->configForScreen(m_screen);
        m_tokens = MonitorConfigManager::instance()->tokensForScreen(m_screen);
    }

    propagateScreen();
    emit sourceChanged();
}

void Tokens::propagateScreen() {
    const auto children = attachedChildren();
    for (auto* const child : children) {
        auto* const tokens = qobject_cast<Tokens*>(child);
        if (tokens)
            tokens->inheritScreen(m_screen);
    }
}

void Tokens::attachedParentChange(
    QQuickAttachedPropertyPropagator* newParent, QQuickAttachedPropertyPropagator* oldParent) {
    Q_UNUSED(oldParent);
    auto* const tokens = qobject_cast<Tokens*>(newParent);
    if (tokens)
        inheritScreen(tokens->screen());
}

void Tokens::bindAnim() {
    m_anim->bindDurations(GlobalConfig::instance()->appearance()->anim()->durations());
    m_anim->bindCurves(TokenConfig::instance()->appearance()->curves());
}

#define TOKENS_ATTACHED_GETTER(Type, name)                                                                             \
    const Type* Tokens::name() const {                                                                                 \
        auto* a = resolveAppearance(m_config, m_complete, #name, parent());                                            \
        return a ? a->name() : nullptr;                                                                                \
    }

TOKENS_ATTACHED_GETTER(AppearanceRounding, rounding)
TOKENS_ATTACHED_GETTER(AppearanceSpacing, spacing)
TOKENS_ATTACHED_GETTER(AppearancePadding, padding)
TOKENS_ATTACHED_GETTER(AppearanceFont, font)

#undef TOKENS_ATTACHED_GETTER

const AppearanceTransparency* Tokens::transparency() const {
    return GlobalConfig::instance()->appearance()->transparency(); // Transparency is always global
}

const SizeTokens* Tokens::sizes() const {
    if (m_tokens)
        return m_tokens->sizes();
    if ((m_complete || !qobject_cast<QQuickItem*>(parent())) && parent())
        qCWarning(lcConfig, "Tokens.sizes accessed without a screen set on %s", parent()->metaObject()->className());
    return TokenConfig::instance()->sizes();
}

const AnimTokens* Tokens::anim() const {
    return m_anim;
}

TokenConfig* Tokens::forScreen(const QString& screen) {
    return TokenConfig::forScreen(screen);
}

Tokens* Tokens::qmlAttachedProperties(QObject* object) {
    return new Tokens(object);
}

} // namespace caelestia::config
