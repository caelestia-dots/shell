//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import Quickshell
import QtQuick
import Niri 0.1

ShellRoot {
    id : shellroot
    Niri {
        id: niri
        Component.onCompleted: connect()

        onConnected: console.log("Connected to niri")
        onErrorOccurred: function(error) {
            console.error("Niri error:", error)
        }
    }
    // Background {}
    LazyLoader { active: true; component: Drawers {} }
    AreaPicker {}
    Lock {
        id: lock
    }

    // Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }
}
