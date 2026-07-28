#include "plugins.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qset.h>
#include <qstandardpaths.h>

#ifndef CAELESTIA_VERSION
#define CAELESTIA_VERSION ""
#endif

Q_LOGGING_CATEGORY(lcPlugins, "caelestia.plugins", QtInfoMsg)

namespace caelestia::plugins {

namespace {

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

QString pluginDataDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/caelestia/plugins");
}

} // namespace

Plugins::Plugins(QObject* parent)
    : QObject(parent)
    , m_configPath(configDir() + QStringLiteral("plugins.json"))
    , m_watcher(new QFileSystemWatcher(this))
    , m_saveTimer(new QTimer(this))
    , m_reloadTimer(new QTimer(this)) {
    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(300);
    connect(m_saveTimer, &QTimer::timeout, this, &Plugins::saveConfig);

    m_reloadTimer->setSingleShot(true);
    m_reloadTimer->setInterval(50);
    connect(m_reloadTimer, &QTimer::timeout, this, [this] {
        loadConfig();
        rescan();
    });

    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &Plugins::onWatchEvent);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &Plugins::onWatchEvent);

    loadConfig();
    rescan();
}

QString Plugins::shellVersion() const {
    return QStringLiteral(CAELESTIA_VERSION);
}

QVariantList Plugins::plugins() const {
    return QVariant::fromValue(m_plugins).toList();
}

QList<PluginManifest*> Plugins::loadedManifests() const {
    QList<PluginManifest*> result;
    for (auto* const plugin : m_plugins)
        if (plugin->valid() && plugin->enabled())
            result.append(plugin);
    return result;
}

QVariantList Plugins::loadedPlugins() const {
    return QVariant::fromValue(loadedManifests()).toList();
}

QVariantList Plugins::conflictingPlugins() const {
    return QVariant::fromValue(m_conflictingPlugins).toList();
}

QStringList Plugins::enabled() const {
    return m_enabled;
}

void Plugins::setEnabled(const QStringList& enabled) {
    if (m_enabled == enabled)
        return;

    m_enabled = enabled;

    for (auto* const plugin : std::as_const(m_plugins))
        plugin->setEnabled(m_enabled.contains(plugin->id()));

    emit enabledChanged();
    emit loadedPluginsChanged();
    m_saveTimer->start();
}

void Plugins::setPluginEnabled(const QString& pluginId, bool enabled) {
    QStringList next = m_enabled;
    if (enabled) {
        if (!next.contains(pluginId))
            next.append(pluginId);
    } else {
        next.removeAll(pluginId);
    }
    setEnabled(next);
}

QList<EntryPoint> Plugins::__entryPoints(EntryPointType::Type type) const {
    QList<EntryPoint> result;

    for (const auto* plugin : std::as_const(m_plugins)) {
        if (!plugin->valid() || !plugin->enabled())
            continue;

        const auto entryPoints = plugin->entryPoints();
        for (const auto& entryPoint : entryPoints)
            if (entryPoint.type() == type)
                result.append(entryPoint);
    }

    return result;
}

void Plugins::reload() {
    loadConfig();
    rescan();
}

void Plugins::loadConfig() {
    m_enabled.clear();
    m_extraPaths.clear();
    m_settings.clear();

    QFile file(m_configPath);
    if (!file.exists()) {
        emit enabledChanged();
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qCWarning(lcPlugins) << "Failed to open" << m_configPath << file.errorString();
        return;
    }

    QJsonParseError error{};
    const auto doc = QJsonDocument::fromJson(file.readAll(), &error);
    file.close();

    if (error.error != QJsonParseError::NoError) {
        qCWarning(lcPlugins) << "Failed to parse" << m_configPath << error.errorString();
        return;
    }

    const auto obj = doc.object();

    const auto enabledArray = obj.value(QStringLiteral("enabled")).toArray();
    for (const auto& entry : enabledArray)
        m_enabled.append(entry.toString());

    const auto pathArray = obj.value(QStringLiteral("path")).toArray();
    for (const auto& entry : pathArray)
        m_extraPaths.append(entry.toString());

    m_settings = obj.value(QStringLiteral("settings")).toObject().toVariantMap();

    emit enabledChanged();
}

void Plugins::saveConfig() {
    // Merge settings into settings from file so confs for removed plugins are preserved
    for (const auto* plugin : std::as_const(m_plugins))
        if (!plugin->id().isEmpty())
            m_settings.insert(plugin->id(), plugin->settingsValues());

    QJsonObject obj;
    obj.insert(QStringLiteral("enabled"), QJsonArray::fromStringList(m_enabled));
    obj.insert(QStringLiteral("path"), QJsonArray::fromStringList(m_extraPaths));
    obj.insert(QStringLiteral("settings"), QJsonObject::fromVariantMap(m_settings));

    QDir().mkpath(QFileInfo(m_configPath).absolutePath());

    QFile file(m_configPath);
    if (!file.open(QIODevice::WriteOnly)) {
        qCWarning(lcPlugins) << "Failed to write" << m_configPath << file.errorString();
        return;
    }

    file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
    file.close();

    // Everything in memory is now on disk, so a rescan may safely reload settings again.
    for (auto* const plugin : std::as_const(m_plugins))
        plugin->markSettingsSaved();

    // Ignore the watcher event triggered by our own write.
    m_recentlySaved = true;
    QTimer::singleShot(500, this, [this] {
        m_recentlySaved = false;
    });

    updateWatches();
}

