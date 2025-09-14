pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    onEnabledChanged: {
        if (enabled)
            props.enabledSince = new Date();
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    // A non-visible PanelWindow required by IdleInhibitor
    PanelWindow {
        id: win

        anchors.left: true
        width: 0
        height: 0

        aboveWindows: false
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
    }

    IdleInhibitor {
        enabled: root.enabled
        window: win
    }

    IpcHandler {
        target: "idleInhibitor"

        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.enabled = !root.enabled;
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }
    }
}
