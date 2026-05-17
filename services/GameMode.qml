pragma Singleton

import QtQuick
import QtQml
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services
import qs.utils

Singleton {
    id: root

    property bool enabled: false

    // forces full opacity
    // Windowrule for new windows + setprop for existing windows, batched to avoid races
    function forceOpacity(): void {
        const cmds = ["keyword windowrule opacity 1 override 1 override 1 override, match:title .*"];
        for (const toplevel of Hypr.toplevels.values)
            cmds.push(`dispatch setprop address:0x${toplevel.address} opaque 1`);
        Hypr.extras.batchMessage(cmds);
    }

    // unset the opacity override for all windows
    function revertOpacity(): void {
        const cmds = [];
        for (const toplevel of Hypr.toplevels.values)
            cmds.push(`dispatch setprop address:0x${toplevel.address} opaque 0`);
        cmds.push("reload");
        Hypr.extras.batchMessage(cmds);
    }

    function setDynamicConfs(): void {
        Hypr.extras.applyOptions({
            "animations:enabled": 0,
            "decoration:shadow:enabled": 0,
            "decoration:blur:enabled": 0,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": 1,
            "input:accel_profile": "flat"
        });
        forceOpacity();
    }

    // save state to a file instead
    function saveState(): void {
        const jsonContent = JSON.stringify({
            enabled: root.enabled
        });
        writeProcess.script = `mkdir -p ${Paths.state} && cat > ${Paths.state}/gamemode.json << 'EOF'\n${jsonContent}\nEOF`;
        writeProcess.running = true;
    }

    onEnabledChanged: {
        if (enabled) {
            setDynamicConfs();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode enabled"), qsTr("Disabled Hyprland animations, blur, gaps, shadows and mouse acceleration"), "gamepad");
        } else {
            revertOpacity();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode disabled"), qsTr("Hyprland settings restored"), "gamepad");
        }
        saveState();
    }

    Process {
        id: writeProcess

        property string script: ""

        command: ["bash", "-c", script]
        // qmllint disable signal-handler-parameters
        onExited: function (exitCode) {
            if (exitCode !== 0)
                console.warn("GameMode: Failed to save gamemode state, exit code:" + exitCode);
        }
        // qmllint enable signal-handler-parameters
    }

    FileView {
        path: `${Paths.state}/gamemode.json`
        printErrors: false
        onLoaded: {
            try {
                root.enabled = JSON.parse(text()).enabled;
            } catch (e) {
                console.warn("GameMode: Failed to load gamemode state:", e);
            }
        }
        Component.onCompleted: reload()
    }

    Connections {
        function onConfigReloaded(): void {
            if (root.enabled)
                root.setDynamicConfs();
        }

        target: Hypr
    }

    IpcHandler {
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

        target: "gameMode"
    }
}
