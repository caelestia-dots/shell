#include "plugins.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qstandardpaths.h>

#include "pluginurlinterceptor.hpp"

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
    m_reloadTimer->setInterval(200);
    connect(m_reloadTimer, &QTimer::timeout, this, [this] {
        loadConfig();
        rescan();
    });

    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &Plugins::onWatchEvent);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &Plugins::onWatchEvent);
}

Plugins::~Plugins() {
    // The engine keeps a raw pointer to the interceptor, and it may outlive this singleton
    if (m_engine && m_interceptor)
        m_engine->removeUrlInterceptor(m_interceptor);
}

void Plugins::classBegin() {}

void Plugins::componentComplete() {
    m_engine = qmlEngine(this);

    if (m_engine) {
        // Parented here so it dies with this engine generation rather than dangling
        m_interceptor = new PluginUrlInterceptor(this);
        m_engine->addUrlInterceptor(m_interceptor);
    } else {
        qCWarning(lcPlugins)
            << "No QML engine available - unable to seal plugin directories, hot reload may not work as expected";
    }

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

    // Update modules and watches before notifying QML
    updateModules();
    updateWatches();

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
    rescan(true);
}

void Plugins::loadConfig() {
    QFile file(m_configPath);

    // No file at all is not a failure, it just means defaults
    if (!file.exists()) {
        m_configOnDisk.clear();
        m_enabled.clear();
        m_extraPaths.clear();
        m_settings.clear();
        emit enabledChanged();
        return;
    }

    // Every failure below leaves the last good config in place. Clearing first and bailing would
    // disable every plugin, and the next save would write that empty state over the real one.
    if (!file.open(QIODevice::ReadOnly)) {
        qCWarning(lcPlugins) << "Failed to open" << m_configPath << file.errorString();
        return;
    }

    const auto data = file.readAll();
    file.close();

    // Recorded even when it does not parse: re-reading an unchanged broken file achieves nothing,
    // and the next save overwrites it anyway.
    m_configOnDisk = data;

    QJsonParseError error{};
    const auto doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        qCWarning(lcPlugins) << "Failed to parse" << m_configPath << error.errorString();
        return;
    }

    const auto obj = doc.object();

    QStringList enabled;
    const auto enabledArray = obj.value(QStringLiteral("enabled")).toArray();
    for (const auto& entry : enabledArray)
        enabled.append(entry.toString());

    QStringList extraPaths;
    const auto pathArray = obj.value(QStringLiteral("path")).toArray();
    for (const auto& entry : pathArray)
        extraPaths.append(entry.toString());

    // Committed only once the whole file has parsed, so a half read or malformed config never
    // becomes the in memory state, and therefore never reaches disk on the next save.
    m_enabled = std::move(enabled);
    m_extraPaths = std::move(extraPaths);
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

    const auto json = QJsonDocument(obj).toJson(QJsonDocument::Indented);

    // Nothing moved, so no write, no watcher event to recognise and nothing new to watch. Falls
    // through to the dirty flags below: identical content means memory already matches the file.
    if (json != m_configOnDisk) {
        QDir().mkpath(QFileInfo(m_configPath).absolutePath());

        QFile file(m_configPath);
        if (!file.open(QIODevice::WriteOnly)) {
            qCWarning(lcPlugins) << "Failed to write" << m_configPath << file.errorString();
            return;
        }

        file.write(json);
        file.close();

        // Checked after the close, since a buffered write can fail there rather than above, and
        // recording content that never reached the disk would make every later comparison lie.
        if (file.error() != QFile::NoError) {
            qCWarning(lcPlugins) << "Failed to write" << m_configPath << file.errorString();
            return;
        }

        m_configOnDisk = json;

        updateWatches();
    }

    // Everything in memory is now on disk, so a rescan may safely reload settings again. Skipped
    // on a failed write, so the values stay dirty and a rescan does not reload over them.
    for (auto* const plugin : std::as_const(m_plugins))
        plugin->markSettingsSaved();
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

