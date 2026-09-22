pragma ComponentBehavior: Bound

import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

GridLayout {
    id: root
    anchors.fill: parent

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen

    readonly property bool isHorizontal: Config.bar.alignment === "top" || Config.bar.alignment === "bottom"
    readonly property int edgePadding: Tokens.padding.large

    flow: isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
    columnSpacing: isHorizontal ? Tokens.spacing.medium : 0
    rowSpacing: isHorizontal ? 0 : Tokens.spacing.medium

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const tray = (repeater.itemAt(i) as EntryWrapper)?.item as Tray;
            if (tray)
                tray.expanded = false;
        }
    }

    function checkPopout(coord: real): void {
        const ch = isHorizontal ? childAt(coord, height / 2) as EntryWrapper : childAt(width / 2, coord) as EntryWrapper;
        if (ch?.entryId !== "tray") closeTray();

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;

        if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const items = (ch.item as StatusIcons).items;
            const icon = isHorizontal 
                ? items.childAt(mapToItem(items, coord, height / 2).x, items.height / 2) 
                : items.childAt(items.width / 2, mapToItem(items, width / 2, coord).y);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = isHorizontal 
                    ? Qt.binding(() => icon.mapToItem(root, icon.width / 2, 0).x) 
                    : Qt.binding(() => icon.mapToItem(root, 0, icon.height / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "tray" && Config.bar.popouts.tray) {
            const tray = ch.item as Tray;
            const expandPt = mapToItem(tray.expandIcon, isHorizontal ? coord : width/2, isHorizontal ? height/2 : coord);
            const inExpand = tray.expandIcon.contains(expandPt);
            
            if (!Config.bar.tray.compact || (tray.expanded && !inExpand)) {
                let foundIndex = -1;
                let foundItem = null;
                for (let i = 0; i < tray.items.count; i++) {
                    const tItem = tray.items.itemAt(i);
                    if (tItem) {
                        const localPt = mapToItem(tItem, isHorizontal ? coord : width/2, isHorizontal ? height/2 : coord);
                        const margin = tray.spacing / 2 + 1;
                        if (localPt.x >= -margin && localPt.x <= tItem.width + margin &&
                            localPt.y >= -margin && localPt.y <= tItem.height + margin) {
                            foundIndex = i;
                            foundItem = tItem;
                            break;
                        }
                    }
                }

                if (foundItem) {
                    popouts.currentName = `traymenu${foundIndex}`;
                    popouts.currentCenter = isHorizontal 
                        ? Qt.binding(() => foundItem.mapToItem(root, foundItem.width / 2, 0).x) 
                        : Qt.binding(() => foundItem.mapToItem(root, 0, foundItem.height / 2).y);
                    popouts.hasCurrent = true;
                }
            } else {
                popouts.hasCurrent = false;
                tray.expanded = true;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = isHorizontal 
                ? (ch.item as Item).mapToItem(root, (ch.item as Item).width / 2, 0).x ?? 0 
                : (ch.item as Item).mapToItem(root, 0, (ch.item as Item).height / 2).y ?? 0;
            popouts.hasCurrent = true;
        }
    }

    function handleWheel(coord: real, angleDelta: point): void {
        const ch = isHorizontal ? childAt(coord, height / 2) as EntryWrapper : childAt(width / 2, coord) as EntryWrapper;
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = (GlobalConfig.bar.workspaces.perMonitor ? Hypr.monitorFor(screen) : Hypr.focusedMonitor);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || (GlobalConfig.bar.workspaces.perMonitor ? mon.activeWorkspace?.id : Hypr.activeWsId) > 1)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "r${angleDelta.y > 0 ? "-" : "+"}1" })` : `workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if ((isHorizontal ? coord < screen.width / 2 : coord < screen.height / 2) && Config.bar.scrollActions.volume) {
            // Volume scroll on top half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on bottom half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
        }
    }

    Repeater {
        id: repeater
        model: ScriptModel { values: root.Config.bar.entries.values.filter(e => e.enabled) }
        DelegateChooser {
            role: "id"
            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {}
                }
            DelegateChoice {
                roleValue: "logo"
                delegate: EntryWrapper {
                    OsIcon {
                        objectName: "taskbarLogo"
                        }
                    }
                }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: EntryWrapper {
                    Workspaces {
                        objectName: "taskbarWorkspaces"
                        screen: root.screen
                        fullscreen: root.fullscreen
                        }
                    }
                }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    ActiveWindow { 
                        objectName: "taskbarActiveWindow"
                        bar: root
                        monitor: Brightness.getMonitorForScreen(root.screen)
                        }
                    }
                }
            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    Tray {
                        objectName: "taskbarTray"
                        }
                    }
                }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {
                        objectName: "taskbarClock"
                        }
                    }
                }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    StatusIcons {
                        objectName: "taskbarStatusIcons"
                        }
                    }
                }
            DelegateChoice {
                roleValue: "power"
                delegate: EntryWrapper {
                    Power {
                        objectName: "taskbarPowerButton"
                        screenState: root.screenState
                        }
                    }
                }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id

        Layout.leftMargin: root.isHorizontal && index === 0 ? root.edgePadding : 0
        Layout.rightMargin: root.isHorizontal && index === repeater.count - 1 ? root.edgePadding : 0
        Layout.topMargin: !root.isHorizontal && index === 0 ? root.edgePadding : 0
        Layout.bottomMargin: !root.isHorizontal && index === repeater.count - 1 ? root.edgePadding : 0
        Layout.alignment: root.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
        
        Layout.fillWidth: root.isHorizontal && entryId === "spacer"
        Layout.fillHeight: !root.isHorizontal && entryId === "spacer"

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0
        children: item
    }
}
