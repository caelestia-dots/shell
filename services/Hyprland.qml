pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors
    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: focusedWorkspace?.id ?? 1
    property string kbLayout: "?"
    property string kbLayoutBrief: "?"

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (n === "activelayout") {
                root.kbLayout = event.parse(2)[1];
                kbBriefProc.running = true;
            } else if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                Hyprland.refreshToplevels();
            }
        }
    }

    Process {
        id: kbBriefProc

        running: false
        command: [Quickshell.env("CAELESTIA_KBBD_PATH") || "/usr/lib/caelestia/kb_brief_detector", root.kbLayout]

        stdout: StdioCollector {
            onStreamFinished: root.kbLayoutBrief = text.toString().toUpperCase()
        }
    }

    // to initialize kbLayout and kbLayoutBrief via HyprlandEvent
    Process {

        running: true
        command: ["fish", "-C", "hyprctl switchxkblayout current next && hyprctl switchxkblayout current prev"]
    }
}
