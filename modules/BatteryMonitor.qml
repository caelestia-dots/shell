import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.Services
import QtMultimedia

Scope {
    id: root

    readonly property list<var> lowWarnLevels: [...GlobalConfig.general.battery.lowBatteryWarnLevels].sort((a, b) => b.level - a.level)
    readonly property list<var> chargeWarnLevels: [...GlobalConfig.general.battery.chargingWarnLevels].sort((a, b) => a.level - b.level)

    MediaPlayer {
        id: notifyLowBattery
        source: "root:///assets/LowBattery.ogg"
        audioOutput: AudioOutput { }
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (UPower.onBattery) {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
                for (const level of root.chargeWarnLevels)
                    level.warned = false;
            } else {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                for (const level of root.lowWarnLevels)
                    level.warned = false;
            }
        }

        target: UPower
    }

    Connections {
        function onPercentageChanged(): void {
            // if (!UPower.onBattery)
            //     return;

            const p = UPower.displayDevice.percentage * 100;
            // If charging check the chargeWarnLevels
            if (!UPower.onBattery){
                for (const level of root.chargeWarnLevels){
                    if (p >= level.level && !level.warned) {
                        level.warned = true;
                        Toaster.toast(level.title ?? qsTr("Charge warning"), level.message ?? qsTr("Battery level is high"), level.icon ?? 'battery_android_alert', level.critical ? Toast.Error : Toast.Warning);                   
                    }
                }
            }
            // If discharging check the lowWarnLevels
            else {
                for (const level of root.lowWarnLevels) {
                    if (p <= level.level && !level.warned) {
                        level.warned = true;
                        Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                        notifyLowBattery.play();
                    }
                }
            }

            if (!hibernateTimer.running && p <= GlobalConfig.general.battery.criticalLevel) {
                Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
                hibernateTimer.start();
            }
        }

        target: UPower.displayDevice
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: SessionManager.hibernate()
    }
}
