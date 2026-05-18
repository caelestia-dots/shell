pragma ComponentBehavior: Bound

//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/shimeji"
import "modules/areapicker"
import "modules/lock"
import qs.components.containers
import qs.utils
import Caelestia.Config
import Quickshell

ShellRoot {
    settings.watchFiles: true

    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    Variants {
        model: Quickshell.screens.filter(s => GlobalConfig.shimeji.enabled && GlobalConfig.shimeji.path.length > 0 && !Strings.testRegexList(GlobalConfig.shimeji.excludedScreens, s.name))

        Shimeji {
            shimejiCount: GlobalConfig.shimeji.count ?? 1
        }
    }

    ConfigToasts {}
    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }
}
