#include "plugins.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qregularexpression.h>
#include <qset.h>
#include <qstandardpaths.h>
#include <qurl.h>
#include <qversionnumber.h>

#ifndef CAELESTIA_VERSION
#define CAELESTIA_VERSION ""
#endif

Q_LOGGING_CATEGORY(lcPlugins, "caelestia.plugins", QtInfoMsg)

namespace caelestia {

namespace {

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

QVersionNumber parseVersion(QString str) {
    str = str.trimmed();
    if (str.startsWith(QLatin1Char('v')))
        str.remove(0, 1);
    return QVersionNumber::fromString(str);
}

// Alphanumeric start then alphanumeric + ._-
bool isValidIdSegment(const QString& segment) {
    static const QRegularExpression re(QStringLiteral("^[A-Za-z0-9][A-Za-z0-9._-]*$"));
    return re.match(segment).hasMatch();
}

bool satisfiesRequirement(const QString& requirement, const QVersionNumber& shell) {
    QString req = requirement.trimmed();
    if (req.isEmpty() || shell.isNull())
        return true;

    // Strip operator from front
    QString op;
    while (!req.isEmpty() && (req.front() == u'>' || req.front() == u'<' || req.front() == u'=')) {
        op += req.front();
        req.remove(0, 1);
    }

    const auto required = parseVersion(req);
    if (required.isNull()) {
        qCWarning(lcPlugins) << "Failed to parse plugin version requirement:" << requirement;
        return true;
    }

    const int cmp = QVersionNumber::compare(shell, required);
    if (op == u"<=")
        return cmp <= 0;
    if (op == u"<")
        return cmp < 0;
    if (op == u">")
        return cmp > 0;
    if (op == u"=" || op == u"==")
        return cmp == 0;
    // No operator means >=
    return cmp >= 0;
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
    return m_plugins;
}

QVariantList Plugins::loadedPlugins() const {
    QVariantList result;
    for (const auto& value : m_plugins) {
        const auto plugin = value.toMap();
        if (plugin.value(QStringLiteral("valid")).toBool() && plugin.value(QStringLiteral("enabled")).toBool())
            result.append(plugin);
    }
    return result;
}

QVariantList Plugins::conflictingPlugins() const {
    return m_conflictingPlugins;
}

QStringList Plugins::enabled() const {
    return m_enabled;
}

void Plugins::setEnabled(const QStringList& enabled) {
    if (m_enabled == enabled)
        return;

    m_enabled = enabled;

    // Refresh the per-plugin enabled flags without re-reading manifests.
    for (auto& value : m_plugins) {
        auto plugin = value.toMap();
        plugin.insert(QStringLiteral("enabled"), m_enabled.contains(plugin.value(QStringLiteral("id")).toString()));
        value = plugin;
    }

    emit enabledChanged();
    emit pluginsChanged();
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

QVariantList Plugins::extensions(const QString& type) const {
    QVariantList result;

    for (const auto& value : m_plugins) {
        const auto plugin = value.toMap();
        if (!plugin.value(QStringLiteral("valid")).toBool() || !plugin.value(QStringLiteral("enabled")).toBool())
            continue;

        const auto pluginId = plugin.value(QStringLiteral("id")).toString();
        const auto provides = plugin.value(QStringLiteral("provides")).toList();
        for (const auto& provided : provides) {
            auto ext = provided.toMap();
            if (ext.value(QStringLiteral("type")).toString() != type)
                continue;
            ext.insert(QStringLiteral("pluginId"), pluginId);
            result.append(ext);
        }
    }

    return result;
}

QVariantMap Plugins::settings(const QString& pluginId) const {
    return m_settings.value(pluginId).toMap();
}

QVariant Plugins::setting(const QString& pluginId, const QString& key, const QVariant& fallback) const {
    const auto pluginSettings = m_settings.value(pluginId).toMap();
    return pluginSettings.contains(key) ? pluginSettings.value(key) : fallback;
}

void Plugins::setSetting(const QString& pluginId, const QString& key, const QVariant& value) {
    auto pluginSettings = m_settings.value(pluginId).toMap();
    if (pluginSettings.value(key) == value)
        return;

    pluginSettings.insert(key, value);
    m_settings.insert(pluginId, pluginSettings);

    emit settingsChanged(pluginId);
    m_saveTimer->start();
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

    // Ignore the watcher event triggered by our own write.
    m_recentlySaved = true;
    QTimer::singleShot(500, this, [this] {
        m_recentlySaved = false;
    });

    updateWatches();
}

void Plugins::rescan() {
    QVariantList result;

    const auto roots = searchRoots();
    for (const auto& root : roots) {
        QDir dir(root);
        if (!dir.exists())
            continue;

        const auto subdirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const auto& subdir : subdirs) {
            const QString pluginDir = dir.absoluteFilePath(subdir);
            const QString manifestPath = pluginDir + QStringLiteral("/manifest.json");
            if (QFile::exists(manifestPath))
                result.append(parseManifest(pluginDir, manifestPath));
        }
    }

    // Deduplicate plugins by id (keep first)
    QSet<QString> seenIds;
    QVariantList conflicting;
    for (auto& value : result) {
        auto plugin = value.toMap();
        if (!plugin.value(QStringLiteral("valid")).toBool())
            continue;

        const auto id = plugin.value(QStringLiteral("id")).toString();
        if (seenIds.contains(id)) {
            qCWarning(lcPlugins) << "Duplicate plugin id" << id << "in"
                                 << plugin.value(QStringLiteral("dir")).toString();
            plugin.insert(QStringLiteral("valid"), false);
            plugin.insert(QStringLiteral("error"), QStringLiteral("Shadowed by earlier plugin"));
            value = plugin;
            conflicting.append(plugin);
        } else {
            seenIds.insert(id);
        }
    }

    m_plugins = result;
    m_conflictingPlugins = conflicting;
    emit pluginsChanged();
    emit loadedPluginsChanged();
    emit conflictingPluginsChanged();
    emit loaded();
    updateWatches();
}

QVariantMap Plugins::parseManifest(const QString& dir, const QString& path) const {
    QVariantMap plugin;
    plugin.insert(QStringLiteral("dir"), dir);

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        plugin.insert(QStringLiteral("valid"), false);
        plugin.insert(QStringLiteral("error"), QStringLiteral("Failed to open manifest"));
        return plugin;
    }

