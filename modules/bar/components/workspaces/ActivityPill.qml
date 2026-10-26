pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

ClipRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen
    required property var activity // mapped activity from Activities.mappedActivities

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool onSpecial: monitor?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: monitor.activeWorkspace?.id ?? 1
    readonly property var wsIds: root.activity?.workspaceIds ?? []
    readonly property bool isCurrentActivity: {
        const a = root.activity;
        if (!a)
            return false;
        return root.activeWsId >= a.startWs && root.activeWsId <= a.endWs;
    }
    readonly property int activeWsIdx: {
        const idx = root.wsIds.indexOf(root.activeWsId);
        return idx >= 0 ? idx : 0;
    }

    readonly property var workspaces: {
        CUtils.dependency(wsList.itemsDirty);
        return root.wsIds.map((_, i) => wsList.itemAtIndex(i));
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: column.implicitHeight + column.anchors.margins * 2
    opacity: root.fullscreen ? 0 : (root.isCurrentActivity ? 1 : 0.72)

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.extraSmall
        spacing: Tokens.spacing.extraSmall

        // Activity icon header — click focuses first workspace
        Item {
            width: parent.width
            height: headerHit.implicitHeight

            Item {
                id: headerHit

                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.extraSmall
                implicitHeight: implicitWidth

                MaterialIcon {
                    id: headerIcon

                    anchors.centerIn: parent
                    text: root.activity?.icon || "dashboard"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    onClicked: {
                        if (root.activity)
                            Activities.focusActivity(root.activity.id);
                    }
                }
            }
        }

        Item {
            id: wsHost

            width: parent.width
            height: wsList.layoutHeight
            clip: true

            Loader {
                asynchronous: true
                opacity: Config.bar.workspaces.occupiedBg ? 1 : 0
                active: opacity > 0
                anchors.fill: parent
                z: 0

                sourceComponent: OccupiedBg {
                    workspaces: root.workspaces
                    wsSpacing: wsList.spacing
                }
            }

            // Active pill: above markers so Colouriser can recolor them; behind
            // app IconImages so they keep their real colours.
            Loader {
                id: activeIndicatorLoader

                asynchronous: true
                anchors.left: wsList.left
                anchors.right: wsList.right
                anchors.top: wsList.top
                width: wsList.width
                // Height comes from ActiveIndicator child — do not stretch to full list
                z: {
                    CUtils.dependency(wsList.itemsDirty);
                    const ws = wsList.itemAtIndex(root.activeWsIdx) as Workspace;
                    return (ws?.hasDesktopAppIcons ?? false) ? 0 : 2;
                }
                active: Config.bar.workspaces.activeIndicator && root.isCurrentActivity

                sourceComponent: ActiveIndicator {
                    activeWs: {
                        CUtils.dependency(wsList.itemsDirty);
                        return wsList.itemAtIndex(root.activeWsIdx) as Workspace;
                    }
                    mask: wsList
                }
            }

            LazyListView {
                id: wsList

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                z: 1
                implicitHeight: contentHeight
                spacing: Tokens.spacing.extraSmall
                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

                model: ScriptModel {
                    values: root.wsIds
                }

                delegate: Workspace {
                    activeWsId: root.activeWsId
                    ws: modelData
                    monitor: root.monitor
                    displayType: Config.bar.workspaces.displayType
                    showWindows: Config.bar.workspaces.showWindows
                    desktopAppIcons: GlobalConfig.activities.showWindowIcons
                    iconRules: GlobalConfig.bar.workspaces.workspaceIcons
                    activeLabel: Config.bar.workspaces.activeLabel
                    occupiedLabel: Config.bar.workspaces.occupiedLabel
                    label: Config.bar.workspaces.label
                }
            }

            MouseArea {
                anchors.fill: wsList
                z: 3
                onClicked: event => {
                    const ws = (wsList.itemAt(event.x, event.y) as Workspace)?.ws;
                    if (!ws)
                        return;
                    if (Hypr.activeWsId !== ws)
                        Hypr.focusWorkspace(ws);
                    else
                        Hypr.toggleSpecial("special");
                }
            }
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
