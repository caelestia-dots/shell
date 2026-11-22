pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import Caelestia.State
import qs.services
import qs.modules.lock

Scope {
    id: root

    required property Lock lock
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly property bool isCharging: !UPower.onBattery
    readonly property bool enabled: {
        // Hyprland ignores the protocol inhibitor on its 0x0 surface, so the Keep awake toggle is enforced here
        if (RuntimeState.inhibitIdle)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return true;
    }

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        if (action === "lock")
            lock.lock.locked = true;
        else if (action === "unlock")
            lock.lock.locked = false;
        else if (typeof action === "string")
            Hypr.dispatch(Hypr.usingLua && ["dpms off", "dpms on"].includes(action) ? `hl.dsp.dpms({ action = "${action === "dpms off" ? "disable" : "enable"}" })` : action);
        else if (!SessionManager.exec(action))
            Quickshell.execDetached(action);
    }

    Connections {
        function onAboutToSleep(): void {
            if (GlobalConfig.general.idle.lockBeforeSleep)
                root.lock.lock.locked = true;
        }

        function onLockRequested(): void {
            root.lock.lock.locked = true;
        }

        function onUnlockRequested(): void {
            root.lock.lock.unlock();
        }

        target: SessionManager
    }

    // Bench rest: darken the screen 8 s before the idle lock (same conditions as that timeout)
    IdleMonitor {
        readonly property var entry: GlobalConfig.general.idle.timeouts.values.find(t => t.idleAction === "lock") ?? null

        enabled: {
            if (!root.enabled || !NotchSettings.values.animBench || !entry || !(entry.enabled ?? true) || entry.timeout <= 10 || root.lock.lock.locked)
                return false;
            if (entry.inhibitWhenAudio && root.hasPlayer)
                return false;
            if (entry.inhibitWhenCharging && root.isCharging)
                return false;
            return true;
        }
        timeout: Math.max(1, (entry?.timeout ?? 0) - 8)
        respectInhibitors: entry?.respectInhibitors ?? true
        onIsIdleChanged: root.lock.resting = isIdle
    }

    Variants {
        model: GlobalConfig.general.idle.timeouts.values

        IdleMonitor {
            required property var modelData

            enabled: {
                if (!root.enabled || !(modelData.enabled ?? true))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                return true;
            }
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
