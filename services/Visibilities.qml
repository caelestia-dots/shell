pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    property var screens: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        screens.set(Hyprland.monitorFor(screen), visibilities);
    }

    function getForActive(): PersistentProperties {
        return screens.get(Hyprland.focusedMonitor);
    }
}
