pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool onSpecial: monitor?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: monitor.activeWorkspace?.id ?? 1
    readonly property int activeWsIdx: workspaceIndex(activeWsId)

    // Only relevant for when showUnoccupied is true
    readonly property int groupOffset: {
        if (!Config.bar.workspaces.showUnoccupied)
            return 0;
        return Math.floor((activeWsId - 1) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown;
    }

    readonly property real workspaceSpacing: Math.floor(Tokens.spacing.extraSmall)

    property real blur: onSpecial ? 1 : 0

    function workspaceIndex(id: int): int {
        let index = id - 1;
        while (index < 0)
            index += Config.bar.workspaces.shown;
        return index % Config.bar.workspaces.shown;
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: workspaces.implicitHeight + Tokens.padding.small

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

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
            active: Config.bar.workspaces.occupiedBg

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            sourceComponent: OccupiedBg {
                workspaces: workspaces
                occupied: root.occupied
                groupOffset: root.groupOffset
                layoutTransitionRunning: root.revealTransitionRunning
                workspaceIndex: root.workspaceIndex
            }
        }

        LazyListView {
            id: workspaces

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: contentHeight

            spacing: Tokens.spacing.extraSmall

            model: ScriptModel {
                values: {
                    const shown = root.Config.bar.workspaces.shown;

                    if (!root.Config.bar.workspaces.showUnoccupied)
                        return Array.from({
                            length: shown
                        }, (_, i) => i);

                    const ids = [];
                    const workspaces = Hypr.workspaces.values;
                    for (let i = 0; i < workspaces.length && ids.length < shown; i++) {
                        if (workspaces[i].monitor !== root.monitor)
                            continue;
                        // The only workspaces that exist are either occupied or the current one
                        ids.push(workspaces[i].id);
                    }

                    // Return the last `shown` workspaces
                    return ids.length > shown ? ids.slice(-shown) : ids;
                }
            }

            delegate: Workspace {
                activeWsId: root.activeWsId
                ws: root.groupOffset + index + 1
            }
        }

        Loader {
            asynchronous: true
            anchors.horizontalCenter: parent.horizontalCenter
            active: Config.bar.workspaces.activeIndicator

            sourceComponent: ActiveIndicator {
                activeWs: workspaces.itemAtIndex(root.activeWsIdx)
                view: workspaces
                mask: workspaces
                workspaceIndex: root.workspaceIndex
            }
        }

        MouseArea {
            anchors.fill: workspaces
            onClicked: event => {
                const ws = (workspaces.itemAt(event.x, event.y) as Workspace)?.ws;
                if (!ws)
                    return;
                if (Hypr.activeWsId !== ws)
                    Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
                else
                    Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.workspace.toggle_special("special")' : "togglespecialworkspace special");
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

        asynchronous: true

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall

        active: opacity > 0

        scale: root.onSpecial ? 1 : 0.5
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: SpecialWorkspaces {
            screen: root.screen
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

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
