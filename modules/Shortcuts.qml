import qs.components.misc
import qs.modules.controlcenter
import qs.services
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool launcherInterrupted

    CustomShortcut {
        name: "controlCenter"
        description: "Open control center"
        onPressed: WindowFactory.create()
    }

    CustomShortcut {
        name: "showall"
        description: "Toggle launcher, dashboard and osd"
        onPressed: {
            const v = Visibilities.getForActive();
            v.launcher = v.dashboard = v.osd = v.utilities = !(v.launcher || v.dashboard || v.osd || v.utilities);
        }
    }

    CustomShortcut {
        name: "session"
        description: "Toggle session menu"
        onPressed: {
            const visibilities = Visibilities.getForActive();
            visibilities.session = !visibilities.session;
        }
    }

    CustomShortcut {
        name: "launcher"
        description: "Toggle launcher"
        onPressed: root.launcherInterrupted = false
        onReleased: {
            if (!root.launcherInterrupted) {
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

    IpcHandler {
        target: "drawers"

        function toggle(drawer: string): void {
            if (list().split("\n").includes(drawer)) {
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
        target: "launcher"

        function wallpaper(): void {
            const visibilities = Visibilities.getForActive();
            visibilities.launcher = true;
            // Auto-type ">wallpaper " to jump to wallpaper section
            Qt.callLater(() => {
                const activeWindow = Quickshell.windows.find(w => w.contentItem.objectName === "LauncherWindow");
                if (activeWindow) {
                    const searchField = activeWindow.contentItem.children.find(c => c.objectName === "searchField");
                    if (searchField) {
                        searchField.text = ">wallpaper ";
                        searchField.cursorPosition = searchField.text.length;
                    }
                }
            });
        }
    }
}
