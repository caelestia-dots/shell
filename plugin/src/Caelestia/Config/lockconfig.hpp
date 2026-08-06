#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class LockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, useWallpaper, false)
    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    // Generic face unlock (Howdy / Visage / future PAM face backends)
    CONFIG_GLOBAL_PROPERTY(bool, enableFaceUnlock, true)
    CONFIG_GLOBAL_PROPERTY(QString, faceAuthProvider, u"howdy"_s)
    CONFIG_GLOBAL_PROPERTY(int, maxFaceAuthTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerFaceAuthOnWake, true)
    // Deprecated Howdy-specific keys — kept for backward compatibility
    CONFIG_GLOBAL_PROPERTY(bool, enableHowdy, true)
    CONFIG_GLOBAL_PROPERTY(int, maxHowdyTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerHowdyOnWake, true)
    CONFIG_PROPERTY(bool, hideNotifs, false)

public:
    explicit LockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
