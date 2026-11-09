import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.State

Scope {
    id: root

    Connections {
        function onInhibitIdleChanged(): void {
            if (RuntimeState.inhibitIdle)
                RuntimeState.inhibitingIdleSince = new Date().getTime();
        }

        target: RuntimeState
    }

    IdleInhibitor {
        enabled: RuntimeState.inhibitIdle
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return RuntimeState.inhibitIdle;
        }

        function toggle(): void {
            RuntimeState.inhibitIdle = !RuntimeState.inhibitIdle;
        }

        function enable(): void {
            RuntimeState.inhibitIdle = true;
        }

        function disable(): void {
            RuntimeState.inhibitIdle = false;
        }

        target: "idleInhibitor"
    }
}
