pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services

Column {
    id: root

    readonly property var excluded: Config.bar.status.peripheralBatteryExcluded

    spacing: Tokens.spacing.small

    Repeater {
        model: ScriptModel {
            values: UPower.devices.values.filter(d => !d.isLaptopBattery && d.type !== UPowerDeviceType.LinePower && d.isPresent && !root.excluded.some(e => e === d.model || e === d.nativePath))
        }

        Row {
            id: peripheralRow

            required property UPowerDevice modelData

            spacing: Tokens.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const t = peripheralRow.modelData.type;
                    if (t === UPowerDeviceType.Mouse || t === UPowerDeviceType.Touchpad)
                        return "mouse";
                    if (t === UPowerDeviceType.Keyboard)
                        return "keyboard";
                    if (t === UPowerDeviceType.Headset || t === UPowerDeviceType.Headphones)
                        return "headphones";
                    if (t === UPowerDeviceType.GamingInput)
                        return "sports_esports";
                    if (t === UPowerDeviceType.Pen)
                        return "stylus";
                    if (t === UPowerDeviceType.Speakers || t === UPowerDeviceType.OtherAudio)
                        return "speaker";
                    if (t === UPowerDeviceType.Phone)
                        return "smartphone";
                    return "battery_full";
                }
                color: Colours.palette.m3onSurface
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: (peripheralRow.modelData.model || "Device") + ": " + Math.round(peripheralRow.modelData.percentage * 100) + "%"
            }
        }
    }
}
