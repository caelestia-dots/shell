#pragma once

#include <qloggingcategory.h>
#include <qstring.h>

#include "settings/macros.hpp"

#define STATE_NODE_NO_CTOR SETTINGS_NODE_NO_CTOR
#define STATE_NODE SETTINGS_NODE
#define STATE_PROPERTY SETTINGS_PROPERTY
#define STATE_GLOBAL_PROPERTY SETTINGS_GLOBAL_PROPERTY

#define STATE_SUBOBJECT(Type, name) SETTINGS_SUBOBJECT(caelestia::state::Type, name)
#define STATE_GLOBAL_SUBOBJECT(Type, name) SETTINGS_GLOBAL_SUBOBJECT(caelestia::state::Type, name)

#define STATE_LIST_TYPE SETTINGS_LIST_TYPE
#define STATE_LIST(Type, name, defaultVal, ...)                                                                        \
    SETTINGS_LIST(caelestia::state::Type, name, DEFAULT_ARG(defaultVal), __VA_ARGS__)
#define STATE_GLOBAL_LIST(Type, name, defaultVal, ...)                                                                 \
    SETTINGS_GLOBAL_LIST(caelestia::state::Type, name, DEFAULT_ARG(defaultVal), __VA_ARGS__)

namespace caelestia::state {

Q_DECLARE_LOGGING_CATEGORY(lcState)

QString stateDir();
QString monitorStateDir();

} // namespace caelestia::state
