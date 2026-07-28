#pragma once

#include <qfilesystemwatcher.h>
#include <qhash.h>
#include <qlist.h>
#include <qobject.h>
#include <qpointer.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qqmlparserstatus.h>
#include <qstringlist.h>
#include <qtimer.h>
#include <qvariant.h>

#include "pluginmanifest.hpp"
#include "pluginmodule.hpp"

namespace caelestia::plugins {

class PluginUrlInterceptor;

// Discovers plugins on disk, parses their manifests and exposes their entry points.
// Backed by a single ~/.config/caelestia/plugins.json holding enabled + path + settings.
//
// Also owns hot reloading: it seals every plugin directory, registers each plugin's QML module,
// and hands out the generation numbers that make a re-registration visible to a running engine.
class Plugins : public QObject, public QQmlParserStatus {
    Q_OBJECT
    QML_NAMED_ELEMENT(PluginsBase)
    Q_INTERFACES(QQmlParserStatus)

    Q_PROPERTY(QString shellVersion READ shellVersion CONSTANT)
    Q_PROPERTY(QVariantList plugins READ plugins NOTIFY pluginsChanged)
    Q_PROPERTY(QVariantList loadedPlugins READ loadedPlugins NOTIFY loadedPluginsChanged)
    Q_PROPERTY(QVariantList conflictingPlugins READ conflictingPlugins NOTIFY conflictingPluginsChanged)
    Q_PROPERTY(QStringList enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)

    // Bumped whenever the flattened entry point set could have changed: a plugin appearing or
    // disappearing, its validity or enabled state flipping, or its manifest declaring different
    // entry points. Exists because manifests are now reused across a rescan, so the plugin list
    // itself can stay identical while its contents change.
    Q_PROPERTY(int entryPointsRevision READ entryPointsRevision NOTIFY entryPointsRevisionChanged)

public:
    explicit Plugins(QObject* parent = nullptr);
    ~Plugins() override;

    Q_DISABLE_COPY_MOVE(Plugins)

    void classBegin() override;

    // Discovery waits for this, because sealing plugin directories needs the engine and nothing
    // can look up a plugin qmldir before the singleton that finds the plugins exists.
    void componentComplete() override;

    [[nodiscard]] QString shellVersion() const;

    [[nodiscard]] QVariantList plugins() const;

    // The subset of plugins that are valid and enabled, i.e. the ones actually running.
    [[nodiscard]] QVariantList loadedPlugins() const;

    // Every plugin caught in an id clash, both sides of it: a contested id invalidates all of the
    // plugins declaring it rather than letting search order pick a winner.
    [[nodiscard]] QVariantList conflictingPlugins() const;

    [[nodiscard]] QStringList enabled() const;
    void setEnabled(const QStringList& enabled);

    [[nodiscard]] int entryPointsRevision() const;

    // Flattened entry points of the given type across all enabled + valid plugins.
    Q_INVOKABLE QList<EntryPoint> __entryPoints(caelestia::plugins::EntryPointType::Type type) const;

    Q_INVOKABLE void setPluginEnabled(const QString& pluginId, bool enabled);
    Q_INVOKABLE void reload();

signals:
    void pluginsChanged();
    void loadedPluginsChanged();
    void conflictingPluginsChanged();
    void enabledChanged();
    void entryPointsRevisionChanged();

    // Emitted after a discovery/reload pass finishes populating the plugin list.
    void loaded();

private:
    // Everything about a plugin directory that has to outlive a single rescan. Manifests are
    // reused where they can be, but the generation has to survive even their recreation: it is
    // what keeps every registration's URL distinct, and a counter living on the manifest would
    // reset and hand back a URL whose compiled unit is already cached, so edits would quietly
    // stop taking effect.
    struct PluginRecord {
        PluginManifest* manifest = nullptr;
        PluginModule module;
        int generation = 0;

        // The module's fingerprint plus the manifest fields a reload depends on
        QByteArray fingerprint;
    };

    void loadConfig();
    void saveConfig();

    // `force` reloads every plugin even if nothing about it changed, which is what an explicit
    // reload() asks for. Watch driven rescans leave it false so an unrelated edit costs nothing.
    void rescan(bool force = false);

    // Rescans the tree of every plugin that is going to run, refreshes its warnings, and bumps the
    // generation of each one whose fingerprint moved. A plugin that is invalid or disabled has its
    // record cleared instead, so it is neither registered nor watched until it comes back.
    void updateModules(bool force = false);

    void onWatchEvent(const QString& path);
    void updateWatches();
    [[nodiscard]] QStringList searchRoots() const;

    // The config file's current bytes, empty when it is missing or unreadable
    [[nodiscard]] QByteArray readConfig() const;

    // Directories holding a manifest.json, in search order
    [[nodiscard]] QStringList discoverPluginDirs() const;
    [[nodiscard]] QList<PluginManifest*> loadedManifests() const;
    void bumpEntryPointsRevision();

    QString m_configPath;
    QFileSystemWatcher* m_watcher;
    QTimer* m_saveTimer;
    QTimer* m_reloadTimer;

    // The config bytes as last read from or written to disk, i.e. what the file is believed to
    // hold. Lets a watcher event be attributed by content: equal means the write was ours and
    // there is nothing to reload, and it doubles as the check that skips a no-op write.
    QByteArray m_configOnDisk;

    QPointer<QQmlEngine> m_engine;
    PluginUrlInterceptor* m_interceptor = nullptr;

    QStringList m_enabled;
    QStringList m_extraPaths;
    QVariantMap m_settings;
    QList<PluginManifest*> m_plugins;
    QList<PluginManifest*> m_conflictingPlugins;

    // Records keyed by their directory, which is their stable identity across a rescan.
    // The id cannot be used: it changes when the author edits name/author in the manifest.
    QHash<QString, PluginRecord> m_records;
    int m_entryPointsRevision = 0;

    // Shared by every plugin. All it has to do is keep climbing, since all it has to produce is a
    // URL the engine has not compiled before, and a shared counter is the one thing that cannot
    // be reset by recreating a manifest.
    int m_generationCounter = 0;
};

} // namespace caelestia::plugins
