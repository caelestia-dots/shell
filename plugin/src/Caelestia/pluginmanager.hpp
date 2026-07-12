#pragma once

#include <qfilesystemwatcher.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstringlist.h>
#include <qtimer.h>
#include <qvariant.h>

namespace caelestia {

// Discovers plugins on disk, parses their manifests and exposes their contributions.
// Backed by a single ~/.config/caelestia/plugins.json holding enabled + path + settings.
class PluginManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString shellVersion READ shellVersion CONSTANT)
    Q_PROPERTY(QVariantList plugins READ plugins NOTIFY pluginsChanged)
    Q_PROPERTY(QVariantList loadedPlugins READ loadedPlugins NOTIFY loadedPluginsChanged)
    Q_PROPERTY(QVariantList conflictingPlugins READ conflictingPlugins NOTIFY conflictingPluginsChanged)
    Q_PROPERTY(QStringList enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)

public:
    explicit PluginManager(QObject* parent = nullptr);

    [[nodiscard]] QString shellVersion() const;

    [[nodiscard]] QVariantList plugins() const;

    // The subset of plugins that are valid and enabled, i.e. the ones actually running.
    [[nodiscard]] QVariantList loadedPlugins() const;

    // Plugins shadowed by an earlier plugin declaring the same id (the losing side of a clash).
    [[nodiscard]] QVariantList conflictingPlugins() const;

    [[nodiscard]] QStringList enabled() const;
    void setEnabled(const QStringList& enabled);

    // Flattened contributions of the given type across all enabled + valid plugins.
    // Each entry is the manifest's provides[] object plus a "pluginId" key, with "source" resolved to a file URL.
    Q_INVOKABLE QVariantList extensions(const QString& type) const;

    Q_INVOKABLE QVariantMap settings(const QString& pluginId) const;
    Q_INVOKABLE QVariant setting(
        const QString& pluginId, const QString& key, const QVariant& fallback = QVariant()) const;
    Q_INVOKABLE void setSetting(const QString& pluginId, const QString& key, const QVariant& value);

    Q_INVOKABLE void setPluginEnabled(const QString& pluginId, bool enabled);
    Q_INVOKABLE void reload();

signals:
    void pluginsChanged();
    void loadedPluginsChanged();
    void conflictingPluginsChanged();
    void enabledChanged();
    void settingsChanged(const QString& pluginId);

    // Emitted after a discovery/reload pass finishes populating the plugin list.
    void loaded();

private:
    void loadConfig();
    void saveConfig();
    void rescan();
    void onWatchEvent();
    void updateWatches();
    [[nodiscard]] QStringList searchRoots() const;
    [[nodiscard]] QVariantMap parseManifest(const QString& dir, const QString& path) const;

    QString m_configPath;
    QFileSystemWatcher* m_watcher;
    QTimer* m_saveTimer;
    QTimer* m_reloadTimer;
    bool m_recentlySaved = false;

    QStringList m_enabled;
    QStringList m_extraPaths;
    QVariantMap m_settings;
    QVariantList m_plugins;
    QVariantList m_conflictingPlugins;
};

} // namespace caelestia
