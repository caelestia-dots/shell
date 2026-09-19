pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Services
import qs.services
import qs.utils

// Re-acquires the session lock when the shell restarts while the session is
// locked.
//
// A WlSessionLock cannot survive a transient zero-output state (waking from
// suspend, a DPMS cycle, a monitor disconnect): quickshell's Wayland
// connection is torn down and it exits, which leaves the compositor showing
// its "lockscreen app died" screen. The compositor keeps the session locked,
// so nothing is exposed, but the session stays unusable until another client
// takes the lock over.
//
// To recover, the shell records in the runtime dir whether the compositor
// currently has the session locked. The runtime dir is wiped on reboot and on
// logout, so a fresh instance that still finds the marker knows the lock was
// held by a shell that has since died, and takes the lock back instead of
// coming up on a stranded session.
Scope {
    id: root

    required property WlSessionLock lock

    readonly property string markerPath: `${Paths.runtime}/caelestia-locked`

    property bool markerPending
    property bool relocking
    property bool blanked

    function handleMarker(content: string): void {
        markerPending = content.trim() === "1";

        if (markerPending)
            relock();
    }

    function writeMarker(locked: bool): void {
        markerPending = locked;
        marker.setText(locked ? "1" : "0");
    }

    function setDpms(on: bool): void {
        // Keep the panel blanked while recovering so the compositor's dead-lock
        // frame is not visible until the lock is back up.
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.dpms({ action = "${on ? "enable" : "disable"}" })` : `dpms ${on ? "on" : "off"}`);
    }

    function allowLockRestore(): void {
        // Hyprland refuses a new session lock while a dead lock client is still
        // registered unless this is set. It is only touched while recovering.
        if (!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            return;

        Hypr.extras.applyOptions({
            "misc:allow_session_lock_restore": 1
        });
    }

    function relock(): void {
        // Nothing to recover with when the lock screen is disabled, and a lock
        // that is still requested but not secure cannot be re-requested without
        // briefly releasing the session, so leave that to quickshell.
        if (relocking || lock.secure || lock.locked || !GlobalConfig.lock.enabled)
            return;

        relocking = true;
        blanked = true;

        setDpms(false);
        allowLockRestore();

        lock.locked = true;
        relockTimeout.start();
    }

    function finishRelock(): void {
        relocking = false;
        relockTimeout.stop();

        if (!blanked)
            return;

        setDpms(true);
        blanked = false;
    }

    Timer {
        id: relockTimeout

        // Give up on this attempt but restore the panel and leave the marker
        // alone, so the next shell start retries the recovery.
        interval: 15000
        onTriggered: {
            console.warn(lc, "Failed to re-acquire the session lock");
            root.finishRelock();
        }
    }

    FileView {
        id: marker

        printErrors: false
        path: root.markerPath

        onLoaded: root.handleMarker(text())
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.handleMarker("");
            else
                console.warn(lc, `Unable to read the lock marker: ${err}`);
        }
        onSaveFailed: err => console.warn(lc, `Unable to write the lock marker: ${err}`)
    }

    Connections {
        function onSecureChanged(): void {
            // The marker is only ever set once the compositor has confirmed the
            // lock is held, so a shell that dies before that leaves the previous
            // value in place and the session stays recoverable.
            if (!root.lock.secure)
                return;

            root.writeMarker(true);
            root.finishRelock();
        }

        // Deliberate unlocks (PAM success, IPC, shortcuts, logind's Unlock).
        // Deliberately keyed off caelestia's own signal rather than `locked`
        // becoming false: quickshell clears `locked` however it goes away, and
        // erasing the marker on shutdown would defeat the entire recovery.
        function onUnlock(): void {
            root.writeMarker(false);
            root.finishRelock();
        }

        target: root.lock
    }

    Connections {
        function onResumed(): void {
            // A resume can silently drop the lock, so take it back if the
            // session was left locked.
            if (root.markerPending && !root.lock.secure)
                root.relock();
        }

        target: SessionManager
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.modules.lock.recovery"
        defaultLogLevel: LoggingCategory.Info
    }
}
