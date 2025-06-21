import "root:/widgets"
import "root:/services"
import "root:/utils"
import "root:/config"
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Item {
    id: root

    property color colour: Colours.palette.m3secondary

    readonly property Item notificationsstatus: notificationsstatus
    readonly property Item network: network
    readonly property real bs: bluetooth.y
    readonly property real be: repeater.count > 0 ? devices.y + devices.implicitHeight : bluetooth.y + bluetooth.implicitHeight
    readonly property Item battery: battery

    clip: true
    implicitWidth: Math.max(notificationsstatus.implicitWidth, network.implicitWidth, bluetooth.implicitWidth, devices.implicitWidth, battery.implicitWidth)
    implicitHeight: notificationsstatus.implicitHeight + network.implicitHeight + network.anchors.topMargin + bluetooth.implicitHeight + bluetooth.anchors.topMargin + (repeater.count > 0 ? devices.implicitHeight + devices.anchors.topMargin : 0) + battery.implicitHeight + battery.anchors.topMargin
    
    MaterialIcon {
        id: notificationsstatus

        animate: true
        text: Notifs.notificationsEnabled ? ( Notifs.popups[0] ? "notifications_unread" : "notifications") : "notifications_off"
        color: root.colour

        anchors.horizontalCenter: parent.horizontalCenter
    }

    MaterialIcon {
        id: network

        anchors.horizontalCenter: notificationsstatus.horizontalCenter
        anchors.top: notificationsstatus.bottom
        anchors.topMargin: Appearance.spacing.small

        animate: true
        text: Network.active ? Icons.getNetworkIcon(Network.active.strength ?? 0) : "wifi_off"
        color: root.colour
    }

    MaterialIcon {
        id: bluetooth

        anchors.horizontalCenter: network.horizontalCenter
        anchors.top: network.bottom
        anchors.topMargin: Appearance.spacing.small

        animate: true
        text: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
        color: root.colour
    }

    Column {
        id: devices

        anchors.horizontalCenter: bluetooth.horizontalCenter
        anchors.top: bluetooth.bottom
        anchors.topMargin: Appearance.spacing.small

        Repeater {
            id: repeater

            model: ScriptModel {
                values: Bluetooth.devices.filter(d => d.connected)
            }

            MaterialIcon {
                required property Bluetooth.Device modelData

                animate: true
                text: Icons.getBluetoothIcon(modelData.icon)
                color: root.colour
            }
        }
    }

    MaterialIcon {
        id: battery

        anchors.horizontalCenter: devices.horizontalCenter
        anchors.top: repeater.count > 0 ? devices.bottom : bluetooth.bottom
        anchors.topMargin: Appearance.spacing.small

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

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }
}
