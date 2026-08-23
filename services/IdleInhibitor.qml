pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince
    readonly property alias until: props.until

    function enableFor(minutes: real): void {
        props.until = new Date(Date.now() + minutes * 60000);
        props.enabled = true;
    }

    onEnabledChanged: {
        if (enabled) {
            props.enabledSince = new Date();
        } else {
            props.until = new Date(0);
        }
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince
        property date until

        reloadableId: "idleInhibitor"
    }

    // Auto-disables when a duration set via enableFor() runs out. Recomputed
    // whenever `enabled`/`until` change, so this also correctly resumes a
    // countdown that was still in progress across a shell reload/restart.
    Timer {
        running: props.enabled && props.until.getTime() > Date.now()
        interval: Math.max(0, props.until.getTime() - Date.now())
        onTriggered: props.enabled = false
    }

    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        function enableFor(minutes: real): void {
            root.enableFor(minutes);
        }

        function until(): string {
            return props.until.toISOString();
        }

        target: "idleInhibitor"
    }
}
