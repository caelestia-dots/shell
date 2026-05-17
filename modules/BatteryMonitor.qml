import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import qs.services

Scope {
    id: root

    readonly property list<var> warnLevels: [...GlobalConfig.general.battery.warnLevels].sort((a, b) => b.level - a.level)

    readonly property var pm: GlobalConfig.general.battery.powerManagement
    readonly property bool pmEnabled: pm && pm.enabled === true
    readonly property list<var> powerThresholds: {
        const t = (pm && pm.thresholds) || [];
        return [...t].sort((a, b) => (b.level ?? 0) - (a.level ?? 0));
    }

    property var originalRefreshRates: ({})
    property int currentThresholdIndex: -1
    property bool settingsModified: false
    property bool initialized: false

    function applyVisualEffects(settings): void {
        const options = {};
        if (settings.disableAnimations === "disable")
            options["animations:enabled"] = 0;
        else if (settings.disableAnimations === "enable")
            options["animations:enabled"] = 1;
        if (settings.disableBlur === "disable")
            options["decoration:blur:enabled"] = 0;
        else if (settings.disableBlur === "enable")
            options["decoration:blur:enabled"] = 1;
        if (settings.disableRounding === "disable")
            options["decoration:rounding"] = 0;
        else if (settings.disableRounding === "enable")
            options["decoration:rounding"] = GlobalConfig.appearance.rounding.normal;
        if (settings.disableShadows === "disable")
            options["decoration:shadow:enabled"] = 0;
        else if (settings.disableShadows === "enable")
            options["decoration:shadow:enabled"] = 1;
        if (Object.keys(options).length > 0)
            Hypr.extras.applyOptions(options); // qmllint disable missing-property
    }

    function applyRefreshRate(rate): void {
        if (rate === "restore") {
            restoreRefreshRates();
            return;
        }
        const targetRate = rate === "auto" ? getLowestRefreshRate() : rate;
        const monitors = Object.values(Hypr.monitors.values || Hypr.monitors);
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data)
                Hypr.extras.message(`keyword monitor ${data.name},${data.width}x${data.height}@${targetRate},${data.x}x${data.y},${data.scale}`); // qmllint disable missing-property
        }
    }

    function getLowestRefreshRate(): real {
        const monitors = Object.values(Hypr.monitors.values || Hypr.monitors);
        let lowestRate = 60;
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data && data.availableModes && data.availableModes.length > 0) {
                const rates = [];
                for (const mode of data.availableModes) {
                    const m = mode.match(/@(\d+(?:\.\d+)?)Hz/);
                    if (m) {
                        const r = Math.round(parseFloat(m[1]));
                        if (!rates.includes(r))
                            rates.push(r);
                    }
                }
                rates.sort((a, b) => a - b);
                if (rates.length > 0)
                    lowestRate = Math.min(lowestRate, rates[0]);
            }
        }
        return lowestRate;
    }

    function saveOriginalSettings(): void {
        const monitors = Object.values(Hypr.monitors.values || Hypr.monitors);
        const next = {};
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data)
                next[data.name] = data.refreshRate;
        }
        root.originalRefreshRates = next;
    }

    function restoreRefreshRates(): void {
        const monitors = Object.values(Hypr.monitors.values || Hypr.monitors);
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data && root.originalRefreshRates[data.name]) {
                const orig = root.originalRefreshRates[data.name];
                Hypr.extras.message(`keyword monitor ${data.name},${data.width}x${data.height}@${orig},${data.x}x${data.y},${data.scale}`); // qmllint disable missing-property
            }
        }
    }

    function setPowerProfile(name): void {
        const map = {
            "power-saver": PowerProfile.PowerSaver,
            "balanced": PowerProfile.Balanced,
            "performance": PowerProfile.Performance
        };
        if (map[name] !== undefined)
            PowerProfiles.profile = map[name];
    }

    function handleUnpluggedState(): void {
        const cfg = (root.pm && root.pm.onUnplugged) || {};
        const hasActions = (cfg.setPowerProfile ?? "") !== "" || (cfg.setRefreshRate ?? "") !== "" || (cfg.disableAnimations ?? "") !== "" || (cfg.disableBlur ?? "") !== "" || (cfg.disableRounding ?? "") !== "" || (cfg.disableShadows ?? "") !== "";
        if (hasActions) {
            if (!root.settingsModified)
                root.saveOriginalSettings();
            if ((cfg.setPowerProfile ?? "") !== "")
                root.setPowerProfile(cfg.setPowerProfile);
            root.applyVisualEffects(cfg);
            if ((cfg.setRefreshRate ?? "") !== "")
                root.applyRefreshRate(cfg.setRefreshRate);
            root.settingsModified = true;
        }
        if (cfg.evaluateThresholds !== false)
            root.evaluateThresholds();
    }

    function handleChargingState(): void {
        const cfg = (root.pm && root.pm.onCharging) || {};
        if (cfg.setPowerProfile === "restore")
            PowerProfiles.profile = PowerProfile.Balanced;
        else if ((cfg.setPowerProfile ?? "") !== "")
            root.setPowerProfile(cfg.setPowerProfile);
        if ((cfg.setRefreshRate ?? "") !== "" && cfg.setRefreshRate !== "unchanged")
            root.applyRefreshRate(cfg.setRefreshRate);
        root.applyVisualEffects(cfg);
        root.settingsModified = false;
        root.currentThresholdIndex = -1;
    }

    function evaluateThresholds(): void {
        if (!UPower.onBattery || !root.pmEnabled)
            return;
        const p = UPower.displayDevice.percentage * 100;
        let target = -1;
        for (let i = 0; i < root.powerThresholds.length; i++) {
            if (p <= (root.powerThresholds[i].level ?? 0)) {
                target = i;
                break;
            }
        }
        if (target !== root.currentThresholdIndex) {
            root.currentThresholdIndex = target;
            if (target >= 0)
                root.applyThreshold(root.powerThresholds[target]);
        }
    }

    function applyThreshold(threshold): void {
        if (!root.settingsModified)
            root.saveOriginalSettings();
        if ((threshold.setPowerProfile ?? "") !== "")
            root.setPowerProfile(threshold.setPowerProfile);
        root.applyVisualEffects(threshold);
        if ((threshold.setRefreshRate ?? "") !== "")
            root.applyRefreshRate(threshold.setRefreshRate);
        root.settingsModified = true;

        if (GlobalConfig.utilities.toasts.lowPowerModeChanged && root.initialized) {
            const actions = [];
            if ((threshold.setPowerProfile ?? "") !== "")
                actions.push(qsTr("profile: ") + threshold.setPowerProfile);
            if ((threshold.setRefreshRate ?? "") !== "")
                actions.push(threshold.setRefreshRate === "auto" ? qsTr("lowest Hz") : threshold.setRefreshRate + "Hz");
            if (threshold.disableAnimations === "disable")
                actions.push(qsTr("no animations"));
            if (threshold.disableBlur === "disable")
                actions.push(qsTr("no blur"));
            Toaster.toast(qsTr("Battery saving active"), qsTr("Applied: ") + actions.join(", "), "battery_saver");
        }
    }

    Component.onCompleted: initTimer.start()

    Timer {
        id: initTimer

        interval: 1000
        onTriggered: root.initialized = true
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (UPower.onBattery) {
                if (GlobalConfig.utilities.toasts.chargingChanged && root.initialized)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
                if (root.pmEnabled)
                    root.handleUnpluggedState();
            } else {
                if (GlobalConfig.utilities.toasts.chargingChanged && root.initialized)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                for (const level of root.warnLevels)
                    level.warned = false;
                if (root.pmEnabled)
                    root.handleChargingState();
            }
        }

        target: UPower
    }

    Connections {
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

            if (!hibernateTimer.running && p <= GlobalConfig.general.battery.criticalLevel) {
                Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
                hibernateTimer.start();
            }

            if (root.pmEnabled)
                root.evaluateThresholds();
        }

        target: UPower.displayDevice
    }

    Connections {
        function onProfileChanged(): void {
            if (!root.pmEnabled)
                return;

            const profileBehaviors = (root.pm && root.pm.profileBehaviors) || {};
            let behavior = null;
            let profileName = "";
            if (PowerProfiles.profile === PowerProfile.PowerSaver) {
                behavior = profileBehaviors.powerSaver;
                profileName = qsTr("Power Saver");
            } else if (PowerProfiles.profile === PowerProfile.Balanced) {
                behavior = profileBehaviors.balanced;
                profileName = qsTr("Balanced");
            } else if (PowerProfiles.profile === PowerProfile.Performance) {
                behavior = profileBehaviors.performance;
                profileName = qsTr("Performance");
            }
            if (!behavior)
                return;

            if (behavior.setRefreshRate && behavior.setRefreshRate !== "" && behavior.setRefreshRate !== "unchanged")
                root.applyRefreshRate(behavior.setRefreshRate);
            root.applyVisualEffects(behavior);

            const hasSettings = (behavior.disableAnimations ?? "") !== "" || (behavior.disableBlur ?? "") !== "" || (behavior.disableRounding ?? "") !== "" || (behavior.disableShadows ?? "") !== "" || (behavior.setRefreshRate && behavior.setRefreshRate !== "" && behavior.setRefreshRate !== "restore");
            if (GlobalConfig.utilities.toasts.lowPowerModeChanged && hasSettings && root.initialized) {
                const actions = [];
                if (behavior.setRefreshRate && behavior.setRefreshRate !== "")
                    actions.push(behavior.setRefreshRate === "auto" ? qsTr("lowest Hz") : behavior.setRefreshRate + "Hz");
                if (behavior.disableAnimations === "disable")
                    actions.push(qsTr("no animations"));
                else if (behavior.disableAnimations === "enable")
                    actions.push(qsTr("animations on"));
                if (behavior.disableBlur === "disable")
                    actions.push(qsTr("no blur"));
                else if (behavior.disableBlur === "enable")
                    actions.push(qsTr("blur on"));
                if (actions.length > 0)
                    Toaster.toast(profileName + qsTr(" profile"), qsTr("Applied: ") + actions.join(", "), "battery_saver");
            }
        }

        target: PowerProfiles
    }
}
