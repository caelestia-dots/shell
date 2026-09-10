pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components.misc

Scope {
    property alias lock: lock

    Component.onCompleted: lifecycle.initialize(lock.locked, lock.secure)

    LockLifecycle {
        id: lifecycle

        function onSecureHookRequested(command): void {
            Quickshell.execDetached(command);
        }

        function onReleaseHookRequested(command): void {
            Quickshell.execDetached(command);
        }

        secureCommand: GlobalConfig.lock.onSecure
        releaseCommand: GlobalConfig.lock.onRelease
    }

    WlSessionLock {
        id: lock

        signal unlock

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Connections {
        function onLockedChanged(): void {
            lifecycle.update(lock.locked, lock.secure);
        }

        function onSecureChanged(): void {
            lifecycle.update(lock.locked, lock.secure);
        }

        enabled: lifecycle.initialized
        target: lock
    }

    Pam {
        id: pam

        lock: lock
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
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
