pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

StyledClippingRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool onSpecial: monitor?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: monitor.activeWorkspace?.id ?? 1
    readonly property int activeWsIdx: workspaceIndex(activeWsId)
    readonly property int shown: Math.max(1, Config.bar.workspaces.shown)
    readonly property bool isHorizontal: Config.bar.alignment === "top" || Config.bar.alignment === "bottom"

    property int itemsRev: 0

    readonly property var wsIds: {
        if (Config.bar.workspaces.showUnoccupied)
            return Array.from({ length: shown }, (_, i) => i + 1);

        const allMonitors = !Config.bar.workspaces.perMonitor;
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const workspaces = Hypr.workspaces.values.filter(w => w.id > 0 && (allMonitors || w.monitor === root.monitor) && (w.id === activeWsId || w.toplevels.values.some(t => !Hypr.isToplevelIgnored(t, ignoredTags))));
        const currentIdx = workspaces.findIndex(w => w.id === activeWsId);
        if (currentIdx < 0) return [];

        const end = CUtils.clamp(currentIdx + 1, Math.min(shown, workspaces.length), workspaces.length);
        const start = Math.max(0, end - shown);
        return workspaces.slice(start, end).map(w => w.id);
    }

    readonly property var workspaces: {
        root.itemsRev;
        return wsIds.map((id, index) => workspacesGrid.itemAt(index));
    }

    readonly property int groupOffset: {
        if (!Config.bar.workspaces.showUnoccupied) return 0;
        return Math.floor((activeWsId - 1) / shown) * shown;
    }

    property real blur: onSpecial ? 1 : 0

    function workspaceIndex(id: int): int {
        if (!Config.bar.workspaces.showUnoccupied) return wsIds.indexOf(id);
        let index = id - 1;
        while (index < 0) index += shown;
        return index % shown;
    }

    implicitWidth: isHorizontal ? (workspacesGrid.implicitWidth + Tokens.padding.extraSmall * 2) : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : (workspacesGrid.implicitHeight + Tokens.padding.extraSmall * 2)

    color: Colours.tPalette.m3surfaceContainer
    
    radius: Math.min(width, height) / 2

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        Loader {
            asynchronous: true
            opacity: Config.bar.workspaces.occupiedBg ? 1 : 0
            active: opacity > 0
            
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            
            sourceComponent: OccupiedBg {
                workspaces: root.workspaces
                wsSpacing: root.isHorizontal ? workspacesGrid.columnSpacing : workspacesGrid.rowSpacing
            }
            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                    }
                }
        }

        GridLayout {
            id: workspacesGrid

            anchors.top: root.isHorizontal ? undefined : parent.top
            anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter
            anchors.left: root.isHorizontal ? parent.left : undefined
            anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
            anchors.topMargin: Tokens.padding.extraSmall
            anchors.leftMargin: Tokens.padding.extraSmall

            flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
            columnSpacing: root.isHorizontal ? Tokens.spacing.extraSmall : 0
            rowSpacing: root.isHorizontal ? 0 : Tokens.spacing.extraSmall
            
            function itemAt(index) {
                root.itemsRev
                return rep.itemAt(index)
            }

            Repeater {
                id: rep
                model: ScriptModel {
                    values: root.wsIds
                }
                
                onItemAdded: root.itemsRev++
                onItemRemoved: root.itemsRev++

                delegate: Workspace {
                    activeWsId: root.activeWsId
                    ws: Config.bar.workspaces.showUnoccupied ? root.groupOffset + index + 1 : modelData
                    monitor: root.monitor
                    displayType: Config.bar.workspaces.displayType
                    showWindows: Config.bar.workspaces.showWindows
                    iconRules: GlobalConfig.bar.workspaces.workspaceIcons
                    activeLabel: Config.bar.workspaces.activeLabel
                    occupiedLabel: Config.bar.workspaces.occupiedLabel
                    label: Config.bar.workspaces.label
                }
            }
        }

        Loader {
            asynchronous: true
            opacity: Config.bar.workspaces.showUnoccupied ? 0 : 1
            active: opacity > 0
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            sourceComponent: GapMarkers {
                workspaces: root.workspaces
                wsSpacing: root.isHorizontal ? workspacesGrid.columnSpacing : workspacesGrid.rowSpacing
            }
            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                    }
                }
        }

        Loader {
            asynchronous: true
            active: Config.bar.workspaces.activeIndicator
            
            anchors.left: root.isHorizontal ? undefined : parent.left
            anchors.right: root.isHorizontal ? undefined : parent.right
            anchors.top: root.isHorizontal ? parent.top : undefined
            anchors.bottom: root.isHorizontal ? parent.bottom : undefined
            anchors.margins: Tokens.padding.extraSmall
            
            sourceComponent: ActiveIndicator {
                activeWs: workspacesGrid.itemAt(root.activeWsIdx)
                mask: workspacesGrid
            }
        }

        MouseArea {
            anchors.fill: workspacesGrid
            onClicked: event => {
                const ws = (workspacesGrid.childAt(event.x, event.y) as Workspace)?.ws;
                if (!ws) return;
                if (Hypr.activeWsId !== ws) Hypr.focusWorkspace(ws);
                else Hypr.toggleSpecial("special");
            }
        }

        Behavior on scale {
            Anim {}
        }
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
                }
            }
    }

    Loader {
        id: specialWs
        anchors.fill: parent
        asynchronous: true
        active: opacity > 0
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: Item {
            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3scrim, Colours.light ? 0 : 0.2)
            }
            SpecialWorkspaces {
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                monitor: root.monitor
                scale: 0.5
                Component.onCompleted: scale = Qt.binding(() => root.onSpecial ? 1 : 0.5)
                Behavior on scale {
                    Anim {}
                }
            }
        }
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
                }
            }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
            }
        }
    Behavior on implicitHeight {
        Anim {}
        }
    Behavior on implicitWidth {
        Anim {}
        }
}