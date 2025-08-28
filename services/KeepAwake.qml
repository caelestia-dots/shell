pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool enabled: false

    Timer {
        id: checkTimer
        interval: 3000  // Check every 3 seconds
        running: true
        repeat: true
        onTriggered: checkHyprIdleProcess()
    }

    Process {
        id: checkProc
        running: false
        command: ["pgrep", "-x", "hypridle"]

        onExited: function (exitCode) {
            enabled = (exitCode !== 0);
        }
    }

    // Kill Hypridle
    Process {
        id: killProc
        running: false
        command: ["pkill", "-f", "hypridle"]

        onExited: function (exitCode) {
            Qt.callLater(checkHyprIdleProcess);
        }
    }

    // Start Hypridle
    Process {
        id: startProc
        running: false
        command: ["hypridle"]

        onStarted: {
            Qt.callLater(checkHyprIdleProcess);
        }
    }

    function checkHyprIdleProcess() {
        if (!checkProc.running) {
            checkProc.running = true;
        }
    }

    Component.onCompleted: {
        checkHyprIdleProcess();
    }

    function enable() {
        if (!enabled && !killProc.running) {
            killProc.running = true;
        }
    }

    function disable() {
        if (enabled && !startProc.running) {
            startProc.running = true;
        }
    }

    function toggle() {
        if (enabled) {
            disable();
        } else {
            enable();
        }
    }
}
