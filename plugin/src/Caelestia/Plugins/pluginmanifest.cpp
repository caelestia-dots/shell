#include "pluginmanifest.hpp"

#include <qfile.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qregularexpression.h>
#include <qversionnumber.h>

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
    , m_dir(dir) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        m_error = QStringLiteral("Failed to open manifest");
        return;
    }

    QJsonParseError error{};
    const auto doc = QJsonDocument::fromJson(file.readAll(), &error);
    file.close();

    if (error.error != QJsonParseError::NoError) {
        m_error = QStringLiteral("Invalid manifest JSON: ") + error.errorString();
        return;
    }

    const auto obj = doc.object();
    m_name = obj.value(QStringLiteral("name")).toString();

    m_author = obj.value(QStringLiteral("author")).toString();
    if (m_author.isEmpty()) // Author defaults to "unknown" if not specified
        m_author = QStringLiteral("unknown");

    // Canonical id is author/name
    m_id = m_author + QStringLiteral("/") + m_name;
    m_version = obj.value(QStringLiteral("version")).toString();
    m_description = obj.value(QStringLiteral("description")).toString();
    m_requires = obj.value(QStringLiteral("requires")).toString();

    // Each entry point parses itself; the first that fails invalidates the whole manifest.
    QString entryPointError;
    const auto entryPointsArray = obj.value(QStringLiteral("entryPoints")).toArray();
    for (const auto& declared : entryPointsArray) {
        const EntryPoint entryPoint(declared.toObject(), dir, this);
        if (entryPointError.isEmpty())
            entryPointError = entryPoint.error();
        m_entryPoints.append(entryPoint);
    }

    if (m_name.isEmpty())
        m_error = QStringLiteral("Manifest is missing 'name'");
    else if (!isValidIdSegment(m_name))
        m_error = QStringLiteral("Plugin name '%1' may only contain letters, digits, '.', '_' or '-'").arg(m_name);
    else if (!isValidIdSegment(m_author))
        m_error = QStringLiteral("Plugin author '%1' may only contain letters, digits, '.', '_' or '-'").arg(m_author);
    else if (!entryPointError.isEmpty())
        m_error = entryPointError;
    else if (!satisfiesRequirement(m_requires, parseVersion(QStringLiteral(CAELESTIA_VERSION))))
        m_error = QStringLiteral("Requires Caelestia %1 (current is %2)")
                      .arg(m_requires, QStringLiteral(CAELESTIA_VERSION));

    m_valid = m_error.isEmpty();
}

QString PluginManifest::id() const {
    return m_id;
}

QString PluginManifest::name() const {
    return m_name;
}

QString PluginManifest::version() const {
    return m_version;
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

QList<EntryPoint> PluginManifest::entryPoints() const {
    return m_entryPoints;
}

bool PluginManifest::valid() const {
    return m_valid;
}

QString PluginManifest::error() const {
    return m_error;
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

QVariantMap PluginManifest::settings() const {
    return m_settings;
}

QVariant PluginManifest::setting(const QString& key, const QVariant& fallback) const {
    return m_settings.contains(key) ? m_settings.value(key) : fallback;
}

void PluginManifest::setSetting(const QString& key, const QVariant& value) {
    if (m_settings.value(key) == value)
        return;

    m_settings.insert(key, value);
    emit settingsChanged();
}

void PluginManifest::setSettings(const QVariantMap& settings) {
    if (m_settings == settings)
        return;

    m_settings = settings;
    emit settingsChanged();
}

void PluginManifest::invalidate(const QString& error) {
    m_valid = false;
    m_error = error;
}

} // namespace caelestia::plugins
