pragma Singleton

import Quickshell
import qs.components
import qs.services

Singleton {
    property var screens: new Map()
    property var bars: new Map()
    property bool sessionLocked: false

    function load(screen: ShellScreen, visibilities: DrawerVisibilities): void {
        screens.set(Hypr.monitorFor(screen), visibilities);
    }

    function getForActive(): DrawerVisibilities {
        return screens.get(Hypr.focusedMonitor);
    }
}
