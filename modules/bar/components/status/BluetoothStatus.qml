pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
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

        // Connected bluetooth devices — with optional BBM battery ring
        Repeater {
            model: ScriptModel {
                values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected) // qmllint disable unresolved-type
            }

            Item {
                id: device

                required property BluetoothDevice modelData

                // Cached once: avoids calling dataFor() three times in three separate bindings.
                readonly property var bbmEntry: BbmService.available
                    ? BbmService.dataFor(modelData?.address ?? "")
                    : null

                // Ring adds strokeWidth on each side plus 1px breathing room per side.
                implicitWidth: deviceIcon.implicitWidth + batteryRing.strokeWidth * 2 + 2
                implicitHeight: deviceIcon.implicitHeight + batteryRing.strokeWidth * 2 + 2

                // Circular battery ring — only visible when BBM tracks this device
                CircularProgress {
                    id: batteryRing
                    anchors.fill: parent
                    value: (device.bbmEntry?.ComputedLevel ?? 0) / 100
                    visible: device.bbmEntry !== null
                    strokeWidth: 2
                    fgColour: (device.bbmEntry?.ComputedLevel ?? 100) < 20
                        ? Colours.palette.m3error
                        : root.colour
                    bgColour: Qt.alpha(root.colour, 0.2)
                }

                MaterialIcon {
                    id: deviceIcon
                    anchors.centerIn: parent
                    animate: true
                    text: Icons.getBluetoothIcon(device.modelData?.icon)
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
}
