import qs.components.misc
import qs.modules.controlcenter
import qs.services
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property bool launcherInterrupted
    readonly property bool hasFullscreen: Hypr.focusedWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen === 2) ?? false

    CustomShortcut {
        name: "controlCenter"
        description: "Open control center"
        onPressed: WindowFactory.create()
    }

    CustomShortcut {
        name: "showall"
        description: "Toggle launcher, dashboard and osd"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const v = Visibilities.getForActive();
            v.launcher = v.dashboard = v.osd = v.utilities = !(v.launcher || v.dashboard || v.osd || v.utilities);
        }
    }

    CustomShortcut {
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const visibilities = Visibilities.getForActive();
            visibilities.dashboard = !visibilities.dashboard;
        }
    }

    CustomShortcut {
        name: "session"
        description: "Toggle session menu"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const visibilities = Visibilities.getForActive();
            visibilities.session = !visibilities.session;
        }
    }

    CustomShortcut {
        name: "launcher"
        description: "Toggle launcher"
        onPressed: root.launcherInterrupted = false
        onReleased: {
            if (!root.launcherInterrupted && !root.hasFullscreen) {
                const visibilities = Visibilities.getForActive();
                visibilities.launcher = !visibilities.launcher;
            }
            root.launcherInterrupted = false;
        }
    }

    CustomShortcut {
        name: "launcherInterrupt"
        description: "Interrupt launcher keybind"
        onPressed: root.launcherInterrupted = true
    }

    CustomShortcut {
        name: "cycleSpecialWorkspace"
        description: "Cycle through open special workspaces"
        onPressed: {
            const openSpecials = Hypr.workspaces.values
                .filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0)
                .sort((a, b) => a.name.localeCompare(b.name));

            if (openSpecials.length === 0)
                return;

            const activeSpecial = Hypr.focusedMonitor.lastIpcObject.specialWorkspace.name ?? "";
            let nextIndex = 0;

            if (activeSpecial) {
                const currentIndex = openSpecials.findIndex(w => w.name === activeSpecial);
                if (currentIndex !== -1) {
                    nextIndex = (currentIndex + 1) % openSpecials.length;
                }
            }

            Hypr.dispatch(`workspace ${openSpecials[nextIndex].name}`);
        }
    }

    IpcHandler {
        target: "drawers"

        function toggle(drawer: string): void {
            if (list().split("\n").includes(drawer)) {
                if (root.hasFullscreen && ["launcher", "session", "dashboard"].includes(drawer))
                    return;
                const visibilities = Visibilities.getForActive();
                visibilities[drawer] = !visibilities[drawer];
            } else {
                console.warn(`[IPC] Drawer "${drawer}" does not exist`);
            }
        }

        function list(): string {
            const visibilities = Visibilities.getForActive();
            return Object.keys(visibilities).filter(k => typeof visibilities[k] === "boolean").join("\n");
        }
    }

    IpcHandler {
        target: "controlCenter"

        function open(): void {
            WindowFactory.create();
        }
    }

    IpcHandler {
        target: "toaster"

        function info(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Info);
        }

        function success(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Success);
        }

        function warn(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Warning);
        }

        function error(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Error);
        }
    }

    property string lastSpecialWorkspace: ""

    Connections {
        target: Hypr.focusedMonitor

        function onLastIpcObjectChanged(): void {
            const specialName = Hypr.focusedMonitor.lastIpcObject.specialWorkspace.name;
            
            if (specialName && specialName.startsWith("special:")) {
                root.lastSpecialWorkspace = specialName;
            }
        }
    }

    IpcHandler {
        target: "specialWorkspace"

        function cycle(direction: string): void {
            const openSpecials = Hypr.workspaces.values
                .filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0);

            if (openSpecials.length === 0)
                return;

            const activeSpecial = Hypr.focusedMonitor.lastIpcObject.specialWorkspace.name ?? "";
            
            if (!activeSpecial) {
                if (root.lastSpecialWorkspace) {
                    const workspace = Hypr.workspaces.values.find(w => w.name === root.lastSpecialWorkspace);
                    if (workspace && workspace.lastIpcObject.windows > 0) {
                        Hypr.dispatch(`workspace ${root.lastSpecialWorkspace}`);
                        return;
                    }
                }
                Hypr.dispatch(`workspace ${openSpecials[0].name}`);
                return;
            }

            const currentIndex = openSpecials.findIndex(w => w.name === activeSpecial);
            let nextIndex = 0;
            
            if (currentIndex !== -1) {
                if (direction === "next")
                    nextIndex = (currentIndex + 1) % openSpecials.length;
                else
                    nextIndex = (currentIndex - 1 + openSpecials.length) % openSpecials.length;
            }

            Hypr.dispatch(`workspace ${openSpecials[nextIndex].name}`);
        }

        function list(): string {
            return Hypr.workspaces.values
                .filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0)
                .map(w => w.name)
                .join("\n");
        }
    }
}
