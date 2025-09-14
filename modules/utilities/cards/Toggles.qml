import qs.components
import qs.services
import qs.config
import qs.modules.controlcenter
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

StyledRect {
    id: root

    required property var visibilities

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2

    radius: Appearance.rounding.normal
    color: Colours.palette.m3surfaceContainer

    GridLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large

        columns: 2
        rowSpacing: Appearance.spacing.normal
        columnSpacing: Appearance.spacing.normal
        uniformCellWidths: true

        StyledText {
            Layout.columnSpan: 2
            text: qsTr("Quick Toggles")
            font.pointSize: Appearance.font.size.normal
        }

        Toggle {
            icon: "wifi"
            text: qsTr("WiFi")
            checked: Network.wifiEnabled

            function onClicked(): void {
                Network.toggleWifi();
            }
        }

        Toggle {
            icon: "bluetooth"
            text: qsTr("Bluetooth")
            checked: Bluetooth.defaultAdapter?.enabled ?? false

            function onClicked(): void {
                const adapter = Bluetooth.defaultAdapter;
                if (adapter)
                    adapter.enabled = !adapter.enabled;
            }
        }

        Toggle {
            icon: "mic"
            text: qsTr("Microphone")
            checked: !Audio.sourceMuted

            function onClicked(): void {
                const audio = Audio.source?.audio;
                if (audio)
                    audio.muted = !audio.muted;
            }
        }

        Toggle {
            icon: "settings"
            text: qsTr("Settings")
            toggle: false

            function onClicked(): void {
                root.visibilities.utilities = false;
                WindowFactory.create(null, {
                    screen: QsWindow.window?.screen ?? null
                });
            }
        }

        Toggle {
            id: gameMode
            icon: "gamepad"
            text: qsTr("Game Mode")
            toggle: true

            function onClicked(): void {
                if (internalChecked) {
                   Quickshell.execDetached(["bash", "-c", `hyprctl --batch "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"`])
                } else {
                    Quickshell.execDetached(["hyprctl", "reload"])
                }
            }

            Process {
                id: fetchActiveState
                running: true
                command: ["bash", "-c", `test "$(hyprctl getoption animations:enabled -j | jq ".int")" -ne 0`]
                onExited: (exitCode, exitStatus) => {
                    gameMode.internalChecked = exitCode !== 0
                }
            }
        }
    }

    component Toggle: StyledRect {
        id: toggle

        required property string icon
        required property string text
        property bool checked
        property bool toggle
        property bool internalChecked

        function onClicked(): void {
        }

        onCheckedChanged: internalChecked = checked

        radius: internalChecked ? Appearance.rounding.small : implicitHeight / 2
        color: internalChecked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

        Layout.fillWidth: true
        implicitWidth: label.implicitWidth + Appearance.padding.larger * 2
        implicitHeight: label.implicitHeight + Appearance.padding.smaller * 2

        StateLayer {
            color: toggle.internalChecked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            function onClicked(): void {
                if (toggle.toggle)
                    toggle.internalChecked = !toggle.internalChecked;
                toggle.onClicked();
            }
        }

        RowLayout {
            id: label

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: toggle.icon
                color: toggle.internalChecked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                fill: toggle.internalChecked ? 1 : 0

                Behavior on fill {
                    Anim {}
                }
            }

            StyledText {
                text: toggle.text
                color: toggle.internalChecked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.small
            }
        }

        Behavior on radius {
            Anim {}
        }
    }
}
