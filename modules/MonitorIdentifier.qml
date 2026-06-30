pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

Variants {
    id: root

    readonly property bool active: Monitors.identifying

    model: Quickshell.screens

    StyledWindow {
        id: win

        required property ShellScreen modelData
        readonly property var monitor: Hypr.monitorFor(modelData)

        screen: modelData
        name: "monitor-identifier"
        visible: root.active || identifierRect.opacity > 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        // Click anywhere on the overlay to dismiss
        MouseArea {
            anchors.fill: parent
            onClicked: Monitors.stopIdentification()
        }

        StyledRect {
            id: identifierRect

            anchors.centerIn: parent
            implicitWidth: Tokens.padding.large * 14
            implicitHeight: Tokens.padding.large * 14
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            opacity: root.active ? 0.92 : 0

            // Prevent the MouseArea behind from stealing this click
            MouseArea {
                anchors.fill: parent
                onClicked: Monitors.stopIdentification()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: win.monitor?.id ?? "?"
                    font.pointSize: 96
                    font.bold: true
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: win.monitor?.name ?? ""
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Behavior on opacity {
                Anim {}
            }
        }
    }
}
