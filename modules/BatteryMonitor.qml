import qs.config
import qs.services
import Caelestia
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root

    readonly property list<var> warnLevels: [...Config.general.battery.warnLevels].sort((a, b) => b.level - a.level)
    readonly property list<var> powerThresholds: [...Config.general.battery.powerManagement.thresholds].sort((a, b) => b.level - a.level)
    readonly property bool powerManagementEnabled: Config.general.battery.powerManagement.enabled
    
    property var originalSettings: ({
        refreshRates: {},
        animationsEnabled: null,
        blurEnabled: null,
        rounding: null,
        shadowsEnabled: null
    })
    
    property int currentThresholdIndex: -1
    property bool settingsModified: false
    property bool initialized: false

    Component.onCompleted: {
        // Mark as initialized after a short delay to suppress startup toasts
        initTimer.start();
    }
    
    Timer {
        id: initTimer
        interval: 1000
        onTriggered: root.initialized = true
    }
    
    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            if (UPower.onBattery) {
                if (Config.utilities.toasts.chargingChanged && root.initialized)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
                
                if (root.powerManagementEnabled) {
                    root.handleUnpluggedState();
                }
            } else {
                if (Config.utilities.toasts.chargingChanged && root.initialized)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                
                for (const level of root.warnLevels)
                    level.warned = false;
                
                if (root.powerManagementEnabled && root.settingsModified) {
                    root.handleChargingState();
                }
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
            
            if (root.powerManagementEnabled) {
                root.evaluateThresholds();
            }
        }
    }

    Connections {
        target: PowerProfiles

        function onProfileChanged(): void {
            if (!root.powerManagementEnabled)
                return;
            
            const profileBehaviors = Config.general.battery.powerManagement.profileBehaviors;
            let behavior = null;
            let profileName = "";
            
            if (PowerProfiles.profile === PowerProfile.PowerSaver) {
                behavior = profileBehaviors.powerSaver;
                profileName = "Power Saver";
            } else if (PowerProfiles.profile === PowerProfile.Balanced) {
                behavior = profileBehaviors.balanced;
                profileName = "Balanced";
            } else if (PowerProfiles.profile === PowerProfile.Performance) {
                behavior = profileBehaviors.performance;
                profileName = "Performance";
            }
            
            if (behavior) {
                if (behavior.setRefreshRate && behavior.setRefreshRate !== "" && behavior.setRefreshRate !== "unchanged") {
                    root.applyRefreshRate(behavior.setRefreshRate);
                }
                
                root.applyVisualEffects(behavior);
                
                const hasSettings = behavior.disableAnimations !== "" || behavior.disableBlur !== "" || 
                                    behavior.disableRounding !== "" || behavior.disableShadows !== "" ||
                                    (behavior.setRefreshRate && behavior.setRefreshRate !== "" && behavior.setRefreshRate !== "restore");
                
                if (Config.utilities.toasts.lowPowerModeChanged && hasSettings && root.initialized) {
                    const actions = [];
                    if (behavior.setRefreshRate && behavior.setRefreshRate !== "") {
                        actions.push(behavior.setRefreshRate === "auto" ? "lowest Hz" : behavior.setRefreshRate + "Hz");
                    }
                    if (behavior.disableAnimations === "disable") actions.push("no animations");
                    else if (behavior.disableAnimations === "enable") actions.push("animations on");
                    if (behavior.disableBlur === "disable") actions.push("no blur");
                    else if (behavior.disableBlur === "enable") actions.push("blur on");
                    
                    if (actions.length > 0) {
                        Toaster.toast(
                            profileName + qsTr(" profile"),
                            qsTr("Applied: ") + actions.join(", "),
                            "battery_saver"
                        );
                    }
                }
            }
        }
    }
    
    function applyVisualEffects(settings) {
        const options = {};
        
        if (settings.disableAnimations === "disable") options["animations:enabled"] = 0;
        else if (settings.disableAnimations === "enable") options["animations:enabled"] = 1;
        
        if (settings.disableBlur === "disable") options["decoration:blur:enabled"] = 0;
        else if (settings.disableBlur === "enable") options["decoration:blur:enabled"] = 1;
        
        if (settings.disableRounding === "disable") options["decoration:rounding"] = 0;
        else if (settings.disableRounding === "enable") options["decoration:rounding"] = Appearance.rounding.normal;
        
        if (settings.disableShadows === "disable") options["decoration:shadow:enabled"] = 0;
        else if (settings.disableShadows === "enable") options["decoration:shadow:enabled"] = 1;
        
        if (Object.keys(options).length > 0) {
            Hypr.extras.applyOptions(options);
        }
    }
    
    function applyRefreshRate(rate) {
        let targetRate;
        
        if (rate === "auto") {
            targetRate = root.getLowestRefreshRate();
        } else if (rate === "restore") {
            root.restoreRefreshRates();
            return;
        } else {
            targetRate = rate;
        }
        
        const monitors = Hypr.monitors.values || Object.values(Hypr.monitors);
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data) {
                Hypr.extras.message(`keyword monitor ${data.name},${data.width}x${data.height}@${targetRate},${data.x}x${data.y},${data.scale}`);
            }
        }
    }
    
    function getLowestRefreshRate() {
        const monitors = Hypr.monitors.values || Object.values(Hypr.monitors);
        let lowestRate = 60; // Default fallback
        
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data && data.availableModes && data.availableModes.length > 0) {
                const supportedRates = [];
                for (const mode of data.availableModes) {
                    const match = mode.match(/@(\d+(?:\.\d+)?)Hz/);
                    if (match) {
                        const rate = Math.round(parseFloat(match[1]));
                        if (!supportedRates.includes(rate)) {
                            supportedRates.push(rate);
                        }
                    }
                }
                
                supportedRates.sort((a, b) => a - b);
                if (supportedRates.length > 0) {
                    lowestRate = Math.min(lowestRate, supportedRates[0]);
                }
            }
        }
        
        return lowestRate;
    }
    
    function handleUnpluggedState() {
        const unpluggedConfig = Config.general.battery.powerManagement.onUnplugged;
        
        const hasExplicitActions = (unpluggedConfig.setPowerProfile && unpluggedConfig.setPowerProfile !== "") || 
                                   (unpluggedConfig.setRefreshRate && unpluggedConfig.setRefreshRate !== "") ||
                                   unpluggedConfig.disableAnimations !== "" ||
                                   unpluggedConfig.disableBlur !== "" ||
                                   unpluggedConfig.disableRounding !== "" ||
                                   unpluggedConfig.disableShadows !== "";
        
        if (hasExplicitActions) {
            if (!root.settingsModified) {
                root.saveOriginalSettings();
            }
            
            if (unpluggedConfig.setPowerProfile && unpluggedConfig.setPowerProfile !== "") {
                const profileMap = {
                    "power-saver": PowerProfile.PowerSaver,
                    "balanced": PowerProfile.Balanced,
                    "performance": PowerProfile.Performance
                };
                if (profileMap[unpluggedConfig.setPowerProfile] !== undefined) {
                    PowerProfiles.profile = profileMap[unpluggedConfig.setPowerProfile];
                }
            }
            
            const settings = {
                disableAnimations: unpluggedConfig.disableAnimations,
                disableBlur: unpluggedConfig.disableBlur,
                disableRounding: unpluggedConfig.disableRounding,
                disableShadows: unpluggedConfig.disableShadows,
                setRefreshRate: (unpluggedConfig.setRefreshRate && unpluggedConfig.setRefreshRate !== "") ? unpluggedConfig.setRefreshRate : null
            };
            root.applyPowerSavingSettings(settings);
            root.settingsModified = true;
        }
        
        if (unpluggedConfig.evaluateThresholds) {
            root.evaluateThresholds();
        }
    }
    
    function evaluateThresholds() {
        if (!UPower.onBattery || !root.powerManagementEnabled)
            return;
        
        const p = UPower.displayDevice.percentage * 100;
        
        let targetThresholdIndex = -1;
        for (let i = 0; i < root.powerThresholds.length; i++) {
            if (p <= root.powerThresholds[i].level) {
                targetThresholdIndex = i;
                break;
            }
        }
        
        if (targetThresholdIndex !== root.currentThresholdIndex) {
            root.currentThresholdIndex = targetThresholdIndex;
            
            if (targetThresholdIndex >= 0) {
                root.applyThreshold(root.powerThresholds[targetThresholdIndex]);
            }
        }
    }
    
    function applyThreshold(threshold) {
        if (!root.settingsModified) {
            root.saveOriginalSettings();
        }
        
        if (threshold.setPowerProfile && threshold.setPowerProfile !== "") {
            root.setPowerProfile(threshold.setPowerProfile);
        }
        
        root.applyPowerSavingSettings(threshold);
        
        root.settingsModified = true;
        
        const actions = [];
        if (threshold.setPowerProfile && threshold.setPowerProfile !== "") actions.push("profile: " + threshold.setPowerProfile);
        if (threshold.setRefreshRate && threshold.setRefreshRate !== "") actions.push(threshold.setRefreshRate + "Hz");
        if (threshold.disableAnimations === "disable") actions.push("no animations");
        if (threshold.disableBlur === "disable") actions.push("no blur");
        
        if (Config.utilities.toasts.lowPowerModeChanged && root.initialized) {
            Toaster.toast(
                qsTr("Battery saving active"),
                qsTr("Applied: ") + actions.join(", "),
                "battery_saver"
            );
        }
    }
    
    function applyPowerSavingSettings(settings) {
        root.applyVisualEffects(settings);
        
        if (settings.setRefreshRate !== null && settings.setRefreshRate !== undefined && settings.setRefreshRate !== "") {
            root.applyRefreshRate(settings.setRefreshRate);
        }
    }
    
    function saveOriginalSettings() {
        const monitors = Hypr.monitors.values || Object.values(Hypr.monitors);
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data) {
                root.originalSettings.refreshRates[data.name] = data.refreshRate;
            }
        }
    }
    
    function setPowerProfile(profileName) {
        const profileMap = {
            "power-saver": PowerProfile.PowerSaver,
            "balanced": PowerProfile.Balanced,
            "performance": PowerProfile.Performance
        };
        if (profileMap[profileName] !== undefined) {
            PowerProfiles.profile = profileMap[profileName];
        }
    }
    
    function handleChargingState() {
        const config = Config.general.battery.powerManagement.onCharging;
        
        if (config.setPowerProfile === "restore") {
            PowerProfiles.profile = PowerProfile.Balanced;
        } else if (config.setPowerProfile && config.setPowerProfile !== "") {
            root.setPowerProfile(config.setPowerProfile);
        }
        
        if (config.setRefreshRate && config.setRefreshRate !== "" && config.setRefreshRate !== "unchanged") {
            root.applyRefreshRate(config.setRefreshRate);
        }
        
        root.applyVisualEffects(config);
        
        root.settingsModified = false;
        root.currentThresholdIndex = -1;
    }
    
    function restoreSettings() {
        Hypr.extras.message("reload");
    }
    
    function restoreRefreshRates() {
        const monitors = Hypr.monitors.values || Object.values(Hypr.monitors);
        for (const monitor of monitors) {
            const data = monitor.lastIpcObject;
            if (data && root.originalSettings.refreshRates[data.name]) {
                const originalRate = root.originalSettings.refreshRates[data.name];
                Hypr.extras.message(`keyword monitor ${data.name},${data.width}x${data.height}@${originalRate},${data.x}x${data.y},${data.scale}`);
            }
        }
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
    }
}
