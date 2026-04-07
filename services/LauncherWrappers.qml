pragma Singleton

import Quickshell

Singleton {
    property var wrappers: new Map()

    function register(screen: var, wrapper: var): void {
        wrappers.set(Hypr.monitorFor(screen), wrapper); // qmllint disable missing-property
    }

    function getForActive(): var {
        return wrappers.get(Hypr.focusedMonitor); // qmllint disable missing-property
    }
}
