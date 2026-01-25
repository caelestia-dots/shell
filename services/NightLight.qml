pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.config
import qs.components.misc

Singleton {
    id: root

    readonly property bool enabled: Config.utilities.nightLight.enabled
    readonly property int temperature: Config.utilities.nightLight.temperature

    property bool on: nightLightProcess.running

    Process {
        id: nightLightProcess
        command: ["hyprsunset", "--temperature", root.temperature.toString()]
        running: false 
    }

    function toggle() {
        if (nightLightProcess.running) {
            nightLightProcess.running = false;
            if (Config.utilities.toasts.nightLight)
                Toaster.toast(qsTr("Night Light"), qsTr("Disabled"), "dark_mode");
        } else {
            nightLightProcess.running = true;
            if (Config.utilities.toasts.nightLight)
                Toaster.toast(qsTr("Night Light"), qsTr("Enabled"), "dark_mode");
        }
    }

    // Kills instances of hyprsunset not managed by Quickshell
    Process {
        id: startupCleaner
        command: ["pkill", "hyprsunset"]
    }
    Component.onCompleted: {
        if (enabled) {
            startupCleaner.running = true;
        }
    }

    Component.onDestruction: {
        nightLightProcess.running = false;
    }

    CustomShortcut {
        name: "nightLightToggle"
        description: "Toggles Night Light"
        onPressed: root.toggle()
    }
}