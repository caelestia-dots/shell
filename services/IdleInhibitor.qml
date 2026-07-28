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

    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            // 0x0 surfaces do not map on Hyprland, so idle inhibitors are ignored.
            // Use a 1x1 corner surface instead (see #635).
            screen: Quickshell.screens[0]
            visible: props.enabled
            anchors.top: true
            anchors.left: true
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            mask: Region {}
            WlrLayershell.namespace: "caelestia-idle-inhibitor"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
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

        target: "idleInhibitor"
    }
}
