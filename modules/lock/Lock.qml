pragma ComponentBehavior: Bound

import qs.components.misc
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool fprint

    LazyLoader {
        id: loader

        onActiveChanged: {
            proc.running = true;
        }

        WlSessionLock {
            id: lock

            property bool unlocked

            locked: true

            onLockedChanged: {
                if (!locked)
                    loader.active = false;
            }

            LockSurface {
                lock: lock
                fprint: root.fprint
            }
        }
    }

    CustomShortcut {
        name: "lock"
        description: "Lock the current session"
        onPressed: loader.activeAsync = true
    }

    CustomShortcut {
        name: "unlock"
        description: "Unlock the current session"
        onPressed: loader.item.locked = false
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            loader.activeAsync = true;
        }

        function unlock(): void {
            loader.item.locked = false;
        }

        function isLocked(): bool {
            return loader.active;
        }
    }

    Process {
        id: proc
        running: true
        command: ["sh", "-c", "if [ -f /etc/pam.d/caelestia ]; then echo true; else echo false; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.fprint = text.includes("true");
            }
        }
    }

    CustomShortcut {
        name: "useFprint"
        description: "Use fprint"
        onPressed: root.fprint = true
    }

    CustomShortcut {
        name: "dontUseFprint"
        description: "Use password only"
        onPressed: root.fprint = false
    }

    IpcHandler {
        target: "fprint"

        function useFprint(): void {
            root.fprint = true;
        }

        function dontUseFprint(): void {
            root.fprint = false;
        }
    }
}
