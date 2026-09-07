#pragma once

#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include "entrypoint.hpp"

namespace caelestia::plugins {

class SettingsObject;

class PluginManifest : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("PluginManifest is created by Plugins")
    Q_MOC_INCLUDE("settingsobject.hpp")

    // Generated from author/name, lowercased
    Q_PROPERTY(QString id READ id NOTIFY idChanged)

    // The URI of the QML module holding this plugin's types, i.e. the id with '.' for '/'
    Q_PROPERTY(QString moduleUri READ moduleUri NOTIFY moduleUriChanged)

    // Required metadata
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString version READ version NOTIFY versionChanged)

    // Optional metadata
    Q_PROPERTY(QString icon READ icon NOTIFY iconChanged)
    Q_PROPERTY(QString description READ description NOTIFY descriptionChanged)
    Q_PROPERTY(QString author READ author NOTIFY authorChanged)
    Q_PROPERTY(QString requires READ requirement NOTIFY requirementChanged)

    // Other props. The directory is the manifest's identity and never changes.
    Q_PROPERTY(QString dir READ dir CONSTANT)
    Q_PROPERTY(QList<caelestia::plugins::EntryPoint> entryPoints READ entryPoints NOTIFY entryPointsChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)

    // Non fatal complaints about the plugin's layout, recomputed on every scan. Unlike `error`
    // these do not stop it loading, they just tell the author something will not work.
    Q_PROPERTY(QStringList warnings READ warnings NOTIFY warningsChanged)

    // The plugin's current hot reload generation, allocated and bumped by Plugins. Everything
    // loaded from a plugin stamps this onto its URL, so a bump makes Qt compile fresh units
    // instead of returning the ones it cached by URL.
    Q_PROPERTY(int generation READ generation NOTIFY generationChanged)

    // Settings
    Q_PROPERTY(QString settingsSource READ settingsSource NOTIFY settingsSourceChanged)
    Q_PROPERTY(QString settingsUiSource READ settingsUiSource NOTIFY settingsUiSourceChanged)
    Q_PROPERTY(caelestia::plugins::SettingsObject* settings READ settings NOTIFY settingsChanged)

public:
    PluginManifest(const QString& dir, const QString& path, QObject* parent = nullptr);

    [[nodiscard]] QString id() const;
    [[nodiscard]] QString moduleUri() const;

    [[nodiscard]] QString name() const;
    [[nodiscard]] QString version() const;

    [[nodiscard]] QString icon() const;
    [[nodiscard]] QString description() const;
    [[nodiscard]] QString author() const;
    [[nodiscard]] QString requirement() const;

    [[nodiscard]] QString dir() const;
    [[nodiscard]] QList<EntryPoint> entryPoints() const;
    [[nodiscard]] bool valid() const;
    [[nodiscard]] QString error() const;

    [[nodiscard]] bool enabled() const;
    void setEnabled(bool enabled);

    [[nodiscard]] QStringList warnings() const;
    void setWarnings(const QStringList& warnings);

    [[nodiscard]] int generation() const;

    // Adopts a new generation: rebuilds the settings object from the newly stamped source, then
    // notifies. Everything reading a plugin URL derives it at that point from the new value, so
    // one synchronous fan-out repoints every live loader onto the same generation.
    void setGeneration(int generation);

    // Absolute, generation stamped URL for a path declared in the manifest relative to dir().
    // Never stored anywhere: a cached copy would outlive its generation.
    [[nodiscard]] Q_INVOKABLE QString sourceUrl(const QString& source) const;

    // The raw `settings`/`settingsUi` paths as declared, i.e. relative and without a generation
    [[nodiscard]] QString declaredSettings() const;
    [[nodiscard]] QString declaredSettingsUi() const;

    [[nodiscard]] QString settingsSource() const;
    [[nodiscard]] QString settingsUiSource() const;

    // Lazily instantiates the plugin's SettingsObject on first access (null if it declares none)
    [[nodiscard]] SettingsObject* settings();

    void loadSettings(const QVariantMap& settings);
    [[nodiscard]] QVariantMap settingsValues() const;

    // True between a change to this plugin's SettingsObject and the write that persists it.
    // While set, the live object is newer than plugins.json and must not be reloaded from it.
    [[nodiscard]] bool hasUnsavedSettings() const;
    void markSettingsSaved();

    // Re-reads manifest.json in place, emitting a change signal for each field that moved.
    // Keeps the object (and therefore its SettingsObject) alive across a rescan.
    void reparse();

    // True when the manifest itself failed to parse or validate, independent of any id clash.
    [[nodiscard]] bool hasParseError() const;

    // The directories of the other plugins declaring this plugin's id. A contested id invalidates
    // every claimant, so this is set on all of them, not just the ones found later. Reversible:
    // recomputed on every scan, since removing a claimant revalidates the rest.
    void setConflicts(const QStringList& dirs);

signals:
    void idChanged();
    void moduleUriChanged();
    void nameChanged();
    void versionChanged();
    void iconChanged();
    void descriptionChanged();
    void authorChanged();
    void requirementChanged();
    void entryPointsChanged();
    void validChanged();
    void errorChanged();
    void enabledChanged();
    void warningsChanged();
    void generationChanged();
    void settingsSourceChanged();
    void settingsUiSourceChanged();

    void settingsChanged();       // Emitted when the settings object itself (m_settings) changed
    void settingsValuesChanged(); // Emitted when a value inside the settings object changed

private:
    void parse();

    // Drops the settings object so the next access rebuilds it from the current generation,
    // keeping the live values so a reload does not discard unsaved edits.
    void rebuildSettings();

    QString m_id;

    QString m_name;
    QString m_version;

    QString m_icon;
    QString m_description;
    QString m_author;
    QString m_requires;

    QString m_dir;
    QString m_path;
    QList<EntryPoint> m_entryPoints;
    QString m_parseError;
    QStringList m_warnings;
    QStringList m_conflicts;
    bool m_enabled = false;
    int m_generation = 0;

    // Raw relative paths; the URLs are derived per access so they always carry the current
    // generation. See sourceUrl().
    QString m_settingsSource;
    QString m_settingsUiSource;
    SettingsObject* m_settings = nullptr;
    QVariantMap m_storedSettings;
    bool m_settingsDirty = false;
};

} // namespace caelestia::plugins
