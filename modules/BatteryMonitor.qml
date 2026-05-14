import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config

Scope {
    id: root

    readonly property list<var> warnLevels: [...GlobalConfig.general.battery.warnLevels].sort((a, b) => b.level - a.level)

    function nearestWarnLevelAbove(p: number): var {
        const ordered = [...root.warnLevels].sort((a, b) => a.level - b.level);
        for (const level of ordered) {
            if (p < level.level)
                return level;
        }
        return null;
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            if (UPower.onBattery) {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
                const p = UPower.displayDevice.percentage * 100;
                const level = root.nearestWarnLevelAbove(p);
                if (level)
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
            } else {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
            }
        }

        target: UPower
    }

    Connections {
        function onReadyChanged(): void {
            if (!UPower.displayDevice.ready)
                return;

            const p = UPower.displayDevice.percentage * 100;
            const level = root.nearestWarnLevelAbove(p);
            if (level)
                Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
        }

        target: UPower.displayDevice
    }

    Connections {
        function onPercentageChanged(): void {
            if (!UPower.onBattery)
                return;

            const p = UPower.displayDevice.percentage * 100;
            for (const level of root.warnLevels) {
                if (p == level.level) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
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
        onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
    }
}
