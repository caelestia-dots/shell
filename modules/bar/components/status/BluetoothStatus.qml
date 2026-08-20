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

    property string name: "bluetooth"
    required property color colour
    readonly property bool taskbarEnabled: {
        const values = Config.bar?.statusIcons?.values ?? [];
        return values.some(item => item?.id === "bluetooth" && item.enabled !== false);
    }
    readonly property bool showBatteryRing: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryRing)

    readonly property var connectedPhoneBattery: {
        const devices = Bluetooth.devices.values ?? []; // qmllint disable unresolved-type
        for (const device of devices) {
            if (!device?.connected)
                continue;
            const icon = (device.icon ?? "").toLowerCase();
            const isPhone = icon.includes("phone") || icon.includes("android") || icon.includes("smartphone");
            if (!isPhone)
                continue;
            if (device.batteryAvailable !== undefined && device.batteryAvailable !== null) {
                const pct = Number(device.battery) * 100;
                if (Number.isFinite(pct))
                    return { percentage: pct, available: true };
            }
            const bbmEntry = BbmService.available ? BbmService.dataFor(device.address ?? "") : null;
            const bbmLevel = Number(bbmEntry?.ComputedLevel ?? NaN);
            if (Number.isFinite(bbmLevel))
                return { percentage: bbmLevel, available: true };
        }
        return null;
    }

    visible: root.taskbarEnabled
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    RowLayout {
        id: layout

        spacing: Tokens.spacing.extraSmall

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

        MaterialIcon {
            visible: !!root.connectedPhoneBattery
            animate: true
            text: {
                const pct = Number(root.connectedPhoneBattery?.percentage ?? 0);
                if (pct >= 90)
                    return "battery_6_bar";
                if (pct >= 70)
                    return "battery_5_bar";
                if (pct >= 50)
                    return "battery_4_bar";
                if (pct >= 30)
                    return "battery_3_bar";
                if (pct >= 15)
                    return "battery_2_bar";
                return "battery_1_bar";
            }
            color: root.colour
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            visible: !!root.connectedPhoneBattery
            text: `${Math.round(root.connectedPhoneBattery?.percentage ?? 0)}%`
            color: root.colour
            font: Tokens.font.body.small
        }
    }
}
