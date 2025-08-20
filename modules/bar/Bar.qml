pragma ComponentBehavior: Bound

import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts
    readonly property int vPadding: Appearance.padding.large

    function checkPopout(y: real): void {
        // Use the more explicit and feature-rich Merge2 logic for popout detection
        const spacing = Appearance.spacing.small;
        const aw = activeWindow.child;
        const awy = activeWindow.y + aw.y;

        const ty = tray.y;
        const th = tray.implicitHeight;
        const trayItems = tray.items;

        const clockY = clock.y;
        const clockHeight = clock.implicitHeight;

        // Check status icons hover areas
        let statusIconFound = false;
        for (const area of statusIconsInner.hoverAreas) {
            if (!area.enabled)
                continue;

            const item = area.item;
            const itemY = statusIcons.y + statusIconsInner.y + item.y - spacing / 2;
            const itemHeight = item.implicitHeight + spacing;

            if (y >= itemY && y <= itemY + itemHeight) {
                popouts.currentName = area.name;
                popouts.currentCenter = Qt.binding(() => statusIcons.y + statusIconsInner.y + item.y + item.implicitHeight / 2);
                popouts.hasCurrent = true;
                statusIconFound = true;
                break;
            }
        }

        if (y >= awy && y <= awy + aw.implicitHeight) {
            popouts.currentName = "activewindow";
            popouts.currentCenter = Qt.binding(() => activeWindow.y + aw.y + aw.implicitHeight / 2);
            popouts.hasCurrent = true;

        } else if (y >= clockY && y <= clockY + clockHeight && Config.bar.clock.showCalendar) {
            const style = Config.bar.clock.style || "advanced";
            popouts.currentName = style === "simple" ? "calendar-simple" : "calendar-advanced";
            popouts.currentCenter = Qt.binding(() => clock.y + clock.implicitHeight / 2);
            popouts.hasCurrent = true;

        } else if (y > ty && y < ty + th) {
            const index = Math.floor(((y - ty) / th) * trayItems.count);
            const item = trayItems.itemAt(index);

            popouts.currentName = `traymenu${index}`;
            popouts.currentCenter = Qt.binding(() => tray.y + item.y + item.implicitHeight / 2);
            popouts.hasCurrent = true;
            
        } else if (!statusIconFound) {
            popouts.hasCurrent = false;
        }
    }

    function handleWheel(y: real, angleDelta: point): void {
        const ch = childAt(width / 2, y) as WrappedLoader;
        if (ch?.id === "workspaces") {
            // Workspace scroll
            const mon = (Config.bar.workspaces.perMonitorWorkspaces ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hyprland.dispatch(`togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || (Config.bar.workspaces.perMonitorWorkspaces ? mon.activeWorkspace?.id : Hyprland.activeWsId) > 1)
                Hyprland.dispatch(`workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (y < screen.height / 2) {
            // Volume scroll on top half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else {
            // Brightness scroll on bottom half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + 0.1);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - 0.1);
        }
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left

    implicitWidth: child.implicitWidth + Config.border.thickness * 2

    Item {
        id: child

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: Math.max(osIcon.implicitWidth, workspaces.implicitWidth, activeWindow.implicitWidth, tray.implicitWidth, clock.implicitWidth, statusIcons.implicitWidth, power.implicitWidth)

        OsIcon {
            id: osIcon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.padding.large
        }
    }

    spacing: Appearance.spacing.normal

    Repeater {
        id: repeater

        model: Config.bar.entries

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: WrappedLoader {
                    Layout.fillHeight: enabled
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: WrappedLoader {
                    sourceComponent: OsIcon {}
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: WrappedLoader {
                    sourceComponent: Workspaces {
                        screen: root.screen
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: WrappedLoader {
                    sourceComponent: ActiveWindow {
                        bar: root
                        monitor: Brightness.getMonitorForScreen(root.screen)
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: WrappedLoader {
                    sourceComponent: Tray {}
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: WrappedLoader {
                    sourceComponent: Clock {}
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: WrappedLoader {
                    sourceComponent: StatusIcons {}
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: WrappedLoader {
                    sourceComponent: Power {
                        visibilities: root.visibilities
                    }
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property bool enabled
        required property string id
        required property int index

        function findFirstEnabled(): Item {
            const count = repeater.count;
            for (let i = 0; i < count; i++) {
                const item = repeater.itemAt(i);
                if (item?.enabled)
                    return item;
            }
            return null;
        }

        function findLastEnabled(): Item {
            for (let i = repeater.count - 1; i >= 0; i--) {
                const item = repeater.itemAt(i);
                if (item?.enabled)
                    return item;
            }
            return null;
        }

        Layout.alignment: Qt.AlignHCenter

        // Cursed ahh thing to add padding to first and last enabled components
        Layout.topMargin: findFirstEnabled() === this ? root.vPadding : 0
        Layout.bottomMargin: findLastEnabled() === this ? root.vPadding : 0

        visible: enabled
        active: enabled
    }
}