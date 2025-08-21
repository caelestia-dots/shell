pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false

    Process {
        id: idleInhibitProc
        running: root.enabled
        command: [Quickshell.env("CAELESTIA_II_PATH") || "/usr/lib/caelestia/inhibit_idle"] 
    }
}
