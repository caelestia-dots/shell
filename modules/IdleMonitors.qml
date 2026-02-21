pragma ComponentBehavior: Bound

import "lock"
import qs.config
import qs.services
import Caelestia.Internal
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    required property Lock lock
    readonly property bool enabled: !Config.general.idle.inhibitWhenAudio || !Players.list.some(p => p.isPlaying)

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        if (action === "lock")
            lock.lock.locked = true;
        else if (action === "unlock")
            lock.lock.locked = false;
        else if (typeof action === "string")
            Hypr.dispatch(action);
        else
            Quickshell.execDetached(action);
    }

    LogindManager {
        onAboutToSleep: {
            if (Config.general.idle.lockBeforeSleep)
                root.lock.lock.locked = true;
        }
        onLockRequested: root.lock.locked = true
        onUnlockRequested: root.lock.unlock()
    }

    Variants {
        model: Config.general.idle.timeouts

        IdleMonitor {
            required property var modelData

            enabled: root.enabled && (modelData.enabled ?? true)
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true

            onIsIdleChanged: {
                root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction);

                let idleActionString = "";
                if (typeof modelData.idleAction === "string")
                    idleActionString = modelData.idleAction;
                else if (Array.isArray(modelData.idleAction))
                    idleActionString = modelData.idleAction.join(" ");

                if (idleActionString.includes("dpms off")) {
                    if (root.lock.pam) {
                        root.lock.pam.screenIsIdle = isIdle;
                    }
                }
            }
        }
    }
}
