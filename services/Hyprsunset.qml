pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias enabled: props.enabled
    property alias temperature: props.temperature

    PersistentProperties {
        id: props

        property bool enabled
        property int temperature: 2500

        reloadableId: "hyprsunset"
    }

    Process {
        id: hyprsunsetProcess
        running: false
        command: root.enabled ?
            ["hyprctl", "hyprsunset", "identity"] :
            ["hyprctl", "hyprsunset", "temperature", root.temperature.toString()]

        function execute() {
            running = true;
        }
    }

    onEnabledChanged: hyprsunsetProcess.execute()
    onTemperatureChanged: if (root.enabled) hyprsunsetProcess.execute()

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
