#pragma once

#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qvariant.h>

#include "entrypoint.hpp"

namespace caelestia::plugins {

class SettingsObject;

class PluginManifest : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("PluginManifest is created by Plugins")
    Q_MOC_INCLUDE("settingsobject.hpp")

    // Generated from author/name
    Q_PROPERTY(QString id READ id NOTIFY idChanged)

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

    // Settings
    Q_PROPERTY(QString settingsSource READ settingsSource NOTIFY settingsSourceChanged)
    Q_PROPERTY(QString settingsUiSource READ settingsUiSource NOTIFY settingsUiSourceChanged)
    Q_PROPERTY(caelestia::plugins::SettingsObject* settings READ settings NOTIFY settingsChanged)

public:
    PluginManifest(const QString& dir, const QString& path, QObject* parent = nullptr);

    [[nodiscard]] QString id() const;

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

    // True when the manifest itself failed to parse or validate, independent of shadowing.
    [[nodiscard]] bool hasParseError() const;

    // Marks the manifest as losing an id clash. Reversible: shadowing is recomputed every scan.
    void setShadowed(bool shadowed);

signals:
    void idChanged();
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
    void settingsSourceChanged();
    void settingsUiSourceChanged();
    void settingsChanged();

private:
    void parse();

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
    bool m_shadowed = false;
    bool m_enabled = false;

    QString m_settingsSource;
    QString m_settingsUiSource;
    SettingsObject* m_settings = nullptr;
    QVariantMap m_storedSettings;
    bool m_settingsDirty = false;
};

} // namespace caelestia::plugins
