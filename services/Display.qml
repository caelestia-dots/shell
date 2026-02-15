pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import Caelestia
import Caelestia.Internal
import qs.services


Singleton {
    id: root

    readonly property var monitors: Hyprland.monitors.values || Hyprland.monitors
    
    // Explicitly track monitor count for debugging
    onMonitorsChanged: console.log(`[Display] Monitors changed. Count: ${monitors ? monitors.length : "null"}`)

    readonly property var internalMonitor: {
        const mons = root.monitors;
        if (!mons || mons.length === 0) return null;
        for (let i = 0; i < mons.length; i++) {
            if (mons[i].name.startsWith("eDP")) return mons[i];
        }
        return mons[0];
    }

    readonly property var externalMonitor: {
        const mons = root.monitors;
        if (!mons || mons.length < 2) return null;
        const im = internalMonitor;
        for (let i = 0; i < mons.length; i++) {
            if (mons[i] !== im) return mons[i];
        }
        return null;
    }

    property var selectedMonitor: internalMonitor
    
    Connections {
        target: Hyprland
        function onMonitorsChanged() {
            if (!selectedMonitor && internalMonitor) {
                selectedMonitor = internalMonitor;
            }
        }
    }

    enum DisplayMode {
        InternalOnly,
        ExternalOnly,
        Mirror,
        Extend
    }

    function setMode(mode) {
        // Access monitors from Hyprland directly to debug
        const originalMons = Hyprland.monitors;
        let mons = [];
        if (Array.isArray(originalMons)) mons = originalMons;
        else if (originalMons.values) mons = (typeof originalMons.values === "function" ? originalMons.values() : originalMons.values);
        else if (originalMons.count !== undefined) {
             for(let i=0; i<originalMons.count; i++) mons.push(originalMons.get(i));
        }
        
        console.log(`[Display] Monitors detection: count=${mons.length} | type=${typeof originalMons}`);
        
        let internal = "";
        let external = "";

        // Find internal
        for (let i = 0; i < mons.length; i++) {
            if (mons[i].name.startsWith("eDP")) {
                internal = mons[i].name;
                break;
            }
        }
        if (!internal && mons.length > 0) internal = mons[0].name;

        // Find external
        for (let i = 0; i < mons.length; i++) {
            if (mons[i].name !== internal) {
                external = mons[i].name;
                break;
            }
        }

        const modeLabels = [qsTr("PC screen only"), qsTr("Second screen only"), qsTr("Duplicate"), qsTr("Extend")];
        const selectedModeLabel = modeLabels[mode] || mode;
        console.log(`[Display] Setting mode: ${selectedModeLabel} | internal: ${internal} | external: ${external} | total mons: ${mons.length}`);
        Toaster.toast(qsTr("Display Configuration"), qsTr("Setting mode: %1").arg(selectedModeLabel), "monitor");

        if (!internal && !external) {
             Toaster.toast(qsTr("Display Configuration"), qsTr("No monitors found!"), "error");
             return;
        }

        switch(mode) {
            case root.DisplayMode.InternalOnly:
                if (internal) {
                    extras.message(`keyword monitor ${internal},preferred,auto,1`);
                    for (let i = 0; i < mons.length; i++) {
                        if (mons[i].name !== internal) extras.message(`keyword monitor ${mons[i].name},disable`);
                    }
                }
                break;
            
            case root.DisplayMode.ExternalOnly:
                if (external) {
                    extras.message(`keyword monitor ${external},preferred,auto,1`);
                    for (let i = 0; i < mons.length; i++) {
                        if (mons[i].name !== external) extras.message(`keyword monitor ${mons[i].name},disable`);
                    }
                }
                break;

            case root.DisplayMode.Mirror:
                if (internal && external) {
                    extras.message(`keyword monitor ${external},preferred,auto,1,mirror,${internal}`);
                    extras.message(`keyword monitor ${internal},preferred,auto,1`);
                }
                break;

            case root.DisplayMode.Extend:
                if (internal) extras.message(`keyword monitor ${internal},preferred,auto,1`);
                if (external) extras.message(`keyword monitor ${external},preferred,auto,1,auto,1`);
                break;
        }
    }

    function identify(monitorName) {
        Toaster.toast(qsTr("Identity"), qsTr("Monitor: %1").arg(monitorName), "monitor");
    }

    function applyConfig(monitorName, res, pos, scale, transform = 0) {
        // Ensure res doesn't have NaN and provide a sane default
        let cleanRes = res || "preferred";
        if (cleanRes.includes("NaN")) cleanRes = "preferred";
        
        // Hyprland monitor keyword syntax: monitor=NAME,RES,OFFSET,SCALE,transform,TRANSFORM
        const cmd = `keyword monitor ${monitorName},${cleanRes},${pos},${scale},transform,${transform}`;
        console.log(`[Display] Applying config: ${cmd}`);
        extras.message(cmd);
        
        refreshTimer.restart();
    }
    
    function setResolution(monitorName, resolution) {
        const mon = findByName(monitorName);
        if (!mon) return;
        const pos = `${mon.x}x${mon.y}`;
        const scale = mon.scale;
        const transform = mon.transform;
        
        applyConfig(monitorName, resolution, pos, scale, transform);
    }

    function setScale(monitorName, scale) {
        const mon = findByName(monitorName);
        if (!mon) return;
        const rr = isNaN(mon.refreshRate) ? 60 : mon.refreshRate;
        const res = `${mon.width}x${mon.height}@${rr}`;
        const pos = `${mon.x}x${mon.y}`;
        const transform = mon.transform;
        applyConfig(monitorName, res, pos, scale, transform);
    }

    function setTransform(monitorName, transform) {
        const mon = findByName(monitorName);
        if (!mon) return;
        const rr = isNaN(mon.refreshRate) ? 60 : mon.refreshRate;
        const res = `${mon.width}x${mon.height}@${rr}`;
        const pos = `${mon.x}x${mon.y}`;
        const scale = mon.scale;
        applyConfig(monitorName, res, pos, scale, transform);
    }

    function resetToPreferred(monitorName) {
        extras.message(`keyword monitor ${monitorName},preferred,auto,1`);
    }

    function setManualResolution(monitorName, resString) {
        const mon = findByName(monitorName);
        if (!mon) return;
        const pos = `${mon.x}x${mon.y}`;
        const scale = mon.scale;
        applyConfig(monitorName, resString, pos, scale, mon.transform);
    }

    function findByName(name) {
        const mons = root.monitors;
        if (!mons) return null;
        for (let i = 0; i < mons.length; i++) {
            if (mons[i].name === name) return mons[i];
        }
        return null;
    }

    function toggleProjector() {
        Visibilities.toggleProjector();
    }
    
    // Helper to extract numeric values from availableModes strings (e.g., "1920x1080@60.00Hz")
    function parseModes(modes) {
        if (!modes || !Array.isArray(modes)) return [];
        const result = [];
        for (let i = 0; i < modes.length; i++) {
            result.push({ text: modes[i], value: modes[i] });
        }
        return result;
    }

    HyprExtras { id: extras }
    Timer {
        id: refreshTimer
        interval: 1000
        repeat: false
        onTriggered: {
            Hyprland.refreshMonitors();
            Hyprland.refreshWorkspaces();
        }
    }
}
