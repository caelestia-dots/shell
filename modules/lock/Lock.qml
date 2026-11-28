pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components.misc
import qs.services

Scope {
    id: root

    property alias lock: lock

    // Hyprland can remove a monitor before Qt drops its screen. Its temporary
    // FALLBACK output can also disappear as soon as a real monitor returns.
    readonly property list<ShellScreen> captureScreens: {
        const monitors = Hypr.monitors.values;
        return Quickshell.screens.filter(screen => {
            const name = screen.name;
            return name && name !== "FALLBACK" && monitors.some(monitor => monitor.name === name) && !GlobalConfig.forScreen(name).lock.useWallpaper;
        });
    }

    WlSessionLock {
        id: lock

        signal unlock

        LockSurface {
            lock: lock
            pam: pam
            captureScreen: root.captureScreens.includes(screen) ? screen : null
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Loader {
        property bool primed: false

        asynchronous: true
        active: !primed && !lock.locked && root.captureScreens.length > 0
        onLoaded: primed = true

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: root.captureScreens[0] ?? null
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: lock.locked = true
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
            lock.locked = true;
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
