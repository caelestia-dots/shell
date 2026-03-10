pragma Singleton

import Quickshell

Singleton {
    property var launchers: new Map()

    function register(screen: var, launcher: var): void {
        launchers.set(Hypr.monitorFor(screen), launcher);
    }

    function getForActive(): var {
        return launchers.get(Hypr.focusedMonitor);
    }
}