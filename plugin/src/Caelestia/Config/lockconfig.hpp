#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::shell::config {

class LockConfig : public settings::ObjectNode {
    CONFIG_NODE(LockConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, useWallpaper, false)
    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, enableFaceAuth, true)
    CONFIG_GLOBAL_ENUM_PROPERTY(FaceAuthProvider, faceAuthProvider, FaceAuthProvider::Howdy)
    CONFIG_GLOBAL_PROPERTY(int, maxFaceAuthTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerFaceAuthOnWake, true)
    CONFIG_PROPERTY(bool, hideNotifs, false)
    CONFIG_GLOBAL_PROPERTY(bool, enableSessionControls, false)
};

} // namespace caelestia::shell::config
