pragma ComponentBehavior: Bound

import "lock"
import qs.config
import qs.services
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
            root.lock.lock.locked = true;
        else if (action === "unlock")
            root.lock.lock.locked = false;
        else if (typeof action === "string")
            Hypr.dispatch(action);
        else
            Quickshell.execDetached(action);
    }

    Variants {
        model: Config.general.idle.timeouts

        IdleMonitor {
            required property var modelData

            enabled: root.enabled && (modelData.enabled ?? true)
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
