#include "rootnodes.hpp"

#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

namespace {

QString nameFor(const QString& key) {
    return key.isEmpty() ? u"global"_s : key;
}

} // namespace

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

} // namespace caelestia::config
