pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var bars: new Map()
    property var borderThickness: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        screens.set(Hypr.monitorFor(screen), visibilities);
    }

    function getForActive(): PersistentProperties {
        return screens.get(Hypr.focusedMonitor);
    }

    function getBorderThickness(screen: ShellScreen): int {
        return borderThickness.get(screen) ?? Config.border.thickness;
    }
}
