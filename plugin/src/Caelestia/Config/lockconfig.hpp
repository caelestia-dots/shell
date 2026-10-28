#pragma once

#include <qstring.h>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::shell::config {

using Qt::StringLiterals::operator""_s;

class LockConfig : public settings::ObjectNode {
    CONFIG_NODE(LockConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, useWallpaper, false)
    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    // PAM face backend named by faceProvider (assets/pam.d/<faceProvider>)
    CONFIG_GLOBAL_PROPERTY(bool, enableFace, true)
    CONFIG_GLOBAL_PROPERTY(QString, faceProvider, u"howdy"_s)
    CONFIG_GLOBAL_PROPERTY(int, maxFaceTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerFaceOnWake, true)
    CONFIG_PROPERTY(bool, hideNotifs, false)
    CONFIG_GLOBAL_PROPERTY(bool, enableSessionControls, false)
};

} // namespace caelestia::shell::config
