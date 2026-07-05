import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.Services

Scope {
    id: root

    readonly property var lowWarnLevels: [...GlobalConfig.general.battery.lowBatteryWarnLevels].sort((a, b) => a.level - b.level)
    readonly property bool lowWarningEnabled: GlobalConfig.general.battery.enableLowBatteryWarning
    readonly property var chargeWarnLevels: [...GlobalConfig.general.battery.chargingWarnLevels].sort((a, b) => a.level - b.level)
    readonly property bool chargeWarningEnabled: GlobalConfig.general.battery.enableHighBatteryWarning

    MediaPlayer {
        id: notifyLowBattery

        source: "root:///assets/LowBattery.ogg"
        audioOutput: AudioOutput {}
    }
    property real lastPercentage: 100

    function handleBatteryWarnings(): void {
        const p = UPower.displayDevice.percentage * 100;

        if (root.lastPercentage >= 0 && UPower.onBattery && lowWarningEnabled) {
            for (const level of root.lowWarnLevels) {
                if (p <= level.level && level.level < root.lastPercentage) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    break;
                }
            }
        }

        if (root.lastPercentage >= 0 && !UPower.onBattery && chargeWarningEnabled) {
            for (const level of root.chargeWarnLevels) {
                if (p >= level.level && level > root.lastPercentage) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    break;
                }
            }
        }

        if (!hibernateTimer.running && p <= GlobalConfig.general.battery.criticalLevel) {
            Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
            hibernateTimer.start();
        }

        root.lastPercentage = p;
    }
    property real lastPercentage: 100

    function handleBatteryWarnings(): void {
        const p = UPower.displayDevice.percentage * 100;

        if (root.lastPercentage >= 0 && UPower.onBattery && lowWarningEnabled) {
            for (const level of root.lowWarnLevels) {
                if (p <= level.level && level.level < root.lastPercentage) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    break;
                }
            }
        }

        if (root.lastPercentage >= 0 && !UPower.onBattery && chargeWarningEnabled) {
            for (const level of root.chargeWarnLevels) {
                if (p >= level.level && level > root.lastPercentage) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    break;
                }
            }
        }

        if (!hibernateTimer.running && p <= GlobalConfig.general.battery.criticalLevel) {
            Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
            hibernateTimer.start();
        }

        root.lastPercentage = p;
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!UPower.displayDevice.ready)
                return;

            if (UPower.onBattery) {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
                root.handleBatteryWarnings();
            } else {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                root.lastPercentage = 100;
            }
        }

        target: UPower
    }

    Connections {
        function onReadyChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Connections {
        function onPercentageChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: SessionManager.hibernate()
    }
}
