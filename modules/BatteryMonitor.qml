import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.utils
import qs.services

Scope {
    id: root

    readonly property var lowWarnLevels: [...GlobalConfig.general.battery.lowBatteryWarnLevels].sort((a, b) => a.level - b.level)
    readonly property bool lowWarningEnabled: GlobalConfig.general.battery.enableLowBatteryWarning
    readonly property var chargeWarnLevels: [...GlobalConfig.general.battery.chargingWarnLevels].sort((a, b) => a.level - b.level)
    readonly property bool chargeWarningEnabled: GlobalConfig.general.battery.enableHighBatteryWarning

    readonly property bool playSound: GlobalConfig.general.battery.toastSound

    property real lastPercentage: 100

    function handleBatteryWarnings(): void {
        const p = UPower.displayDevice.percentage * 100;

        if (root.lastPercentage >= 0 && UPower.onBattery && lowWarningEnabled) {
            for (const level of root.lowWarnLevels) {
                if (p <= level.level && level.level < root.lastPercentage && level.enabled) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    if (playSound) {
                        notifyLowBattery.play();
                    }
                    break;
                }
            }
        }

        if (root.lastPercentage >= 0 && !UPower.onBattery && chargeWarningEnabled) {
            for (const level of root.chargeWarnLevels) {
                if (p >= level.level && level.level > root.lastPercentage && level.enabled) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    if (playSound) {
                        notifyHighBattery.play();
                    }
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

    function matchingAudioDevice(pwNode): var {
        if (!pwNode?.ready)
            return mediaDevices.defaultAudioOutput;

        const name = pwNode.description || pwNode.name;
        for (const dev of mediaDevices.audioOutputs) {
            if (dev.description === name)
                return dev;
        }
        return mediaDevices.defaultAudioOutput;
    }

    MediaDevices {
        id: mediaDevices
    }

    MediaPlayer {
        id: notifyLowBattery

        source: Paths.absolutePath(GlobalConfig.paths.lowBatNotifSound)
        audioOutput: AudioOutput {
            device: root.matchingAudioDevice(Audio.sink)
        }
    }

    MediaPlayer {
        id: notifyHighBattery

        source: Paths.absolutePath(GlobalConfig.paths.highBatNotifSound)
        audioOutput: AudioOutput {
            device: root.matchingAudioDevice(Audio.sink)
        }
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
