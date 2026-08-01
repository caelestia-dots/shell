pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config

// hyprsunset >= 0.4.0: `identity get/true/false` for state and disable.
// Older versions only support plain `identity`; state detection is unavailable.
Singleton {
    id: root

    property bool enabled
    property var supportsIdentityGet: null
    property bool legacyApiWarned

    readonly property var config: {
        const item = GlobalConfig.utilities.quickToggles.find(t => typeof t === "object" && t.id === "nightLight");
        return typeof item === "object" ? item : {};
    }
    readonly property int temperature: config.temperature ?? 4000

    function disableCommand(): list<string> {
        return supportsIdentityGet === true ? ["hyprctl", "hyprsunset", "identity", "true"] : ["hyprctl", "hyprsunset", "identity"];
    }

    function setEnabled(value: bool): void {
        Quickshell.execDetached(value ? ["hyprctl", "hyprsunset", "temperature", String(temperature)] : disableCommand());

        const changed = enabled !== value;
        enabled = value;

        if (changed && (config.toast ?? true)) {
            if (value)
                Toaster.toast(qsTr("Night light enabled"), qsTr("Blue-light filter is now active"), "nightlight");
            else
                Toaster.toast(qsTr("Night light disabled"), qsTr("Blue-light filter is now inactive"), "nightlight");
        }
    }

    function toggle(): void {
        setEnabled(!enabled);
    }

    function warnLegacyApi(): void {
        if (legacyApiWarned || !(config.toast ?? true))
            return;

        legacyApiWarned = true;
        Toaster.toast(qsTr("Night light state unavailable"), qsTr("hyprsunset 0.4.0+ is required to detect the current state"), "warning", Toast.Warning);
    }

    function parseIdentityGet(output: string): void {
        const value = output.trim();
        if (value === "true" || value === "false") {
            supportsIdentityGet = true;
            enabled = value === "false";
            return;
        }

        supportsIdentityGet = false;
        warnLegacyApi();
    }

    function refresh(): void {
        queryProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: queryProc

        command: ["hyprctl", "hyprsunset", "identity", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.parseIdentityGet(text)
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.setEnabled(true);
        }

        function disable(): void {
            root.setEnabled(false);
        }

        function refresh(): void {
            root.refresh();
        }

        target: "nightLight"
    }
}
