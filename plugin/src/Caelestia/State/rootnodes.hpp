#pragma once

#include "settings/rootnode.hpp"
#include "settings/singleton.hpp"
#include "common.hpp"

namespace caelestia::state {

class PStateRoot : public settings::RootNode {
    STATE_NODE_NO_CTOR(PStateRoot, settings::RootNode)
    QML_ANONYMOUS

public:
    explicit PStateRoot(const QString& path, PStateRoot* fallback = nullptr, QObject* parent = nullptr);
};

SETTINGS_SINGLETON_DECL(PersistentState, PStateRoot, PersistentState)

} // namespace caelestia::state
