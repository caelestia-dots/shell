pragma Singleton

import Quickshell

Singleton {
    property var screens: ({})

    function getForActive(): PersistentProperties {
        return Object.entries(screens).find(s => s[0].slice(s[0].indexOf('"') + 1, s[0].lastIndexOf('"')) === Hyprland.focusedMonitor.name)[1];
    }
}
