import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.modules.controlcenter
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var visibilities

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2

    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        StyledText {
            text: qsTr("Quick Toggles")
            font.pointSize: Appearance.font.size.normal
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            Toggle {
                icon: "wifi"
                checked: Network.wifiEnabled
                onClicked: Network.toggleWifi()
            }

            Toggle {
                icon: "bluetooth"
                checked: Bluetooth.defaultAdapter?.enabled ?? false
                onClicked: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.enabled = !adapter.enabled;
                }
            }

            Toggle {
                icon: "mic"
                checked: !Audio.sourceMuted
                onClicked: {
                    const audio = Audio.source?.audio;
                    if (audio)
                        audio.muted = !audio.muted;
                }
            }

            Toggle {
                icon: "settings"
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                toggle: false
                onClicked: {
                    root.visibilities.utilities = false;
                    WindowFactory.create(null, {
                        screen: QsWindow.window?.screen ?? null
                    });
                }
            }

            Toggle {
                icon: "gamepad"
                checked: GameMode.enabled
                onClicked: GameMode.enabled = !GameMode.enabled
            }

            Toggle {
                icon: "notifications_off"
                checked: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            Toggle {
                icon: "vpn_key"
                checked: VPN.connected
                enabled: !VPN.connecting
                visible: VPN.enabled
                onClicked: VPN.toggle()
            }
        }
    }

    component Toggle: IconButton {
        Layout.fillWidth: true
        Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Appearance.padding.large : internalChecked ? Appearance.padding.smaller : 0)
        radius: stateLayer.pressed ? Appearance.rounding.small / 2 : internalChecked ? Appearance.rounding.small : Appearance.rounding.normal
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        toggle: true
        radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
        radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }
}
