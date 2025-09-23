import qs.config
import Caelestia
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root

    readonly property list<var> warnLevels: [...Config.general.battery.warnLevels].sort((a, b) => b.level - a.level)

    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            if (UPower.onBattery) {
                if (Config.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is now on AC"), "power_off");
            } else {
                if (Config.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                for (const level of root.warnLevels)
                    level.warned = false;
            }
        }
    }

    Connections {
        target: UPower.displayDevice

        function onPercentageChanged(): void {
            if (!UPower.onBattery)
                return;

            const p = UPower.displayDevice.percentage * 100;
            for (const level of root.warnLevels) {
                if (p <= level.level && !level.warned) {
                    level.warned = true;
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                }
            }

            if (!hibernateTimer.running && p <= Config.general.battery.criticalLevel) {
                Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
                hibernateTimer.start();
            }
        }
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
    }
}