QStringList Plugins::discoverPluginDirs() const {
    QStringList dirs;

    const auto roots = searchRoots();
    for (const auto& root : roots) {
        QDir dir(root);
        if (!dir.exists())
            continue;

        const auto subdirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const auto& subdir : subdirs) {
            const QString pluginDir = dir.absoluteFilePath(subdir);
            if (QFile::exists(pluginDir + QStringLiteral("/manifest.json")))
                dirs.append(pluginDir);
        }
    }

    return dirs;
}

void Plugins::rescan() {
    const auto previousPlugins = m_plugins;
    const auto previousConflicting = m_conflictingPlugins;
    const auto previousLoaded = loadedManifests();

    // Reuse manifests instead of remaking all on rescan
    const auto dirs = discoverPluginDirs();
    QList<PluginManifest*> result;
    for (const auto& pluginDir : dirs) {
        auto* manifest = m_pluginsByDir.value(pluginDir);

        if (manifest) {
            manifest->reparse();
        } else {
            manifest = new PluginManifest(pluginDir, pluginDir + QStringLiteral("/manifest.json"), this);

            connect(manifest, &PluginManifest::settingsChanged, this, [this] {
                m_saveTimer->start();
            });
            connect(manifest, &PluginManifest::entryPointsChanged, this, &Plugins::bumpEntryPointsRevision);
            connect(manifest, &PluginManifest::validChanged, this, &Plugins::bumpEntryPointsRevision);
            connect(manifest, &PluginManifest::enabledChanged, this, &Plugins::bumpEntryPointsRevision);

            m_pluginsByDir.insert(pluginDir, manifest);
        }

        manifest->setEnabled(m_enabled.contains(manifest->id()));

        // Don't load from file if there are unsaved settings
        if (!manifest->hasUnsavedSettings())
            manifest->loadSettings(m_settings.value(manifest->id()).toMap());

        if (manifest->hasParseError())
            qCWarning(lcPlugins) << "Ignoring plugin" << manifest->id() << "-" << manifest->error();

        result.append(manifest);
    }

    // Drop manifests whose directory no longer holds a manifest.json
    for (auto it = m_pluginsByDir.begin(); it != m_pluginsByDir.end();) {
        if (dirs.contains(it.key())) {
            ++it;
            continue;
        }

        it.value()->deleteLater();
        it = m_pluginsByDir.erase(it);
    }

    // On id collision keep the first plugin encountered and shadow the rest: later duplicates
    // are marked invalid so they neither load nor contribute, with a warning at the clash.
    // Recomputed from scratch every pass, since removing a plugin can unshadow another.
    QSet<QString> seenIds;
    QList<PluginManifest*> conflicting;
    for (auto* const plugin : result) {
        if (plugin->hasParseError()) {
            plugin->setShadowed(false);
            continue;
        }

        if (seenIds.contains(plugin->id())) {
            qCWarning(lcPlugins) << "Duplicate plugin id" << plugin->id() << "in" << plugin->dir()
                                 << "- shadowed by an earlier plugin";
            plugin->setShadowed(true);
            conflicting.append(plugin);
        } else {
            plugin->setShadowed(false);
            seenIds.insert(plugin->id());
        }
    }

    m_plugins = result;
    m_conflictingPlugins = conflicting;

    if (m_plugins != previousPlugins) {
        emit pluginsChanged();
        bumpEntryPointsRevision();
    }
    if (m_conflictingPlugins != previousConflicting)
        emit conflictingPluginsChanged();
    if (loadedManifests() != previousLoaded)
        emit loadedPluginsChanged();

    emit loaded();

    updateWatches();
}

void Plugins::bumpEntryPointsRevision() {
    m_entryPointsRevision++;
    emit entryPointsRevisionChanged();
}

int Plugins::entryPointsRevision() const {
    return m_entryPointsRevision;
}

QStringList Plugins::searchRoots() const {
    QStringList roots;
    roots.append(pluginDataDir());
    roots.append(configDir() + QStringLiteral("plugins"));

    const auto envPath = qEnvironmentVariable("CAELESTIA_PLUGIN_PATH");
    if (!envPath.isEmpty())
        roots.append(envPath.split(QLatin1Char(':'), Qt::SkipEmptyParts));

    roots.append(m_extraPaths);
    roots.removeDuplicates();
    return roots;
}

void Plugins::updateWatches() {
    const auto watchedDirs = m_watcher->directories();
    if (!watchedDirs.isEmpty())
        m_watcher->removePaths(watchedDirs);
    const auto watchedFiles = m_watcher->files();
    if (!watchedFiles.isEmpty())
        m_watcher->removePaths(watchedFiles);

    const auto cfgDir = QFileInfo(m_configPath).absolutePath();
    if (QFile::exists(cfgDir))
        m_watcher->addPath(cfgDir);
    if (QFile::exists(m_configPath))
        m_watcher->addPath(m_configPath);

    const auto roots = searchRoots();
    for (const auto& root : roots)
        if (QFile::exists(root))
            m_watcher->addPath(root);
}

void Plugins::onWatchEvent() {
    updateWatches();

    if (m_recentlySaved)
        return;

    m_reloadTimer->start();
}

} // namespace caelestia::plugins
