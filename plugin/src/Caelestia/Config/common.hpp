#pragma once

#include <qloggingcategory.h>
#include <qstring.h>

#include "settings/macros.hpp"
#include "settings/objectnode.hpp"

#define CONFIG_NODE_NO_CTOR SETTINGS_NODE_NO_CTOR
#define CONFIG_NODE SETTINGS_NODE
#define CONFIG_PROPERTY SETTINGS_PROPERTY
#define CONFIG_GLOBAL_PROPERTY SETTINGS_GLOBAL_PROPERTY

#define CONFIG_ENUM_PROPERTY(Type, name, defaultVal) CONFIG_PROPERTY(caelestia::config::Type::Enum, name, defaultVal)
#define CONFIG_GLOBAL_ENUM_PROPERTY(Type, name, defaultVal)                                                            \
    CONFIG_GLOBAL_PROPERTY(caelestia::config::Type::Enum, name, defaultVal)

#define CONFIG_SUBOBJECT(Type, name) SETTINGS_SUBOBJECT(caelestia::config::Type, name)
#define CONFIG_GLOBAL_SUBOBJECT(Type, name) SETTINGS_GLOBAL_SUBOBJECT(caelestia::config::Type, name)

#define CONFIG_LIST_TYPE SETTINGS_LIST_TYPE
#define CONFIG_LIST(Type, name, defaultVal, ...)                                                                       \
    SETTINGS_LIST(caelestia::config::Type, name, DEFAULT_ARG(defaultVal), __VA_ARGS__)
#define CONFIG_GLOBAL_LIST(Type, name, defaultVal, ...)                                                                \
    SETTINGS_GLOBAL_LIST(caelestia::config::Type, name, DEFAULT_ARG(defaultVal), __VA_ARGS__)

namespace caelestia::config {

Q_DECLARE_LOGGING_CATEGORY(lcConfig)

QString configDir();
QString monitorConfigDir();

class ListEntry : public settings::ObjectNode {
    CONFIG_NODE(ListEntry, settings::ObjectNode)

    CONFIG_PROPERTY(QString, id, QString())
    CONFIG_PROPERTY(bool, enabled, true)
};

CONFIG_LIST_TYPE(ListEntry, EntryList)

} // namespace caelestia::config

// Shorthand for declaring an ID'd entry (bar entries/status icons, quick toggles, etc)
#define LIST_ENTRY(id, enabled) caelestia::settings::vmap({ { u"id"_s, u## #id##_s }, { u"enabled"_s, enabled } })
