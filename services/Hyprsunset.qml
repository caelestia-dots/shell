pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias enabled: props.enabled

    PersistentProperties {
        id: props

        property bool enabled

        reloadableId: "hyprsunset"
    }

    Process {
        id: hyprsunsetProcess
        running: false

        function updateCommand() {
            if (root.enabled) {
                command = ["hyprctl", "hyprsunset", "temperature", "2500"];
            } else {
                command = ["hyprctl", "hyprsunset", "identity"];
            }
            running = true;
        }
    }

    onEnabledChanged: {
        hyprsunsetProcess.updateCommand();
    }

    IpcHandler {
        target: "hyprsunset"

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
