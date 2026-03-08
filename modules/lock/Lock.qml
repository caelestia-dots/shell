pragma ComponentBehavior: Bound

import qs.components.misc
import qs.config
import Caelestia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    property alias lock: lock

    WlSessionLock {
        id: lock

        signal unlock

        function screenNames(): var {
            const screens = lock.screens;
            if (!screens)
                return [];

            const names = [];
            for (let i = 0; i < screens.length; i++) {
                const n = screens[i]?.name ?? "";
                if (n.length > 0)
                    names.push(n);
            }
            return names;
        }

        function allMonitorsExcluded(): bool {
            const excluded = Config.lock.excludedScreens ?? [];
            const names = screenNames();

            if (names.length === 0)
                return false;

            for (let i = 0; i < names.length; i++) {
                if (!excluded.includes(names[i]))
                    return false;
            }
            return true;
        }

        function safeLock(): void {
            if (allMonitorsExcluded()) {
                Toaster.toast(
                    qsTr("Lockscreen is disabled on all monitors; refusing to lock to prevent lockout."),
                    "settingsalert",
                    Toast.Error
                );
                return;
            }

            lock.locked = true;
        }

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam
        lock: lock
    }

    CustomShortcut {
        name: "lock"
        description: "Lock the current session"
        onPressed: lock.safeLock()
    }

    CustomShortcut {
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lock.safeLock();
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }
    }
}
