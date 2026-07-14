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
    Q_PROPERTY(QString id READ id CONSTANT)

    // Required metadata
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)

    // Optional metadata
    Q_PROPERTY(QString description READ description CONSTANT)
    Q_PROPERTY(QString author READ author CONSTANT)
    Q_PROPERTY(QString requires READ requirement CONSTANT)

    // Other props
    Q_PROPERTY(QString dir READ dir CONSTANT)
    Q_PROPERTY(QList<caelestia::plugins::EntryPoint> entryPoints READ entryPoints CONSTANT)
    Q_PROPERTY(bool valid READ valid CONSTANT)
    Q_PROPERTY(QString error READ error CONSTANT)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)

    // Settings
    Q_PROPERTY(QString settingsSource READ settingsSource CONSTANT)
    Q_PROPERTY(QString settingsUiSource READ settingsUiSource CONSTANT)
    Q_PROPERTY(caelestia::plugins::SettingsObject* settings READ settings NOTIFY settingsChanged)

public:
    PluginManifest(const QString& dir, const QString& path, QObject* parent = nullptr);

    [[nodiscard]] QString id() const;

    [[nodiscard]] QString name() const;
    [[nodiscard]] QString version() const;

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

    // Marks the manifest as invalid
    void invalidate(const QString& error);

signals:
    void enabledChanged();
    void settingsChanged();

private:
    QString m_id;

    QString m_name;
    QString m_version;

    QString m_description;
    QString m_author;
    QString m_requires;

    QString m_dir;
    QList<EntryPoint> m_entryPoints;
    bool m_valid = false;
    QString m_error;
    bool m_enabled = false;

    QString m_settingsSource;
    QString m_settingsUiSource;
    SettingsObject* m_settings = nullptr;
    QVariantMap m_storedSettings;
};

} // namespace caelestia::plugins
