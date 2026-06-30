pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property list<var> monitors: []

    readonly property Process proc: Process {
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                } catch (e) {
                    console.error("Hyprctl: failed to parse monitors JSON", e);
                }
            }
        }
    }

    // Debounce updates to prevent rapid IPC events or commands from causing render issues.
    function update(): void {
        debounce.restart();
    }

    // Run immediately at startup
    Component.onCompleted: root.proc.running = true

    Timer {
        id: debounce

        interval: 200
        repeat: false
        onTriggered: {
            root.proc.running = true;
            // Schedule recovery pass to handle Wayland geometry changes
            recovery.restart();
        }
    }

    Timer {
        id: recovery

        interval: 600
        repeat: false
        onTriggered: root.proc.running = true
    }

    // Periodic polling fallback
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.update()
    }

    // Listen for Hyprland monitor events
    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name.includes("mon")) {
                root.update();
            }
        }

        target: Hyprland
    }
}
