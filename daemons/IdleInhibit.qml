import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.State

Scope {
    id: root

    Connections {
        function onKeepAwakeEnabledChanged(): void {
            if (PersistentState.keepAwakeEnabled) {
                if (PersistentState.keepAwakeEnabledAt <= 0)
                    PersistentState.keepAwakeEnabledAt = new Date().getTime();
            } else {
                PersistentState.keepAwakeEnabledAt = -1;
            }
        }

        target: PersistentState
    }

    IdleInhibitor {
        enabled: PersistentState.keepAwakeEnabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return PersistentState.keepAwakeEnabled;
        }

        function toggle(): void {
            if (PersistentState.keepAwakeEnabled)
                disable();
            else
                enable();
        }

        function enable(): void {
            PersistentState.keepAwakeEnabled = true;
            PersistentState.keepAwakeEnabledAt = new Date().getTime();
        }

        function disable(): void {
            PersistentState.keepAwakeEnabled = false;
            PersistentState.keepAwakeEnabledAt = -1;
        }

        target: "idleInhibitor"
    }
}
