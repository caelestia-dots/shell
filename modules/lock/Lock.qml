pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.misc

Scope {
    id: root

    property alias lock: lock
    // Set immediately in doLock() and held until unlock to prevent
    // duplicate lock requests before lock.locked reflects compositor state.
    property bool lockTriggered: false

    function doLock(): void {
        if (lock.locked || root.lockTriggered)
            return;
        root.lockTriggered = true;
        lock.locked = true;
    }

    WlSessionLock {
        id: lock

        signal unlock

        onLockedChanged: if (!locked)
            root.lockTriggered = false

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    // Keeps the ICC backend warmed up so the lock surface's ScreencopyView receives
    // a frame before the compositor sends stopped. captureSource is nulled while locked
    // so the ICC context is destroyed before the compositor's stopped event arrives.
    ScreencopyView {
        captureSource: lock.locked ? null : Quickshell.screens[0]
        width: 1
        height: 1
        visible: false
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: root.doLock()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        function lock(): void {
            root.doLock();
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }

        target: "lock"
    }
}
