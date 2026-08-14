pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.utils

Item {
    id: root

    required property color colour

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    ColumnLayout {
        id: layout

        spacing: Tokens.spacing.medium / 2

        // Bluetooth icon
        MaterialIcon {
            animate: true
            text: {
                if (!Bluetooth.defaultAdapter?.enabled) // qmllint disable unresolved-type
                    return "bluetooth_disabled";
                if (Bluetooth.devices.values.some(d => d.connected)) // qmllint disable unresolved-type
                    return "bluetooth_connected";
                return "bluetooth";
            }
            color: root.colour
        }

        // Connected bluetooth devices
        Repeater {
            model: ScriptModel {
                values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected) // qmllint disable unresolved-type
            }

            MaterialIcon {
                id: device

                required property BluetoothDevice modelData

                animate: true
                text: Icons.getBluetoothIcon(modelData?.icon)
                color: root.colour
                fill: 1

                SequentialAnimation on opacity {
                    running: device.modelData?.state !== BluetoothDeviceState.Connected // qmllint disable unresolved-type
                    alwaysRunToEnd: true
                    loops: Animation.Infinite

                    Anim {
                        from: 1
                        to: 0
                        duration: Tokens.anim.durations.large
                        easing: Tokens.anim.standardAccel
                    }
                    Anim {
                        from: 0
                        to: 1
                        duration: Tokens.anim.durations.large
                        easing: Tokens.anim.standardDecel
                    }
                }
            }
        }
    }
}
