#pragma once

#include <qfilesystemwatcher.h>
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
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString shellVersion READ shellVersion CONSTANT)
    Q_PROPERTY(QList<caelestia::plugins::PluginManifest*> plugins READ plugins NOTIFY pluginsChanged)
    Q_PROPERTY(QList<caelestia::plugins::PluginManifest*> loadedPlugins READ loadedPlugins NOTIFY loadedPluginsChanged)
    Q_PROPERTY(QList<caelestia::plugins::PluginManifest*> conflictingPlugins READ conflictingPlugins NOTIFY
            conflictingPluginsChanged)
    Q_PROPERTY(QStringList enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)

public:
    explicit Plugins(QObject* parent = nullptr);

    [[nodiscard]] QString shellVersion() const;

    [[nodiscard]] QList<PluginManifest*> plugins() const;

    // The subset of plugins that are valid and enabled, i.e. the ones actually running.
    [[nodiscard]] QList<PluginManifest*> loadedPlugins() const;

    // Plugins shadowed by an earlier plugin declaring the same id (the losing side of a clash).
    [[nodiscard]] QList<PluginManifest*> conflictingPlugins() const;

    [[nodiscard]] QStringList enabled() const;
    void setEnabled(const QStringList& enabled);

    // Flattened entry points of the given type across all enabled + valid plugins.
    Q_INVOKABLE QList<EntryPoint> entryPoints(caelestia::plugins::EntryPointType::Type type) const;

    Q_INVOKABLE void setPluginEnabled(const QString& pluginId, bool enabled);
    Q_INVOKABLE void reload();

signals:
    void pluginsChanged();
    void loadedPluginsChanged();
    void conflictingPluginsChanged();
    void enabledChanged();

    // Emitted after a discovery/reload pass finishes populating the plugin list.
    void loaded();

private:
    void loadConfig();
    void saveConfig();
    void rescan();
    void onWatchEvent();
    void updateWatches();
    [[nodiscard]] QStringList searchRoots() const;

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
};

} // namespace caelestia::plugins
