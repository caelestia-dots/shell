#include <qstring.h>
using Qt::StringLiterals::operator""_s;
#include <qstring.h>
using Qt::StringLiterals::operator""_s;
#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class OsdConfig : public settings::ObjectNode {
    CONFIG_NODE(OsdConfig, settings::ObjectNode)
    CONFIG_PROPERTY(QString, placement, u"right"_s)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, hideDelay, 2000)
    CONFIG_PROPERTY(bool, enableBrightness, true)
    CONFIG_PROPERTY(bool, enableMicrophone, false)
};

} // namespace caelestia::config
