#pragma once

#include "settings/rootnode.hpp"
#include "settings/singleton.hpp"
#include "common.hpp"

namespace caelestia::shell::state {

class PStateRoot : public settings::RootNode {
    STATE_NODE_NO_CTOR(PStateRoot, settings::RootNode)
    QML_ANONYMOUS

    STATE_GLOBAL_PROPERTY(bool, wallpaperPlaying, true)
    STATE_GLOBAL_PROPERTY(bool, doNotDisturb, false)
    STATE_GLOBAL_PROPERTY(bool, keepAwakeEnabled, false)
    STATE_GLOBAL_PROPERTY(qreal, keepAwakeEnabledAt, -1)

public:
    explicit PStateRoot(const QString& path, PStateRoot* fallback = nullptr, QObject* parent = nullptr);
};

class RStateRoot : public settings::RootNode {
    STATE_NODE_NO_CTOR(RStateRoot, settings::RootNode)
    QML_ANONYMOUS

    STATE_GLOBAL_PROPERTY(bool, gameMode, false)

public:
    explicit RStateRoot(const QString& path, RStateRoot* fallback = nullptr, QObject* parent = nullptr);
};

SETTINGS_SINGLETON_DECL(PersistentState, caelestia::shell::state::PStateRoot, PersistentState)
SETTINGS_SINGLETON_DECL(RuntimeState, caelestia::shell::state::RStateRoot, RuntimeState)

} // namespace caelestia::shell::state
