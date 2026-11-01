pragma ComponentBehavior: Bound

import "lock"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import qs.services

Scope {
    id: root

    required property Lock lock
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly property bool isCharging: !UPower.onBattery
    readonly property bool enabled: {
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return true;
    }
    property bool releaseSleepWhenSecure

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        // "unlock" is intentionally not supported: it would unlock without authentication
        // as soon as the user returns from idle
        if (action === "lock")
            lock.lock.locked = true;
        else if (action === "unlock")
            console.warn("Ignoring idle action \"unlock\": unlocking requires authentication");
        else if (typeof action === "string")
            Hypr.dispatch(Hypr.usingLua && ["dpms off", "dpms on"].includes(action) ? `hl.dsp.dpms({ action = "${action === "dpms off" ? "disable" : "enable"}" })` : action);
        else if (!SessionManager.exec(action))
            Quickshell.execDetached(action);
    }

    Connections {
        function onAboutToSleep(): void {
            if (!GlobalConfig.general.idle.lockBeforeSleep)
                return SessionManager.releaseSleepInhibitor();

            root.lock.lock.locked = true;
            // Hold off sleep until the compositor confirms the lock (or the inhibitor times out)
            if (root.lock.lock.secure)
                SessionManager.releaseSleepInhibitor();
            else
                root.releaseSleepWhenSecure = true;
        }

        function onResumed(): void {
            root.releaseSleepWhenSecure = false;
        }

        function onLockRequested(): void {
            root.lock.lock.locked = true;
        }

        function onUnlockRequested(): void {
            root.lock.lock.unlock();
        }

        target: SessionManager
    }

    Connections {
        function onSecureChanged(): void {
            if (root.releaseSleepWhenSecure && root.lock.lock.secure) {
                root.releaseSleepWhenSecure = false;
                SessionManager.releaseSleepInhibitor();
            }
        }

        target: root.lock.lock
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
