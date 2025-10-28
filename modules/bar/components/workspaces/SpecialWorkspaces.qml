pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property string activeSpecial: (Config.bar.workspaces.perMonitorWorkspaces ? monitor : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace.name ?? ""

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: mask
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.full

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.3
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            radius: Appearance.rounding.full
            implicitHeight: parent.height / 2
            opacity: view.contentY > 0 ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            radius: Appearance.rounding.full
            implicitHeight: parent.height / 2
            opacity: view.contentY < view.contentHeight - parent.height + Appearance.padding.small ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }
    }

    ListView {
        id: view

        anchors.fill: parent
        spacing: Appearance.spacing.normal
        interactive: false

        currentIndex: model.values.findIndex(w => w.name === root.activeSpecial)
        onCurrentIndexChanged: currentIndex = Qt.binding(() => model.values.findIndex(w => w.name === root.activeSpecial))

        model: ScriptModel {
            values: Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (!Config.bar.workspaces.perMonitorWorkspaces || w.monitor === root.monitor))
        }

        preferredHighlightBegin: 0
        preferredHighlightEnd: height
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightFollowsCurrentItem: false
        highlight: Item {
            y: view.currentItem?.y ?? 0
            implicitHeight: view.currentItem?.size ?? 0

            Behavior on y {
                Anim {}
            }
        }

        delegate: ColumnLayout {
            id: ws

            required property HyprlandWorkspace modelData
            readonly property int size: label.Layout.preferredHeight + (hasWindows ? windows.implicitHeight + Appearance.padding.small : 0)
            property int wsId
            property string icon
            property bool hasWindows

            anchors.left: view.contentItem.left
            anchors.right: view.contentItem.right

            spacing: 0

            Component.onCompleted: {
                wsId = modelData.id;
                icon = Icons.getSpecialWsIcon(modelData.name);
                hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && modelData.lastIpcObject.windows > 0;
            }

            // Hacky thing cause modelData gets destroyed before the remove anim finishes
            Connections {
                target: ws.modelData

                function onIdChanged(): void {
                    if (ws.modelData)
                        ws.wsId = ws.modelData.id;
                }

                function onNameChanged(): void {
                    if (ws.modelData)
                        ws.icon = Icons.getSpecialWsIcon(ws.modelData.name);
                }

                function onLastIpcObjectChanged(): void {
                    if (ws.modelData)
                        ws.hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
                }
            }

            Connections {
                target: Config.bar.workspaces

                function onShowWindowsOnSpecialWorkspacesChanged(): void {
                    if (ws.modelData)
                        ws.hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
                }
            }

            Loader {
                id: label

                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.preferredHeight: Config.bar.sizes.innerWidth - Appearance.padding.small * 2

                asynchronous: true
                sourceComponent: ws.icon.length === 1 ? letterComp : iconComp

                Component {
                    id: iconComp

                    MaterialIcon {
                        fill: 1
                        text: ws.icon
                        verticalAlignment: Qt.AlignVCenter
                    }
                }

                Component {
                    id: letterComp

                    StyledText {
                        text: ws.icon
                        verticalAlignment: Qt.AlignVCenter
                    }
                }
            }

            Loader {
                id: windows

                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.preferredHeight: implicitHeight

                visible: active
                active: ws.hasWindows
                asynchronous: true

                sourceComponent: Column {
                    spacing: 0

                    add: Transition {
                        Anim {
                            properties: "scale"
                            from: 0
                            to: 1
                            easing.bezierCurve: Appearance.anim.curves.standardDecel
                        }
                    }

                    move: Transition {
                        Anim {
                            properties: "scale"
                            to: 1
                            easing.bezierCurve: Appearance.anim.curves.standardDecel
                        }
                        Anim {
                            properties: "x,y"
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: Hypr.toplevels.values.filter(c => c.workspace?.id === ws.wsId)
                        }

                        MaterialIcon {
                            required property var modelData

                            grade: 0
                            text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                Behavior on Layout.preferredHeight {
                    Anim {}
                }
            }
        }

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }

        remove: Transition {
            Anim {
                property: "scale"
                to: 0.5
                duration: Appearance.anim.durations.small
            }
            Anim {
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        displaced: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }
    }

    Loader {
        active: Config.bar.workspaces.activeIndicator
        asynchronous: true
        anchors.fill: parent

        sourceComponent: Item {
            StyledClippingRect {
                id: indicator

                anchors.left: parent.left
                anchors.right: parent.right

                y: (view.currentItem?.y ?? 0) - view.contentY
                implicitHeight: view.currentItem?.size ?? 0

                color: Colours.palette.m3tertiary
                radius: Appearance.rounding.full

                Colouriser {
                    source: view
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onTertiary

                    anchors.horizontalCenter: parent.horizontalCenter

                    x: 0
                    y: -indicator.y
                    implicitWidth: view.width
                    implicitHeight: view.height
                }

                Behavior on y {
                    Anim {
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }

                Behavior on implicitHeight {
                    Anim {
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
            }
        }
    }

    MouseArea {
        property real startY

        anchors.fill: view

        drag.target: view.contentItem
        drag.axis: Drag.YAxis
        drag.maximumY: 0
        drag.minimumY: Math.min(0, view.height - view.contentHeight - Appearance.padding.small)

        onPressed: event => startY = event.y

        onClicked: event => {
            if (Math.abs(event.y - startY) > drag.threshold)
                return;

            const ws = view.itemAt(event.x, event.y);
            if (ws?.modelData)
                Hypr.dispatch(`togglespecialworkspace ${ws.modelData.name.slice(8)}`);
            else
                Hypr.dispatch("togglespecialworkspace special");
        }
    }
}
