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
    CONFIG_GLOBAL_PROPERTY(bool, enableFace, true)
    CONFIG_GLOBAL_ENUM_PROPERTY(FaceProvider, faceProvider, FaceProvider::Howdy)
    CONFIG_GLOBAL_PROPERTY(int, maxFaceTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerFaceOnWake, true)
    CONFIG_PROPERTY(bool, hideNotifs, false)
    CONFIG_GLOBAL_PROPERTY(bool, enableSessionControls, false)
};

} // namespace caelestia::shell::config
