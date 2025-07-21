pragma ComponentBehavior: Bound

import qs.widgets
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    LazyLoader {
        id: loader

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
}
