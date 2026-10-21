#include "rootnodes.hpp"

namespace caelestia::state {

using Qt::StringLiterals::operator""_s;

namespace {

QString nameFor(const QString& key) {
    return key.isEmpty() ? u"global"_s : key;
}

struct Handler {
    static void loaded(settings::RootNode* layer, const QString& screen) {
        qCDebug(lcState) << "Loaded state for" << nameFor(screen) << "with" << layer->diagnostics().count() << "issues";
    }

    static void loadFailed(const QString& error, const QString& screen) {
        qCWarning(lcState) << "Failed to load state for" << nameFor(screen) << ':' << error;
    }

    static void saveFailed(const QString& error, const QString& screen) {
        qCWarning(lcState) << "Failed to save state for" << nameFor(screen) << ':' << error;
    }
};

} // namespace

PStateRoot::PStateRoot(const QString& path, PStateRoot* fallback, QObject* parent)
    : RootNode(false, path, fallback, parent) {}

RStateRoot::RStateRoot(const QString& path, RStateRoot* fallback, QObject* parent)
    : RootNode(false, path, fallback, parent) {}

SETTINGS_SINGLETON_IMPL(PersistentState, PStateRoot, stateDir(), monitorStateDir(), u"state.json"_s, Handler)
SETTINGS_SINGLETON_IMPL(RuntimeState, RStateRoot, runtimeDir(), monitorRuntimeDir(), u"state.json"_s, Handler)

} // namespace caelestia::state
