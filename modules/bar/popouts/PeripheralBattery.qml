pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.components
import qs.config

Column {
    spacing: Appearance.spacing.small

    Repeater {
        model: ScriptModel {
            values: UPower.devices.values.filter(d => !d.isLaptopBattery && d.type !== UPowerDeviceType.LinePower && d.isPresent && !Config.bar.status.peripheralBatteryExcluded.some(e => e === d.model || e === d.nativePath))
        }

        Row {
            required property UPowerDevice modelData

            spacing: Appearance.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const t = modelData.type;
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
                text: (modelData.model || "Device") + ": " + Math.round(modelData.percentage * 100) + "%"
            }
        }
    }
}
