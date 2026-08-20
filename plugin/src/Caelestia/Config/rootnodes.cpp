#include "rootnodes.hpp"

#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

ConfigRoot::ConfigRoot(const QString& path, ConfigRoot* fallback, QObject* parent)
    : RootNode(path, fallback, parent) {
    load();
    bindTokens();
}

void ConfigRoot::bindTokens() {
    qCDebug(lcConfig) << "Binding appearance to token values for" << (key().isEmpty() ? u"global"_s : key());

    auto* const tokens = TokensSingleton::instance()->appearance();
    m_appearance->rounding()->bindTokens(tokens->rounding());
    m_appearance->spacing()->bindTokens(tokens->spacing());
    m_appearance->padding()->bindTokens(tokens->padding());
    m_appearance->anim()->durations()->bindTokens(tokens->animDurations());
}

TokensRoot::TokensRoot(const QString& path, TokensRoot* fallback, QObject* parent)
    : RootNode(path, fallback, parent) {
    load();
}

} // namespace caelestia::config
