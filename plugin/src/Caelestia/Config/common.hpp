#pragma once

#include <qloggingcategory.h>
#include <qstring.h>

#include "settings/listnode.hpp"
#include "settings/macros.hpp"
#include "settings/objectnode.hpp"

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
