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

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    // Combine hoverAreas property (from Merge2) and color/radius (from main)
    readonly property list<var> hoverAreas: [
        {
            name: "notifications",
            item: notificationsIcon,
            enabled: Config.bar.status.showNotifications
        },
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
    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    clip: true
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: iconColumn.implicitHeight + Appearance.padding.normal * 2

    ColumnLayout {
        id: iconColumn

        anchors.centerIn: parent
        spacing: Appearance.spacing.smaller / 2

        // Notifications icon
        Loader {
            id: notificationsIcon

            asynchronous: true
            active: Config.bar.status.showNotifications
            visible: active

            sourceComponent: MaterialIcon {
                animate: true
                text: {
                    if (Notifs.dnd) return "notifications_off"
                    if (Notifs.list.length > 0) return "notifications"
                    return "notifications_none"
                }
                color: Notifs.dnd ? Colours.palette.m3error : root.colour

                MouseArea {
                    anchors.fill: parent
                    onClicked: Notifs.toggleDnd()
                }
            }
        }

        // Audio icon
        WrappedLoader {
            id: audioIcon
            name: "audio"
            active: Config.bar.status.showAudio

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                color: root.colour
            }
        }

        // Keyboard layout icon
        WrappedLoader {
            name: "kblayout"
            active: Config.bar.status.showKbLayout

            sourceComponent: StyledText {
                animate: true
                text: Hyprland.kbLayout
                color: root.colour
                font.family: Appearance.font.family.mono
            }
        }

        // Network icon
        WrappedLoader {
            id: networkIcon
            name: "network"
            active: Config.bar.status.showNetwork

            sourceComponent: MaterialIcon {
                animate: true
                text: Network.active ? Icons.getNetworkIcon(Network.active.strength ?? 0) : "wifi_off"
                color: root.colour
            }
        }

        // Bluetooth section
        WrappedLoader {
            id: bluetoothGroup
            name: "bluetooth"
            active: Config.bar.status.showBluetooth

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
        WrappedLoader {
            id: batteryIcon
            name: "battery"
            active: Config.bar.status.showBattery

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

    component WrappedLoader: Loader {
        required property string name

        Layout.alignment: Qt.AlignHCenter
        asynchronous: true
        visible: active
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.large
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}