pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var bars: new Map()

    function load(screen, visibilities) {
        screens.set(Hypr.monitorFor(screen), visibilities);
    }

    function getForActive() {
        return screens.get(Hypr.focusedMonitor);
    }

    function toggleProjector() {
        const vis = getForActive();
        if (vis) vis.projector = !vis.projector;
    }
}
