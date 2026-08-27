pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled
    property alias temperature: props.temperature

    onEnabledChanged: {
        if (enabled) {
            applyTemperature();
        } else {
            stopNightLight();
        }
    }

    onTemperatureChanged: {
        if (enabled) {
            applyTemperature();
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: false
        property int temperature: 4000

        reloadableId: "nightLight"
    }

    function toggle(): void {
        enabled = !enabled;
    }

    function setTemp(t: int): void {
        temperature = Math.max(1000, Math.min(6500, t));
    }

    function applyTemperature(): void {
        procApply.running = false;
        const script = "if pgrep -x hyprsunset >/dev/null 2>&1; then " +
                       "hyprctl hyprsunset temperature " + temperature.toString() + "; " +
                       "else " +
                       "hyprsunset -t " + temperature.toString() + " >/dev/null 2>&1 & " +
                       "fi";
        procApply.command = ["sh", "-c", script];
        procApply.running = true;
    }

    function stopNightLight(): void {
        procStop.running = false;
        procStop.command = ["sh", "-c", "hyprctl hyprsunset identity 2>/dev/null; pkill -x hyprsunset 2>/dev/null"];
        procStop.running = true;
    }

    Process {
        id: procApply
        running: false
    }

    Process {
        id: procStop
        running: false
    }

    Component.onCompleted: {
        if (enabled) {
            applyTemperature();
        }
    }

    IpcHandler {
        target: "nightLight"

        function isEnabled(): bool {
            return props.enabled;
        }

        function getTemperature(): int {
            return props.temperature;
        }

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        function setTemperature(temp: int): void {
            root.setTemp(temp);
        }
    }
}
