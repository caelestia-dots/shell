#include "pluginmanifest.hpp"

#include <qfile.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qqmlcomponent.h>
#include <qqmlengine.h>
#include <qurl.h>
#include <qversionnumber.h>

#include "pluginmodule.hpp"
#include "settingmeta.hpp"
#include "settingsobject.hpp"

#ifndef CAELESTIA_VERSION
#define CAELESTIA_VERSION ""
#endif

namespace caelestia::plugins {

namespace {

QVersionNumber parseVersion(QString str) {
    str = str.trimmed();
    if (str.startsWith(QLatin1Char('v')))
        str.remove(0, 1);
    return QVersionNumber::fromString(str);
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
    if (required.isNull())
        return true;

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

PluginManifest::PluginManifest(const QString& dir, const QString& path, QObject* parent)
    : QObject(parent)
    , m_dir(dir)
    , m_path(path) {
    parse();
}

void PluginManifest::parse() {
    const auto wasValid = valid();
    const auto wasError = error();

    QString id;
    QString name;
    QString version;
    QString icon;
    QString description;
    QString author;
    QString requirement;
    QString settingsSource;
    QString settingsUiSource;
    QList<EntryPoint> entryPoints;
    QString parseError;

    QFile file(m_path);
    QJsonParseError jsonError{};
    QJsonDocument doc;

    if (!file.open(QIODevice::ReadOnly)) {
        parseError = QStringLiteral("Failed to open manifest");
    } else {
        doc = QJsonDocument::fromJson(file.readAll(), &jsonError);
        file.close();

        if (jsonError.error != QJsonParseError::NoError)
            parseError = QStringLiteral("Invalid manifest JSON: ") + jsonError.errorString();
    }

    if (parseError.isEmpty()) {
        const auto obj = doc.object();
        name = obj.value(QStringLiteral("name")).toString();

        author = obj.value(QStringLiteral("author")).toString();
        if (author.isEmpty()) // Author defaults to "unknown" if not specified
            author = QStringLiteral("unknown");

        // Canonical id is author/name. Lowercased here rather than when deriving the module URI,
        // so the duplicate id check catches Foo/Bar clashing with foo/bar too.
        id = (author + QStringLiteral("/") + name).toLower();
        version = obj.value(QStringLiteral("version")).toString();
        icon = obj.value(QStringLiteral("icon")).toString();
        description = obj.value(QStringLiteral("description")).toString();
        requirement = obj.value(QStringLiteral("requires")).toString();

        settingsSource = obj.value(QStringLiteral("settings")).toString();
        settingsUiSource = obj.value(QStringLiteral("settingsUi")).toString();

        // Each entry point parses itself; the first that fails invalidates the whole manifest.
        QString entryPointError;
        const auto entryPointsArray = obj.value(QStringLiteral("entryPoints")).toArray();
        for (const auto& declared : entryPointsArray) {
            const EntryPoint entryPoint(declared.toObject(), this);
            if (entryPointError.isEmpty())
                entryPointError = entryPoint.error();
            entryPoints.append(entryPoint);
        }

        // Both halves of the id become module URI segments, so they inherit QML's constraint on
        // them: anything else is a parse error at the author's import, not at registration.
        if (name.isEmpty())
            parseError = QStringLiteral("Manifest is missing 'name'");
        else if (!PluginModule::isValidUriSegment(name))
            parseError = QStringLiteral("Plugin name '%1' may only contain letters, digits or '_', and "
                                        "may not start with a digit")
                             .arg(name);
        else if (!PluginModule::isValidUriSegment(author))
            parseError = QStringLiteral("Plugin author '%1' may only contain letters, digits or '_', and "
                                        "may not start with a digit")
                             .arg(author);
        else if (!entryPointError.isEmpty())
            parseError = entryPointError;
        else if (!satisfiesRequirement(requirement, parseVersion(QStringLiteral(CAELESTIA_VERSION))))
            parseError = QStringLiteral("Requires Caelestia %1 (current is %2)")
                             .arg(requirement, QStringLiteral(CAELESTIA_VERSION));
    }

    // Set before the field assignments so anything reacting to those signals already observes
    // the new validity rather than the previous pass's.
    m_parseError = parseError;

    // Assign values to fields
#define ASSIGN(field, value, sig)                                                                                      \
    if ((field) != (value)) {                                                                                          \
        (field) = (value);                                                                                             \
        Q_EMIT sig();                                                                                                  \
    }

    if (m_id != id) {
        m_id = id;
        emit idChanged();
        emit moduleUriChanged();
    }

    ASSIGN(m_name, name, nameChanged)
    ASSIGN(m_version, version, versionChanged)
    ASSIGN(m_icon, icon, iconChanged)
    ASSIGN(m_description, description, descriptionChanged)
    ASSIGN(m_author, author, authorChanged)
    ASSIGN(m_requires, requirement, requirementChanged)
    ASSIGN(m_settingsSource, settingsSource, settingsSourceChanged)
    ASSIGN(m_settingsUiSource, settingsUiSource, settingsUiSourceChanged)
    ASSIGN(m_entryPoints, entryPoints, entryPointsChanged)

#undef ASSIGN

    if (error() != wasError)
        emit errorChanged();
    if (valid() != wasValid)
        emit validChanged();
}

void PluginManifest::reparse() {
    parse();
}

QString PluginManifest::id() const {
    return m_id;
}

QString PluginManifest::moduleUri() const {
    return PluginModule::uriFor(m_id);
}

QString PluginManifest::name() const {
    return m_name;
}

QString PluginManifest::version() const {
    return m_version;
}

QString PluginManifest::icon() const {
    return m_icon;
}

QString PluginManifest::description() const {
    return m_description;
}

QString PluginManifest::author() const {
    return m_author;
}

QString PluginManifest::requirement() const {
    return m_requires;
}

QString PluginManifest::dir() const {
    return m_dir;
}

QString PluginManifest::sourceUrl(const QString& source) const {
    if (source.isEmpty())
        return {};

    auto url = QUrl::fromLocalFile(m_dir + QStringLiteral("/") + source);
    url.setQuery(QStringLiteral("gen=%1").arg(m_generation));
    return url.toString();
}

QString PluginManifest::declaredSettings() const {
    return m_settingsSource;
}

QString PluginManifest::declaredSettingsUi() const {
    return m_settingsUiSource;
}

QString PluginManifest::settingsSource() const {
    return sourceUrl(m_settingsSource);
}

QString PluginManifest::settingsUiSource() const {
    return sourceUrl(m_settingsUiSource);
}

QList<EntryPoint> PluginManifest::entryPoints() const {
    return m_entryPoints;
}

bool PluginManifest::valid() const {
    return m_parseError.isEmpty() && m_conflicts.isEmpty();
}

QString PluginManifest::error() const {
    if (!m_parseError.isEmpty())
        return m_parseError;

    if (!m_conflicts.isEmpty())
        return QStringLiteral("Duplicate plugin id '%1', also declared by %2")
            .arg(m_id, m_conflicts.join(QStringLiteral(", ")));

    return {};
}

bool PluginManifest::hasParseError() const {
    return !m_parseError.isEmpty();
}

bool PluginManifest::enabled() const {
    return m_enabled;
}

void PluginManifest::setEnabled(bool enabled) {
    if (m_enabled == enabled)
        return;

    m_enabled = enabled;
    emit enabledChanged();
}

QStringList PluginManifest::warnings() const {
    return m_warnings;
}

void PluginManifest::setWarnings(const QStringList& warnings) {
    if (m_warnings == warnings)
        return;

    m_warnings = warnings;
    emit warningsChanged();
}

int PluginManifest::generation() const {
    return m_generation;
}

void PluginManifest::setGeneration(int generation) {
    if (m_generation == generation)
        return;

    m_generation = generation;

    // Before the notify, since loaders inject settings while creating their new object and would
    // otherwise pick up the one built from the previous generation's Settings.qml.
    rebuildSettings();

    emit settingsSourceChanged();
    emit settingsUiSourceChanged();
    emit generationChanged();
}

void PluginManifest::rebuildSettings() {
    if (!m_settings)
        return;

    m_storedSettings = m_settings->toMap();
    m_settings->deleteLater();
    m_settings = nullptr;

    emit settingsChanged();
}

SettingsObject* PluginManifest::settings() {
    if (m_settings || m_settingsSource.isEmpty())
        return m_settings;

    // Get the qml engine from the parent Plugins singleton
    auto* const engine = qmlEngine(parent());
    if (!engine)
        return nullptr;

    QQmlComponent component(engine, QUrl(settingsSource()));
    auto* const object = component.create();
    m_settings = qobject_cast<SettingsObject*>(object);

    if (!m_settings) {
        if (component.isError())
            qCWarning(lcPluginSettings, "Failed to load settings for %s: %s", qUtf8Printable(m_id),
                qUtf8Printable(component.errorString().trimmed()));
        else
            qCWarning(lcPluginSettings, "Settings root for %s is not a SettingsObject", qUtf8Printable(m_id));

        if (object)
            object->deleteLater();

        return nullptr;
    }

    QQmlEngine::setObjectOwnership(m_settings, QQmlEngine::CppOwnership);
    m_settings->setParent(this);

    // Load stored settings
    m_settings->load(m_storedSettings);
    connect(m_settings, &SettingsObject::changed, this, [this] {
        m_settingsDirty = true;
        emit settingsValuesChanged();
    });

    return m_settings;
}

void PluginManifest::loadSettings(const QVariantMap& settings) {
    if (m_settings)
        m_settings->load(settings);
    else
        m_storedSettings = settings;
}

bool PluginManifest::hasUnsavedSettings() const {
    return m_settingsDirty;
}

void PluginManifest::markSettingsSaved() {
    m_settingsDirty = false;
}

QVariantMap PluginManifest::settingsValues() const {
    return m_settings ? m_settings->toMap() : m_storedSettings;
}

void PluginManifest::setConflicts(const QStringList& dirs) {
    if (m_conflicts == dirs)
        return;

    const auto wasValid = valid();

    m_conflicts = dirs;
    emit errorChanged();

    if (valid() != wasValid)
        emit validChanged();
}

} // namespace caelestia::plugins
