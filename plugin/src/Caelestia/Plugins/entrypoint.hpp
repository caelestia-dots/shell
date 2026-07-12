#pragma once

#include <optional>

#include <qjsonobject.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qvariant.h>

namespace caelestia::plugins {

class EntryPointType : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum Type {
        Service,  // a headless QObject instantiated for the lifetime of the plugin
        BarEntry, // a widget contributed to the bar
    };
    Q_ENUM(Type)

    [[nodiscard]] static std::optional<Type> fromString(const QString& str);
    [[nodiscard]] Q_INVOKABLE static QString toString(Type type);
};

class EntryPoint {
    Q_GADGET
    QML_VALUE_TYPE(pluginEntryPoint)

    // Required
    Q_PROPERTY(caelestia::plugins::EntryPointType::Type type MEMBER m_type)
    Q_PROPERTY(QString source MEMBER m_source)

    // Optional
    Q_PROPERTY(QString pluginId MEMBER m_pluginId)
    Q_PROPERTY(QVariantMap properties MEMBER m_properties)

public:
    EntryPoint() = default;
    EntryPoint(const QJsonObject& json, const QString& dir, const QString& pluginId);

    [[nodiscard]] EntryPointType::Type type() const;

    // Empty when the entry point parsed successfully, otherwise why it is invalid.
    [[nodiscard]] QString error() const;

private:
    EntryPointType::Type m_type = EntryPointType::Service;
    QString m_source;
    QString m_pluginId;
    QVariantMap m_properties;
    QString m_error;
};

} // namespace caelestia::plugins
