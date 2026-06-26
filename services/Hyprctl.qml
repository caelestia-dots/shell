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

    function update(): void {
        proc.running = true;
    }

    Component.onCompleted: update()

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.update()
    }

    // Refresh when Hyprland reports changes
    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name.includes("mon")) {
                root.update();
            }
        }

        target: Hyprland
    }
}
