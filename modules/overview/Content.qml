pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Multimedia
import qs.components
import qs.services
import qs.modules.drawers
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Caelestia.State

Item {
    id: root

    required property Panels panels
    property int refreshTick: 1

    property int workspaces: Math.max(1, Config.bar.workspaces.shown)
    property int rows: 2
    property int columns: Math.ceil(workspaces / rows)
    property real previewScale: 0.3

    property int previewHeight: Math.floor(Screen.height * previewScale / rows)
    property int previewWidth: previewHeight * Screen.width / Screen.height

    property real previewScaleX: previewWidth / Screen.width
    property int spacing: 15
    property int padding: 40

    implicitWidth: columns * (previewWidth + spacing + root.previewScaleX * (spacing - root.panels.bar.width)) + spacing + 10
    implicitHeight: rows * (previewHeight + spacing) + 30

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        WorkspaceData.updateAll();
    }

    // Trigger two times. First time fresh after reload, for responsiveness and second time for completeness
    Connections {

        function onRawEvent(event) {
            const triggers = ["openwindow", "closewindow", "movewindow", "workspace", "activespecial", "createworkspace", "destroyworkspace", "fullscreen", "changefloatingmode"];

            if (triggers.includes(event.name)) {
                Hyprland.refreshToplevels();
                WorkspaceData.updateAll();
                updateTimer.restart();
            }
        }

        target: Hyprland
    }

    // DO NOT REMOVE: After maxmizing a window, setting Windows as not Visible may take a while
    Timer {
        id: updateTimer

        interval: 500 // 500 milliseconds is usually enough for the compositor to settle
        repeat: false
        onTriggered: {
            Hyprland.refreshToplevels();
            WorkspaceData.updateAll();
        }
    }

    // Grid of all Workspaces with 2 rows
    Grid {
        id: workspaceGrid

        anchors.fill: parent
        columns: root.columns
        rows: root.rows
        spacing: root.spacing
        anchors.margins: 20

        Repeater {
            model: root.workspaces

            delegate: ClippingWrapperRectangle {
                id: workspaceCard

                required property int index
                readonly property int workspaceId: index + 1

                width: root.previewWidth + (root.spacing - root.panels.bar.width) * root.previewScaleX
                height: root.previewHeight + (root.spacing - 5) * root.previewScale
                border.color: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === workspaceId ? "#cba6f7" : "#313244"
                border.width: 2
                radius: 8
                clip: true

                child: Item {
                    id: previewBackground

                    property bool isUsed: Hyprland.toplevels.values.filter(window => window.workspace && window.workspace.id === workspaceCard.workspaceId).length > 0

                    anchors.fill: parent

                    // Wallpaper Background
                    Visual {
                        anchors.fill: parent
                        source: Wallpapers.current
                        playing: PersistentState.wallpaperPlaying
                    }

                    // Darkening layer for empty workspaces
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: 0.7
                        visible: !previewBackground.isUsed
                    }

                    // Workspace Header Label
                    StyledText {
                        text: workspaceCard.workspaceId
                        font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !previewBackground.isUsed
                    }

                    // Nested Repeater for windows belonging specifically to this workspace
                    Repeater {
                        id: previewRepeater

                        model: ScriptModel {
                            values: Hyprland.toplevels.values.filter(toplevel => {
                                const _rev = WorkspaceData.clientsRevision;
                                return toplevel.workspace && toplevel.workspace.id === workspaceCard.workspaceId;
                            })
                        }

                        delegate: ClippingWrapperRectangle {
                            id: previewDisplay

                            required property var modelData

                            property var window: WorkspaceData.windowByAddress["0x" + modelData.address]
                            property var monitor: window ? WorkspaceData.monitorById[window.monitor] : null
                            property int xOffset_l: root.panels.bar.width
                            property int tick: root.refreshTick

                            property int should_height: {
                                if (!window || !monitor)
                                    return 100;
                                return (window.size[1]) / (monitor.height) * root.previewHeight * monitor.scale;
                            }
                            property int should_width: {
                                if (!window || !monitor)
                                    return 100;
                                let sol = (window.size[0]) / (monitor.width) * root.previewWidth * monitor.scale;
                                let sol2 = should_height / window.size[1] * window.size[0];
                                if (sol2 > sol) {
                                    should_height = sol / window.size[0] * window.size[1];
                                    return sol;
                                }
                                return sol2;
                            }

                            x: {
                                if (!window || !monitor)
                                    return 0;
                                return (window.at[0] - monitor.x - xOffset_l / monitor.scale) / (monitor.width) * root.previewWidth * monitor.scale;
                            }
                            y: {
                                if (!window || !monitor)
                                    return 0;
                                return (window.at[1] - monitor.y) / monitor.height * root.previewHeight * monitor.scale;
                            }
                            implicitHeight: should_height
                            implicitWidth: should_width
                            radius: 6
                            opacity: {
                                if (!previewDisplay.window) {
                                    console.warn("Window couldn't be displayed because there is no Window Object");
                                    return 0;
                                }
                                if (!previewDisplay.monitor) {
                                    console.warn("Window couldn't be displayed because there is no Monitor Object");
                                    return 0;
                                }
                                if (!previewDisplay.window.visible)
                                    return 0;
                                else
                                    return 1;
                            }
                            clip: true
                            color: "transparent"
                            child: ScreencopyView {
                                id: preview

                                anchors.fill: parent
                                anchors.horizontalCenter: workspaceCard.horizontalCenter
                                captureSource: modelData.wayland
                                live: true
                                layer.enabled: true
                                layer.smooth: true
                                opacity: 1
                            }
                        }
                    }

                    // Click to switch workspace via Hyprland IPC
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (Hyprland.usingLua) {
                                Hyprland.dispatch(`hl.dsp.focus({workspace = '${workspaceCard.workspaceId}'})`);
                            } else {
                                Hyprland.dispatch("workspace " + workspaceCard.workspaceId);
                            }
                        }
                    }
                }
            }
        }
    }
}
