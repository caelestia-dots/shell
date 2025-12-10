import qs.config
import Caelestia
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root

    readonly property list<var> warnLevels: [...Config.general.battery.warnLevels].sort((a, b) => b.level - a.level)

    property real lastPercentage: 100

    function currentPercent(): real {
        return UPower.displayDevice.percentage * 100;
    }

    // Fire notifications only for levels that were crossed from above → below
    function notifyCrossedLevels(oldP: real, newP: real): void {
        for (const level of root.warnLevels) {
            if (oldP > level.level && newP <= level.level) {
                Toaster.toast(
                    level.title   ?? qsTr("Battery warning"),
                    level.message ?? qsTr("Battery level is low"),
                    level.icon    ?? "battery_android_alert",
                    level.critical ? Toast.Error : Toast.Warning
                );
            }
        }
    }

    function toastLowestMatchingLevel(p: real): void {
        let chosen = null;
        for (let i = root.warnLevels.length - 1; i >= 0; --i) {
            const level = root.warnLevels[i];
            if (p <= level.level) {
                chosen = level;
                break;
            }
        }

        if (chosen) {
            Toaster.toast(
                chosen.title   ?? qsTr("Battery warning"),
                chosen.message ?? qsTr("Battery level is low"),
                chosen.icon    ?? "battery_android_alert",
                chosen.critical ? Toast.Error : Toast.Warning
            );
        }
    }

    // On startup: if already on battery, show a single toast for the lowest matching level
    Component.onCompleted: {
        const p = currentPercent();
        if (UPower.onBattery)
            root.toastLowestMatchingLevel(p);
        root.lastPercentage = p;
    }

    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            const p = currentPercent();
            if (UPower.onBattery) {
                if (Config.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"),
                                  qsTr("Battery is discharging"),
                                  "power_off");
                root.toastLowestMatchingLevel(p);
            } else {
                if (Config.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"),
                                  qsTr("Battery is charging"),
                                  "power");
            }
            root.lastPercentage = p;
        }
    }

    Connections {
        target: UPower.displayDevice

        function onPercentageChanged(): void {
            if (!UPower.onBattery)
                return;

            const oldP = root.lastPercentage;
            const p    = currentPercent();

            // Only notify for thresholds we actually crossed between oldP and p
            root.notifyCrossedLevels(oldP, p);

            root.lastPercentage = p;

            if (!hibernateTimer.running && p <= Config.general.battery.criticalLevel) {
                Toaster.toast(
                    qsTr("Hibernating in 5 seconds"),
                    qsTr("Hibernating to prevent data loss"),
                    "battery_android_alert",
                    Toast.Error
                );
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
