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

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    required property bool isHorizontal
    required property rect dashboardHitRect
    readonly property int axisPadding: Tokens.padding.large
    readonly property int entryCount: repeater.count
    readonly property var enabledEntries: Config.bar.entries.values.filter(e => e.enabled)
    readonly property int firstSpacerIndex: enabledEntries.findIndex(e => e.id === "spacer")

    readonly property real workspaceWidth: {
        if (!isHorizontal)
            return 0;
        let reserved = axisPadding * 2 + columnSpacing * Math.max(0, entryCount - 1);
        for (const child of children) {
            const entry = child as EntryWrapper;
            if (!entry || entry.entryId === "workspaces")
                continue;
            const item = entry.item;
            reserved += entry.entryId === "activeWindow" ? (item as ActiveWindow).minimumAlong : ((item as Tray)?.nonAnimAlong ?? item.implicitWidth);
        }
        return Math.max(0, width - reserved);
    }

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const tray = (repeater.itemAt(i) as EntryWrapper)?.item as Tray;
            if (tray)
                tray.expanded = false;
        }
    }

    function activeWindowContains(item: Item, x: real): bool {
        if (x < 0 || x >= item.width)
            return false;
        if (!isHorizontal || dashboardHitRect.width <= 0)
            return true;
        const position = item.mapToItem(null, x, 0).x;
        return position < dashboardHitRect.x || position >= dashboardHitRect.x + dashboardHitRect.width;
    }

    function activeWindowCenter(item: Item): real {
        if (!isHorizontal)
            return item.mapToItem(root, 0, item.implicitHeight / 2).y;
        if (dashboardHitRect.width <= 0)
            return item.mapToItem(root, item.width / 2, 0).x;
        const start = item.mapToItem(null, 0, 0).x;
        const leftWidth = Math.max(0, Math.min(item.width, dashboardHitRect.x - start));
        const rightWidth = Math.max(0, Math.min(item.width, start + item.width - dashboardHitRect.x - dashboardHitRect.width));
        // Anchor to an owned interval even when the dashboard splits the title.
        const center = leftWidth >= rightWidth ? leftWidth / 2 : item.width - rightWidth / 2;
        return item.mapToItem(root, center, 0).x;
    }

    function hasNonTitleEntryAt(along: real): bool {
        const entry = childAt(isHorizontal ? along : width / 2, isHorizontal ? height / 2 : along) as EntryWrapper;
        return !!entry?.entryId && entry.entryId !== "activeWindow";
    }

    function checkPopout(along: real): void {
        const ch = childAt(isHorizontal ? along : width / 2, isHorizontal ? height / 2 : along) as EntryWrapper;

        if (ch?.entryId !== "tray")
            closeTray();

        if (!ch?.entryId) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;

        if (id === "statusIcons") {
            const items = (ch.item as StatusIcons).items;
            const icon = items.childAt(isHorizontal ? mapToItem(items, along, 0).x : items.width / 2, isHorizontal ? items.height / 2 : mapToItem(items, 0, along).y);

            if (icon?.present) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => isHorizontal ? icon.mapToItem(root, icon.implicitWidth / 2, 0).x : icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = Config.bar.popouts.statusIcons;
            } else {
                popouts.hasCurrent = false;
            }
        } else if (id === "tray") {
            const tray = ch.item as Tray;
            tray.expanded = true;
            const layout = tray.layout;
            const item = layout ? layout.childAt(isHorizontal ? mapToItem(layout, along, 0).x : layout.width / 2, isHorizontal ? layout.height / 2 : mapToItem(layout, 0, along).y) as TrayItem : null;

            if (item?.modelData) {
                popouts.currentName = `traymenu${item.index}`;
                popouts.currentCenter = Qt.binding(() => isHorizontal ? item.mapToItem(root, item.width / 2, 0).x : item.mapToItem(root, 0, item.height / 2).y);
                popouts.hasCurrent = Config.bar.popouts.tray;
            } else {
                popouts.hasCurrent = false;
            }
        } else if (id === "activeWindow") {
            const item = ch.item as Item;
            if (item && isHorizontal && !activeWindowContains(item, mapToItem(item, along, 0).x)) {
                if (popouts.currentName === "activewindow")
                    popouts.hasCurrent = false;
                return;
            }
            const alreadyOpen = popouts.hasCurrent && popouts.currentName === "activewindow";
            popouts.currentName = "activewindow";
            popouts.currentCenter = item ? activeWindowCenter(item) : 0;
            popouts.hasCurrent = Config.bar.popouts.activeWindow && (Config.bar.activeWindow.showOnHover || alreadyOpen);
        } else {
            const item = ch.item as Item;
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = isHorizontal ? (item ? item.mapToItem(root, item.implicitWidth / 2, 0).x : 0) : (item ? item.mapToItem(root, 0, item.implicitHeight / 2).y : 0);
            popouts.hasCurrent = Config.bar.popouts[id] ?? false;
        }
    }

    function handleWheel(along: real, angleDelta: point): void {
        const ch = childAt(isHorizontal ? along : width / 2, isHorizontal ? height / 2 : along) as EntryWrapper;
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            const mon = Hypr.monitorFor(screen);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || mon.activeWorkspace?.id > 1)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "r${angleDelta.y > 0 ? "-" : "+"}1" })` : `workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (along < (isHorizontal ? screen.width : screen.height) / 2 && Config.bar.scrollActions.volume) {
            // Volume scroll on first half of the bar
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on second half of the bar
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
        }
    }

    rows: isHorizontal ? 1 : -1
    columns: isHorizontal ? -1 : 1
    rowSpacing: isHorizontal ? 0 : Tokens.spacing.medium
    columnSpacing: isHorizontal ? Tokens.spacing.medium : 0

    Repeater {
        id: repeater

        model: ScriptModel {
            values: root.enabledEntries
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: Item {
                    required property int index
                    readonly property bool isFirstSpacer: index === root.firstSpacerIndex
                    Layout.fillWidth: root.isHorizontal && !isFirstSpacer
                    Layout.fillHeight: !root.isHorizontal
                }
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
                        isHorizontal: root.isHorizontal
                        maxWidth: root.workspaceWidth
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    ActiveWindow {
                        objectName: "taskbarActiveWindow"
                        bar: root
                        isHorizontal: root.isHorizontal
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    Tray {
                        objectName: "taskbarTray"
                        isHorizontal: root.isHorizontal
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {
                        objectName: "taskbarClock"
                        isHorizontal: root.isHorizontal
                    }
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    StatusIcons {
                        objectName: "taskbarStatusIcons"
                        isHorizontal: root.isHorizontal
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

        Layout.alignment: root.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
        Layout.leftMargin: root.isHorizontal && index === 0 ? root.axisPadding : 0
        Layout.rightMargin: root.isHorizontal && index === repeater.count - 1 ? root.axisPadding : 0
        Layout.topMargin: !root.isHorizontal && index === 0 ? root.axisPadding : 0
        Layout.bottomMargin: !root.isHorizontal && index === repeater.count - 1 ? root.axisPadding : 0

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
