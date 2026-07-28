#pragma once

#include <qfilesystemwatcher.h>
#include <qhash.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstringlist.h>
#include <qtimer.h>
#include <qvariant.h>

#include "pluginmanifest.hpp"

namespace caelestia::plugins {

// Discovers plugins on disk, parses their manifests and exposes their entry points.
// Backed by a single ~/.config/caelestia/plugins.json holding enabled + path + settings.
class Plugins : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(PluginsBase)

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

    [[nodiscard]] QString shellVersion() const;

    [[nodiscard]] QVariantList plugins() const;

    // The subset of plugins that are valid and enabled, i.e. the ones actually running.
    [[nodiscard]] QVariantList loadedPlugins() const;

    // Plugins shadowed by an earlier plugin declaring the same id (the losing side of a clash).
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
    void loadConfig();
    void saveConfig();
    void rescan();
    void onWatchEvent();
    void updateWatches();
    [[nodiscard]] QStringList searchRoots() const;

    // Directories holding a manifest.json, in search order (earlier roots win an id clash)
    [[nodiscard]] QStringList discoverPluginDirs() const;
    [[nodiscard]] QList<PluginManifest*> loadedManifests() const;
    void bumpEntryPointsRevision();

    QString m_configPath;
    QFileSystemWatcher* m_watcher;
    QTimer* m_saveTimer;
    QTimer* m_reloadTimer;
    bool m_recentlySaved = false;

    QStringList m_enabled;
    QStringList m_extraPaths;
    QVariantMap m_settings;
    QList<PluginManifest*> m_plugins;
    QList<PluginManifest*> m_conflictingPlugins;

    // Manifests keyed by their directory, which is their stable identity across a rescan.
    // The id cannot be used: it changes when the author edits name/author in the manifest.
    QHash<QString, PluginManifest*> m_pluginsByDir;
    int m_entryPointsRevision = 0;
};

} // namespace caelestia::plugins
