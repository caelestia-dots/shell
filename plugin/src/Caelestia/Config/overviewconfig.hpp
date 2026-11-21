#pragma once

#include <qstring.h>
#include <qstringlist.h>
#include <qvariantlist.h>

#include "settings/objectnode.hpp"
#include "util/i18n.hpp"
#include "common.hpp"

namespace caelestia::shell::config {

using Qt::StringLiterals::operator""_s;
using settings::vmap;
using util::i18n::mark;
using util::i18n::markCtx;

class OverviewAction : public settings::ObjectNode {
    CONFIG_NODE(OverviewAction, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(QString, name, {})
    CONFIG_PROPERTY(QString, icon, {})
    CONFIG_PROPERTY(QString, description, {})
    CONFIG_PROPERTY(QStringList, command, {})
    CONFIG_PROPERTY(bool, dangerous, false)
};
CONFIG_LIST_TYPE(OverviewAction, OverviewActionList)

class OverviewConfig : public settings::ObjectNode {
    CONFIG_NODE(OverviewConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, false)
};

} // namespace caelestia::shell::config
