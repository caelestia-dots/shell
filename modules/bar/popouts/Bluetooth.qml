pragma ComponentBehavior: Bound

import qs.widgets
import qs.config
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        text: qsTr("Bluetooth %1").arg(BluetoothAdapterState.toString(Bluetooth.defaultAdapter.state).toLowerCase())
    }

    StyledText {
        text: qsTr("%n connected device(s)", "", Bluetooth.devices.values.filter(d => d.connected).length)
    }

    Repeater {
        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        }

        RowLayout {
            id: device

            required property var modelData
            readonly property bool loading: device.modelData.state === BluetoothDeviceState.Connecting || device.modelData.state === BluetoothDeviceState.Disconnecting

            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: Icons.getBluetoothIcon(device.modelData.icon)
            }

            StyledText {
                Layout.fillWidth: true
                text: device.modelData.name
            }

            Item {
                id: connectBtn

                implicitWidth: loadingIndicator.implicitWidth - Appearance.padding.small * 2
                implicitHeight: loadingIndicator.implicitHeight - Appearance.padding.small * 2

                BusyIndicator {
                    id: loadingIndicator

                    anchors.centerIn: parent

                    implicitWidth: Appearance.font.size.large * 2 + Appearance.padding.small * 2
                    implicitHeight: Appearance.font.size.large * 2 + Appearance.padding.small * 2

                    background: null
                    running: opacity > 0
                    opacity: device.loading ? 1 : 0

                    Behavior on opacity {
                        Anim {}
                    }
                }

                StateLayer {
                    radius: Appearance.rounding.full
                    disabled: device.loading

                    function onClicked(): void {
                        device.modelData.connected = !device.modelData.connected;
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    animate: true
                    text: device.modelData.connected ? "link_off" : "link"

                    font.pointSize: device.loading ? Appearance.font.size.normal : Appearance.font.size.larger

                    Behavior on font.pointSize {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }
                }
            }

            Loader {
                asynchronous: true
                active: device.modelData.paired
                sourceComponent: Item {
                    implicitWidth: connectBtn.implicitWidth
                    implicitHeight: connectBtn.implicitHeight

                    StateLayer {
                        radius: Appearance.rounding.full

                        function onClicked(): void {
                            device.modelData.forget();
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "delete"
                    }
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
