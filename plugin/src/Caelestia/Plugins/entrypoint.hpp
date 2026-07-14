#pragma once

#include <qjsonobject.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qvariant.h>

namespace caelestia::plugins {

class PluginManifest;

class EntryPointType : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum Type {
        Custom,       // Custom unparented component
        BarEntry,     // Entry in the bar
        BarPopout,    // Popout attached to a bar entry
        StatusIcon,   // Status icon in the bar
        QuickToggle,  // Quick toggle in utilities drawer
        DashboardTab, // New dashboard tab
    };
    Q_ENUM(Type)

    [[nodiscard]] static std::optional<Type> fromString(const QString& str);
    [[nodiscard]] Q_INVOKABLE static QString toString(Type type);
};

class EntryPoint {
    Q_GADGET
    Q_MOC_INCLUDE("pluginmanifest.hpp")
    QML_VALUE_TYPE(pluginEntryPoint)

    // Required metadata
    Q_PROPERTY(caelestia::plugins::EntryPointType::Type type MEMBER m_type)
    Q_PROPERTY(QString source MEMBER m_source)

    Q_PROPERTY(caelestia::plugins::PluginManifest* plugin MEMBER m_plugin)
    Q_PROPERTY(QVariantMap properties MEMBER m_properties)

public:
    EntryPoint() = default;
    EntryPoint(const QJsonObject& json, const QString& dir, PluginManifest* plugin);

    [[nodiscard]] EntryPointType::Type type() const;

    // Empty when the entry point parsed successfully, otherwise why it is invalid.
    [[nodiscard]] QString error() const;

private:
    EntryPointType::Type m_type = EntryPointType::Custom;
    QString m_source;
    PluginManifest* m_plugin = nullptr;
    QVariantMap m_properties;
    QString m_error;
};

} // namespace caelestia::plugins
