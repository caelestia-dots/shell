pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    property alias lock: lock

    WlSessionLock {
        id: lock

        signal unlock

        // The surfaces release the lock at the end of their unlock animation. If there is
        // no surface (e.g. no monitors connected) or the animation never finishes (e.g. the
        // render loop is paused while the outputs are off), release it directly instead.
        onUnlock: {
            if (Quickshell.screens.length === 0)
                locked = false;
            else
                unlockFallback.restart();
        }
        onLockedChanged: {
            if (!locked)
                unlockFallback.stop();
        }

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Timer {
        id: unlockFallback

        interval: 3000
        onTriggered: lock.locked = false
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
}
