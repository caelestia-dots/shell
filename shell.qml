//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// Use qt6ct platform theme so QIcon reads qt6ct.conf [Appearance] icon_theme (Papirus) and the
// Material palette is applied to Qt widgets; kept in sync by caelestia-quiet (see _sync_qt6ct)
//@ pragma Env QT_QPA_PLATFORMTHEME=qt6ct
// Load the locally built plugin (in ~/.local) instead of the system package's:
// it carries fork-side C++ changes (Requests transfer timeout, config nodes).
//@ pragma Env QT_ADDITIONAL_PACKAGES_PREFIX_PATH=/home/manu/.local/lib/qt6/qml

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.activities
import qs.modules.areapicker
import qs.modules.background
import qs.modules.clipboard
import qs.modules.drawers
import qs.modules.lock
import qs.daemons

ShellRoot {
    id: root

    settings.watchFiles: false

    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily
        Notifs;
        Players;
        Brightness;
        Keybinds;
        Activities;
        Clipboard;
        Updates;
        MadisonVpn;
        Hydration;
        // Steam: activity poll only; library/API loads when Games tab opens
        Steam;
        // Weather: first Dash/Weather UI calls Weather.reload() — skip boot network hit

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }

    FontLoader {
        source: Quickshell.shellPath("assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    // Modules
    Background {}
    Drawers {}
    Overview {}
    AreaPicker {}
    ClipboardHost {}
    Lock {
        id: lock
    }

    // Daemons
    Shortcuts {}
    BatteryMonitor {}
    GameMode {}
    IdleInhibit {}
    IdleMonitors {
        lock: lock
    }
}
