pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color colour: Colours.palette.m3secondary

    readonly property list<var> hoverAreas: [
        {
            name: "audio",
            item: audioIcon,
            enabled: Config.bar.status.showAudio
        },
        {
            name: "network",
            item: networkIcon,
            enabled: Config.bar.status.showNetwork
        },
        {
            name: "bluetooth",
            item: bluetoothGroup,
            enabled: Config.bar.status.showBluetooth
        },
        {
            name: "battery",
            item: batteryIcon,
            enabled: Config.bar.status.showBattery
        }
    ]

    clip: true
    implicitWidth: iconColumn.implicitWidth
    implicitHeight: iconColumn.implicitHeight

    ColumnLayout {
        id: iconColumn

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Appearance.spacing.smaller / 2

        // Audio icon
        Loader {
            id: audioIcon

            asynchronous: true
            active: Config.bar.status.showAudio
            visible: active

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                color: root.colour
            }
        }

        // Keyboard layout icon
        Loader {
            id: kbLayout

            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.status.showKbLayout
            visible: active

            sourceComponent: StyledText {
                animate: true
                text: Hyprland.kbLayout
                color: root.colour
                font.family: Appearance.font.family.mono
            }
        }

        // Network icon
        Loader {
            id: networkIcon

            asynchronous: true
            active: Config.bar.status.showNetwork
            visible: active

            sourceComponent: MaterialIcon {
                animate: true
                text: Network.active ? Icons.getNetworkIcon(Network.active.strength ?? 0) : "wifi_off"
                color: root.colour
            }
        }

        // Bluetooth section (grouped for hover area)
        Loader {
            id: bluetoothGroup

            asynchronous: true
            active: Config.bar.status.showBluetooth
            visible: active

            sourceComponent: ColumnLayout {
                spacing: Appearance.spacing.smaller / 2

                // Bluetooth icon
                MaterialIcon {
                    animate: true
                    text: {
                        if (!Bluetooth.defaultAdapter?.enabled)
                            return "bluetooth_disabled";
                        if (Bluetooth.devices.values.some(d => d.connected))
                            return "bluetooth_connected";
                        return "bluetooth";
                    }
                    color: root.colour
                }

                // Connected bluetooth devices
                Repeater {
                    model: ScriptModel {
                        values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected)
                    }

                    MaterialIcon {
                        id: device

                        required property BluetoothDevice modelData

                        animate: true
                        text: Icons.getBluetoothIcon(modelData.icon)
                        color: root.colour
                        fill: 1

                        SequentialAnimation on opacity {
                            running: device.modelData.state !== BluetoothDeviceState.Connected
                            alwaysRunToEnd: true
                            loops: Animation.Infinite

                            Anim {
                                from: 1
                                to: 0
                                easing.bezierCurve: Appearance.anim.curves.standardAccel
                            }
                            Anim {
                                from: 0
                                to: 1
                                easing.bezierCurve: Appearance.anim.curves.standardDecel
                            }
                        }
                    }
                }
            }
        }

        // Battery icon
        Loader {
            id: batteryIcon

            asynchronous: true
            active: Config.bar.status.showBattery
            visible: active

            sourceComponent: MaterialIcon {
                animate: true
                text: {
                    if (!UPower.displayDevice.isLaptopBattery) {
                        if (PowerProfiles.profile === PowerProfile.PowerSaver)
                            return "energy_savings_leaf";
                        if (PowerProfiles.profile === PowerProfile.Performance)
                            return "rocket_launch";
                        return "balance";
                    }

                    const perc = UPower.displayDevice.percentage;
                    const charging = !UPower.onBattery;
                    if (perc === 1)
                        return charging ? "battery_charging_full" : "battery_full";
                    let level = Math.floor(perc * 7);
                    if (charging && (level === 4 || level === 1))
                        level--;
                    return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                }
                color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Colours.palette.m3error
                fill: 1
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.large
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}
