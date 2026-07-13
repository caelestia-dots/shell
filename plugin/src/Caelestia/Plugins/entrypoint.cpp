#include "entrypoint.hpp"

#include <qurl.h>

namespace caelestia::plugins {

std::optional<EntryPointType::Type> EntryPointType::fromString(const QString& str) {
    if (str == QStringLiteral("service"))
        return Service;
    if (str == QStringLiteral("bar-entry"))
        return BarEntry;
    return std::nullopt;
}

QString EntryPointType::toString(Type type) {
    switch (type) {
    case Service:
        return QStringLiteral("service");
    case BarEntry:
        return QStringLiteral("bar-entry");
    }
    return {};
}

EntryPoint::EntryPoint(const QJsonObject& json, const QString& dir, PluginManifest* plugin)
    : m_plugin(plugin) {
    const auto typeStr = json.value(QStringLiteral("type")).toString();
    if (const auto type = EntryPointType::fromString(typeStr))
        m_type = *type;
    else
        m_error = typeStr.isEmpty() ? QStringLiteral("Entry point is missing 'type'")
                                    : QStringLiteral("Entry point has unknown type '%1'").arg(typeStr);

    const auto source = json.value(QStringLiteral("source")).toString();
    if (!source.isEmpty())
        m_source = QUrl::fromLocalFile(dir + QStringLiteral("/") + source).toString();
    else if (m_error.isEmpty())
        m_error = QStringLiteral("Entry point '%1' is missing 'source'").arg(typeStr);

    // Keep any author-defined keys beyond the known ones.
    m_properties = json.toVariantMap();
    m_properties.remove(QStringLiteral("type"));
    m_properties.remove(QStringLiteral("source"));
}

EntryPointType::Type EntryPoint::type() const {
    return m_type;
}

QString EntryPoint::error() const {
    return m_error;
}

} // namespace caelestia::plugins