void Plugins::rescan(bool force) {
    const auto previousPlugins = m_plugins;
    const auto previousConflicting = m_conflictingPlugins;
    const auto previousLoaded = loadedManifests();

    const auto dirs = discoverPluginDirs();

    // Sealed before anything in a newly discovered plugin can compile, since a directory that
    // resolves its types by filename once keeps doing so for the rest of the process. Every plugin
    // found, enabled or not, is sealed otherwise the first compile after an enable would beat the seal to it.
    if (m_interceptor)
        m_interceptor->setRoots(dirs);

    // Reuse manifests instead of remaking all on rescan
    QList<PluginManifest*> result;
    for (const auto& pluginDir : dirs) {
        auto& record = m_records[pluginDir];
        auto* manifest = record.manifest;

        if (manifest) {
            manifest->reparse();
        } else {
            manifest = new PluginManifest(pluginDir, pluginDir + QStringLiteral("/manifest.json"), this);

            connect(manifest, &PluginManifest::settingsValuesChanged, this, [this] {
                m_saveTimer->start();
            });
            connect(manifest, &PluginManifest::entryPointsChanged, this, &Plugins::bumpEntryPointsRevision);
            connect(manifest, &PluginManifest::validChanged, this, &Plugins::bumpEntryPointsRevision);
            connect(manifest, &PluginManifest::enabledChanged, this, &Plugins::bumpEntryPointsRevision);

            record.manifest = manifest;
        }

        manifest->setEnabled(m_enabled.contains(manifest->id()));

        // Don't load from file if there are unsaved settings
        if (!manifest->hasUnsavedSettings())
            manifest->loadSettings(m_settings.value(manifest->id()).toMap());

        if (manifest->hasParseError())
            qCWarning(lcPlugins) << "Ignoring plugin" << manifest->id() << "-" << manifest->error();

        result.append(manifest);
    }

    // Drop records whose directory no longer holds a manifest.json. This leaks, but Qt does not have a
    // public unregister API so we have to deal with it.
    for (auto it = m_records.begin(); it != m_records.end();) {
        if (dirs.contains(it.key())) {
            ++it;
            continue;
        }

        it.value().manifest->deleteLater();
        it = m_records.erase(it);
    }

    // Conflicting ids will disable all plugins with the contested id
    QHash<QString, QList<PluginManifest*>> byId;
    for (auto* const plugin : result)
        if (!plugin->hasParseError())
            byId[plugin->id()].append(plugin);

    // Recomputed from scratch every pass, since removing a claimant revalidates the rest.
    QList<PluginManifest*> conflicting;
    for (auto* const plugin : result) {
        const auto claimants = plugin->hasParseError() ? QList<PluginManifest*>() : byId.value(plugin->id());
        if (claimants.size() < 2) {
            plugin->setConflicts({});
            continue;
        }

        QStringList others;
        for (const auto* claimant : claimants)
            if (claimant != plugin)
                others.append(claimant->dir());

        qCWarning(lcPlugins) << "Duplicate plugin id" << plugin->id() << "in" << plugin->dir() << "- also declared by"
                             << others.join(QStringLiteral(", "));

        plugin->setConflicts(others);
        conflicting.append(plugin);
    }

    m_plugins = result;
    m_conflictingPlugins = conflicting;

    // After the id grouping, so a plugin caught in a clash registers nothing
    updateModules(force);

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

void Plugins::updateModules(bool force) {
    // Every plugin's root URI, so a file importing another plugin's module can be flagged
    QStringList uris;
    for (const auto* plugin : std::as_const(m_plugins))
        if (plugin->valid())
            uris.append(plugin->moduleUri());

    QList<PluginManifest*> bumped;

    for (auto* const plugin : std::as_const(m_plugins)) {
        auto& record = m_records[plugin->dir()];

        const auto valid = plugin->valid();
        const auto previousUri = record.module.uri();
        const auto previousWarnings = plugin->warnings();

        QStringList warnings;

        // Renaming the plugin renames its module, but the author's own imports can still name the old
        // one and keep resolving to it until the QML engine dies. We can't do anything about that, so send
        // a warning instead.
        if (valid && !previousUri.isEmpty() && previousUri != plugin->moduleUri())
            warnings.append(QStringLiteral(
                "Plugin was renamed from '%1' to '%2'. Imports may not work as expected until next restart.")
                    .arg(previousUri, plugin->moduleUri()));

        // Don't register plugins which are not enabled. Use the enabled map instead of the manifest
        // as this is called before the manifest is flipped.
        const auto active = valid && m_enabled.contains(plugin->id());

        bool reload = false;

        if (active) {
            auto others = uris;
            others.removeAll(plugin->moduleUri());

            record.module = PluginModule(plugin->dir(), plugin->moduleUri());
            record.module.scan(others);
            warnings.append(record.module.warnings());

            // Manifest fields that pick files to load which may not necessarily be valid QML components (and are
            // therefore skipped in the tree walk)
            // e.g. a lowercase named QML file
            auto fingerprint = record.module.fingerprint();
            fingerprint.append(plugin->declaredSettings().toUtf8());
            fingerprint.append('\0');
            fingerprint.append(plugin->declaredSettingsUi().toUtf8());

            reload = fingerprint != record.fingerprint || force;
            if (reload)
                record.fingerprint = std::move(fingerprint);
        } else {
            record.module = PluginModule();
            record.fingerprint.clear();
        }

        plugin->setWarnings(warnings);

        // Re-logged on every reload, since a warning describes a standing problem with the plugin
        // rather than something that just happened. Also logged when only the warnings moved,
        // which is how another plugin appearing can make a cross plugin import visible.
        if (reload || warnings != previousWarnings)
            for (const auto& warning : std::as_const(warnings))
                qCWarning(lcPlugins, "[%s] %s", qUtf8Printable(plugin->id()), qUtf8Printable(warning));

        if (!reload)
            continue;

        record.generation = ++m_generationCounter;

        // Before any fan-out, or an import resolves the previous registration
        record.module.registerTypes(record.generation);

        bumped.append(plugin);
    }

    // Fanned out only once every module is registered, and synchronously, so no live loader sees
    // a half updated set of registrations and no loader created mid-pass joins the wrong cohort.
    for (auto* const plugin : std::as_const(bumped))
        plugin->setGeneration(m_records[plugin->dir()].generation);
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

    QStringList paths;
    paths.append(QFileInfo(m_configPath).absolutePath());
    paths.append(m_configPath);
    paths.append(searchRoots());

    // Directories report files appearing and disappearing; the files themselves report edits,
    // which a directory watch does not. The module's own walk decides what is worth watching, so
    // dotfiles and .git stay out of it.
    for (auto it = m_records.cbegin(); it != m_records.cend(); ++it) {
        paths.append(it.key());
        paths.append(it.key() + QStringLiteral("/manifest.json"));
        paths.append(it.value().module.watchPaths());
    }

    paths.removeDuplicates();

    for (const auto& path : std::as_const(paths))
        if (QFile::exists(path))
            m_watcher->addPath(path);
}

QByteArray Plugins::readConfig() const {
    QFile file(m_configPath);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return file.readAll();
}

void Plugins::onWatchEvent(const QString& path) {
    updateWatches();

    // Only ignore writes to the config file, checked by content
    if (path == m_configPath && readConfig() == m_configOnDisk)
        return;

    m_reloadTimer->start();
}

} // namespace caelestia::plugins
