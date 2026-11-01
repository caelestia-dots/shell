import QtQuick
import Quickshell
import Quickshell.Io
import qs.components.misc

// Runs the minimal lock screen in its own Quickshell process so a crash in the
// main shell cannot take the session lock down with it.
Scope {
    id: root

    readonly property string lockPath: Quickshell.shellPath("lock-shell.qml")
    readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/caelestia-lock.state"
    readonly property bool secure: locked && process.running && stateText === "locked"

    property bool locked: false
    property string stateText

    function lock(): void {
        locked = true;
    }

    // Unlock requests from logind are handled by the lock process itself.
    function unlock(): void {
    }

    onLockedChanged: {
        if (!locked || process.running)
            return;

        stateText = "";
        clearState.running = true;
    }

    Process {
        id: clearState

        command: ["rm", "-f", root.statePath]

        onExited: {
            process.command = ["qs", "-p", root.lockPath];
            process.running = true;
        }
    }

    Process {
        id: process

        onExited: code => {
            if (code !== 0)
                console.warn(`Lock process exited with code ${code}`);
            root.locked = false;
            root.stateText = "unlocked";
        }
    }

    Process {
        id: readState

        stdout: StdioCollector {
            onDataChanged: {
                const value = text.trim();
                if (value.length > 0)
                    root.stateText = value;
            }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.locked

        onTriggered: {
            if (readState.running)
                return;

            readState.command = ["sh", "-c", `cat "${root.statePath}" 2>/dev/null; echo`];
            readState.running = true;
        }
    }

    IpcHandler {
        function lock(): void {
            root.lock();
        }

        function isLocked(): bool {
            return root.locked || process.running;
        }

        function isSecure(): bool {
            return root.secure;
        }

        target: "lock"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: root.lock()
    }
}
