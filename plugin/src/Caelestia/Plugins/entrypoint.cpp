#include "entrypoint.hpp"

#include <qurl.h>

namespace caelestia::plugins {

namespace {

constexpr std::pair<EntryPointType::Type, QLatin1String> kTypeNames[] = {
    { EntryPointType::Custom, QLatin1String("custom") },
    { EntryPointType::BarEntry, QLatin1String("bar-entry") },
    { EntryPointType::BarPopout, QLatin1String("bar-popout") },
    { EntryPointType::StatusIcon, QLatin1String("status-icon") },
    { EntryPointType::QuickToggle, QLatin1String("quick-toggle") },
    { EntryPointType::DashboardTab, QLatin1String("dashboard-tab") },
};

} // namespace

std::optional<EntryPointType::Type> EntryPointType::fromString(const QString& str) {
    for (const auto& [type, name] : kTypeNames)
        if (str == name)
            return type;
    return std::nullopt;
}

QString EntryPointType::toString(Type type) {
    for (const auto& [t, name] : kTypeNames)
        if (t == type)
            return name;
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
