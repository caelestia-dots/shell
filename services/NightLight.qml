pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool active: false
    property bool pending: false
    property bool requestedActive: false
    property int startupAttempts: 0
    property bool attemptedStart: false
    property int stateGeneration: 0

    function refresh(): void {
        if (!available || pending || statusProc.running)
            return;

        statusProc.requestGeneration = stateGeneration;
        statusProc.running = true;
    }

    function toggle(): void {
        if (!available || pending)
            return;

        requestedActive = !active;
        stateGeneration++;
        pending = true;
        active = requestedActive;
        startupAttempts = 0;
        attemptedStart = false;
        if (requestedActive)
            enableProc.running = true;
        else
            disableProc.running = true;
    }

    function complete(success: bool): void {
        startupTimer.stop();
        if (!success)
            active = !requestedActive;
        pending = false;
        if (!success && requestedActive && attemptedStart && ownedSunset.running)
            ownedSunset.running = false;
        refresh();
    }

    Process {
        id: availabilityProc

        running: true
        command: ["sh", "-c", "command -v hyprsunset >/dev/null && command -v hyprctl >/dev/null"]
        // qmllint disable signal-handler-parameters
        onExited: code => {
            root.available = code === 0;
            if (root.available)
                root.refresh();
        }
    }

    Process {
        id: statusProc

        property int requestGeneration: 0

        command: ["hyprctl", "hyprsunset", "identity", "get"]
        // qmllint disable signal-handler-parameters
        onExited: {
            if (!root.pending && requestGeneration !== root.stateGeneration)
                Qt.callLater(root.refresh);
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.pending || statusProc.requestGeneration !== root.stateGeneration)
                    return;
                const identity = text.trim();
                if (identity === "true")
                    root.active = false;
                else if (identity === "false")
                    root.active = true;
            }
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.available
        onTriggered: root.refresh()
    }

    Process {
        id: ownedSunset

        command: ["hyprsunset", "--identity"]
        // qmllint disable signal-handler-parameters
        onExited: {
            if (root.pending && root.requestedActive)
                root.complete(false);
            else if (root.active)
                root.active = false;
        }
    }

    Process {
        id: enableProc

        command: ["hyprctl", "hyprsunset", "temperature", "4500"]
        // qmllint disable signal-handler-parameters
        onExited: code => {
            if (code === 0) {
                root.complete(true);
            } else if (!root.attemptedStart) {
                root.attemptedStart = true;
                ownedSunset.running = true;
                startupTimer.restart();
            } else if (root.startupAttempts < 3) {
                startupTimer.restart();
            } else {
                root.complete(false);
            }
        }
    }

    Process {
        id: disableProc

        command: ["hyprctl", "hyprsunset", "identity"]
        // qmllint disable signal-handler-parameters
        onExited: code => root.complete(code === 0)
    }

    Timer {
        id: startupTimer

        interval: 200
        onTriggered: {
            root.startupAttempts++;
            enableProc.running = true;
        }
    }
}
