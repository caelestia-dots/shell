//pragma ComponentBehavior: Bound
import QtQuick
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Multimedia
import qs.components
import qs.components.effects
import qs.components.filedialog
import qs.services
import qs.modules.drawers
import qs.modules.drawers
import qs.utils
import QtQuick.Layouts
import Quickshell
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
    property int spacing: 15

    implicitWidth: columns * (previewWidth + spacing) - spacing + 40
    implicitHeight: rows * (previewHeight + spacing) - spacing + 40

    // Main 10-workspace overview grid
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

                width: root.previewWidth
                height: root.previewHeight
                border.color: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === workspaceId ? "#cba6f7" : "#313244"
                border.width: 2
                radius: 8
                clip: true

                child: Item {
                    id: previewBackground
                    anchors.fill: parent

                    property bool isUsed: Hyprland.toplevels.values.filter(window => window.workspace && window.workspace.id === workspaceCard.workspaceId).length > 0

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

                        delegate: Item {
                            id: previewDisplay

                            property var window: WorkspaceData.windowByAddress["0x" + modelData.address]
                            property var monitor: window ? WorkspaceData.monitorById[window.monitor] : null
                            property int xOffset: root.panels.bar.width

                            x: {
                                if (!window || !monitor)
                                    return 0;
                                return (window.at[0] - monitor.x - xOffset) / (monitor.width - previewDisplay.xOffset) * root.previewWidth * monitor.scale * 0.99;
                            }
                            y: {
                                if (!window || !monitor)
                                    return 0;
                                return (window.at[1] - monitor.y) / monitor.height * root.previewHeight * monitor.scale * 0.98;
                            }
                            width: {
                                if (!window || !monitor)
                                    return 0;
                                return window.size[0] / (monitor.width - previewDisplay.xOffset) * root.previewWidth * monitor.scale * 0.99;
                            }
                            height: {
                                if (!window || !monitor)
                                    return 0;
                                return window.size[1] / monitor.height * root.previewHeight * monitor.scale * 0.98;
                            }

                            ClippingWrapperRectangle {
                                anchors.fill: parent
                                radius: 6
                                opacity: {
                                    if (!previewDisplay.window || !previewDisplay.monitor || !previewDisplay.window.visible)
                                        return 0;
                                    else
                                        return 1;
                                }
                                color: "transparent"
                                property int tick: root.refreshTick
                                child: ScreencopyView {
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
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const triggers = ["openwindow", "closewindow", "movewindow", "workspace", "activespecial", "createworkspace", "destroyworkspace", "fullscreen", "changefloatingmode"];

            if (triggers.includes(event.name)) {
                updateTimer.restart();
            }
        }
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
    Component.onCompleted: {
        Hyprland.refreshToplevels();
        WorkspaceData.updateAll();
    }
}