    QJsonParseError error{};
    const auto doc = QJsonDocument::fromJson(file.readAll(), &error);
    file.close();

    if (error.error != QJsonParseError::NoError) {
        plugin.insert(QStringLiteral("valid"), false);
        plugin.insert(QStringLiteral("error"), QStringLiteral("Invalid manifest JSON: ") + error.errorString());
        return plugin;
    }

    const auto obj = doc.object();
    const auto name = obj.value(QStringLiteral("name")).toString();

    auto author = obj.value(QStringLiteral("author")).toString();
    if (author.isEmpty()) // Author defaults to "unknown" if not specified
        author = QStringLiteral("unknown");

    // Canonical id is author/name
    const auto id = author + QStringLiteral("/") + name;

    plugin.insert(QStringLiteral("id"), id);
    plugin.insert(QStringLiteral("name"), name);
    plugin.insert(QStringLiteral("version"), obj.value(QStringLiteral("version")).toString());
    plugin.insert(QStringLiteral("description"), obj.value(QStringLiteral("description")).toString());
    plugin.insert(QStringLiteral("author"), author);

    const auto requirement = obj.value(QStringLiteral("requires")).toString();
    plugin.insert(QStringLiteral("requires"), requirement);

    QVariantList provides;
    const auto providesArray = obj.value(QStringLiteral("provides")).toArray();
    for (const auto& provided : providesArray) {
        auto ext = provided.toObject().toVariantMap();
        const auto source = ext.value(QStringLiteral("source")).toString();
        if (!source.isEmpty())
            ext.insert(QStringLiteral("source"), QUrl::fromLocalFile(dir + QStringLiteral("/") + source).toString());
        provides.append(ext);
    }
    plugin.insert(QStringLiteral("provides"), provides);

    plugin.insert(QStringLiteral("enabled"), m_enabled.contains(id));

    bool valid = true;
    QString validationError;
    if (name.isEmpty()) {
        valid = false;
        validationError = QStringLiteral("Manifest is missing 'id'");
    } else if (!isValidIdSegment(name)) {
        valid = false;
        validationError = QStringLiteral("Plugin id '%1' may only contain letters, digits, '.', '_' or '-'").arg(name);
    } else if (!isValidIdSegment(author)) {
        valid = false;
        validationError =
            QStringLiteral("Plugin author '%1' may only contain letters, digits, '.', '_' or '-'").arg(author);
    } else if (!satisfiesRequirement(requirement, parseVersion(QStringLiteral(CAELESTIA_VERSION)))) {
        valid = false;
        validationError =
            QStringLiteral("Requires Caelestia %1 (current is %2)").arg(requirement, QStringLiteral(CAELESTIA_VERSION));
    }

    plugin.insert(QStringLiteral("valid"), valid);
    plugin.insert(QStringLiteral("error"), validationError);

    if (!valid)
        qCWarning(lcPlugins) << "Ignoring plugin" << id << "-" << validationError;

    return plugin;
}

QStringList Plugins::searchRoots() const {
    QStringList roots;
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

} // namespace caelestia
