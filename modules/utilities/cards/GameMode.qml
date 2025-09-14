import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell

StyledRect {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2

    radius: Appearance.rounding.normal
    color: Colours.palette.m3surfaceContainer
    clip: true

    property bool toggled

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Appearance.padding.smaller * 2

            radius: Appearance.rounding.full
            color: root.toggled ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: "gamepad"
                color: root.toggled ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                font.pointSize: Appearance.font.size.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Game Mode")
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.toggled ? qsTr("Performance mode active") : qsTr("Visual effects enabled")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
                elide: Text.ElideRight
            }
        }

        StyledSwitch {
            checked: root.toggled
            onToggled: {
                root.toggled = !root.toggled
                if (root.toggled) {
                   Quickshell.execDetached(["bash", "-c", `hyprctl --batch "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"`])
                } else {
                    Quickshell.execDetached(["hyprctl", "reload"])
                }
            }
        }

        Process {
            id: fetchActiveState
            running: true
            command: ["bash", "-c", `test "$(hyprctl getoption animations:enabled -j | jq ".int")" -ne 0`]
            onExited: (exitCode, exitStatus) => {
                root.toggled = exitCode !== 0
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
