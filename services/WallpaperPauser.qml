pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import qs.services

Singleton {
    id: root

    property bool _loaded: false
    property bool pauseOnBattery: false
    property bool paused: false

    function recalculate() {
        if (!_loaded)
            return;

        let newPaused = false;
        let reason = "None";
        // Rule #1, Battery
        if (pauseOnBattery && UPower.onBattery) {
            newPaused = true;
            reason = "Battery";
        } else {
            const ws = Hyprland.focusedWorkspace;
            if (ws) {
                // Strictly filter global toplevels to only the focused workspace
                const toplevels = Hyprland.toplevels.values.filter(t => {
                    const obj = t.lastIpcObject;
                    return obj && obj.workspace && obj.workspace.id === ws.id;
                });
                // Rule #2, 2+ visible windows
                if (toplevels.length >= 2) {
                    newPaused = true;
                    reason = "2+ windows (" + toplevels.length + " total)";
                } else {
                    // Rule #3, 70% of monitor area
                    const monitor = Hyprland.focusedMonitor;
                    if (monitor) {
                        const screen = Quickshell.screens.find(s => {
                            return s.name === monitor.name;
                        });
                        if (screen) {
                            const screenArea = screen.width * screen.height;
                            if (screenArea > 0) {
                                const threshold = screenArea * 0.7;
                                for (const t of toplevels) {
                                    const size = t.lastIpcObject.size;
                                    if (size && size.length >= 2 && size[0] * size[1] >= threshold) {
                                        newPaused = true;
                                        reason = "70% area rule by: " + t.lastIpcObject.title + " (" + size[0] + "x" + size[1] + ")";
                                        console.log("[DEBUG] 70% rule triggered by:", t.lastIpcObject.title, size);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        paused = newPaused;
        console.log("[DEBUG] WallpaperPauser recalculated. Final paused state:", paused, "Reason:", reason);
    }
    function saveSetting() {
        saveProcess.command = ["sh", "-c", "echo '" + root.pauseOnBattery + "' > ~/.cache/caelestia/pauseOnBattery.txt"];
        saveProcess.running = true;
    }

    onPauseOnBatteryChanged: {
        if (_loaded) {
            saveSetting();
            recalculate();
        }
    }

    FileView {
        id: loadView

        path: Quickshell.env("HOME") + "/.cache/caelestia/pauseOnBattery.txt"
        printErrors: false

        onLoadFailed: {
            if (!root._loaded) {
                root._loaded = true;
                root.recalculate();
            }
        }
        onLoaded: {
            root.pauseOnBattery = (text().trim() === "true");
            root._loaded = true;
            root.recalculate();
        }
    }
    Process {
        id: saveProcess
    }
    Connections {
        function onOnBatteryChanged() {
            root.recalculate();
        }

        target: UPower
    }
    Connections {
        function onFocusedMonitorChanged() {
            root.recalculate();
        }
        function onFocusedWorkspaceChanged() {
            root.recalculate();
        }
        function onRawEvent(event) {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (["fullscreen", "activewindow", "changefloatingmode", "minimize", "movewindow", "openwindow", "closewindow", "workspace", "moveworkspace", "focusedmon"].includes(n))
                recalcTimer.restart();
        }

        target: Hyprland
    }
    Timer {
        id: recalcTimer

        interval: 16

        onTriggered: root.recalculate()
    }
}
