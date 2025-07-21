import qs.widgets
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick

Item {
    id: root

    property color colour: Colours.palette.m3secondary

    property bool showAudio: false
    property bool showNetwork: true
    property bool showBluetooth: true
    property bool showBattery: true

    readonly property var hoverAreas: [
        {
            name: "audio",
            item: audioIcon,
            enabled: showAudio && audioIcon.visible
        },
        {
            name: "network", 
            item: networkIcon,
            enabled: showNetwork && networkIcon.visible
        },
        {
            name: "bluetooth",
            item: bluetoothGroup,
            enabled: showBluetooth && (bluetoothIcon.visible || bluetoothDevices.visible)
        },
        {
            name: "battery",
            item: batteryIcon,
            enabled: showBattery && batteryIcon.visible
        }
    ]

    clip: true
    implicitWidth: iconColumn.implicitWidth
    implicitHeight: iconColumn.implicitHeight

    Column {
        id: iconColumn
        
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Appearance.spacing.smaller / 2

        // Audio icon
        MaterialIcon {
            id: audioIcon
            objectName: "audio"
            visible: root.showAudio
            animate: true
            text: Audio.muted ? "volume_off" :
                Audio.volume >= 0.66 ? "volume_up" :
                Audio.volume >= 0.33 ? "volume_down" : "volume_mute"
            color: root.colour
        }

        // Network icon
        MaterialIcon {
            id: networkIcon
            objectName: "network"
            visible: root.showNetwork
            animate: true
            text: Network.active ? Icons.getNetworkIcon(Network.active.strength ?? 0) : "wifi_off"
            color: root.colour
        }

        // Bluetooth section (grouped for hover area)
        Item {
            id: bluetoothGroup
            visible: root.showBluetooth
            implicitWidth: Math.max(bluetoothIcon.implicitWidth, bluetoothDevices.implicitWidth)
            implicitHeight: bluetoothIcon.implicitHeight + (bluetoothDevices.visible ? bluetoothDevices.implicitHeight + bluetoothDevices.anchors.topMargin : 0)

            // Bluetooth icon
            MaterialIcon {
                id: bluetoothIcon
                objectName: "bluetooth"
                visible: root.showBluetooth
                animate: true
                text: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
                color: root.colour
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Connected bluetooth devices
            Column {
                id: bluetoothDevices
                objectName: "bluetoothDevices"
                spacing: Appearance.spacing.smaller / 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: bluetoothIcon.bottom
                anchors.topMargin: Appearance.spacing.smaller / 2

                Repeater {
                    model: ScriptModel {
                        values: Bluetooth.devices.filter(d => d.connected)
                    }

                    MaterialIcon {
                        required property Bluetooth.Device modelData
                        animate: true
                        text: Icons.getBluetoothIcon(modelData.icon)
                        color: root.colour
                        fill: 1
                    }
                }
            }
        }

        // Battery icon
        MaterialIcon {
            id: batteryIcon
            objectName: "battery"
            visible: root.showBattery
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

    Behavior on implicitHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.large
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}
