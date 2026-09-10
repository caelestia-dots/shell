#pragma once

#include <qstring.h>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class DesktopClockBackground : public settings::ObjectNode {
    CONFIG_NODE(DesktopClockBackground, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(bool, blur, true)
};

class DesktopClockShadow : public settings::ObjectNode {
    CONFIG_NODE(DesktopClockShadow, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(qreal, blur, 0.4)
};

class DesktopClock : public settings::ObjectNode {
    CONFIG_NODE(DesktopClock, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, scale, 1.0)
    CONFIG_PROPERTY(QString, position, u"bottom-right"_s)
    CONFIG_PROPERTY(bool, invertColors, false)
    CONFIG_SUBOBJECT(DesktopClockBackground, background)
    CONFIG_SUBOBJECT(DesktopClockShadow, shadow)
};

class BackgroundVisualiser : public settings::ObjectNode {
    CONFIG_NODE(BackgroundVisualiser, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(bool, autoHide, true)
    CONFIG_PROPERTY(bool, blur, false)
    CONFIG_PROPERTY(qreal, rounding, 1)
    CONFIG_PROPERTY(qreal, spacing, 1)
};

class BackgroundConfig : public settings::ObjectNode {
    CONFIG_NODE(BackgroundConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, wallpaperEnabled, true)
    CONFIG_SUBOBJECT(DesktopClock, desktopClock)
    CONFIG_SUBOBJECT(BackgroundVisualiser, visualiser)
};

} // namespace caelestia::config
