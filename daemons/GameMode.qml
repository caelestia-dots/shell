import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.services

Scope {
    id: root

    FileView {
        id: shellJson
        path: Quickshell.env("HOME") + "/.config/caelestia/shell.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    function applyGameMode(): void {
        const defaults = {
            "animations:enabled": 0,
            "decoration:shadow:enabled": 0,
            "decoration:blur:enabled": 0,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": 1
        };

        let config = {};
        try {
            const json = JSON.parse(shellJson.text());
            config = json?.utilities?.gameMode?.options ?? {};
        } catch (e) {}

        const filtered = {};
        for (const key in defaults) {
            if (key in config) {
                if (config[key] === null)
                    continue;
                if (typeof config[key] === "boolean")
                    filtered[key] = config[key] ? 1 : 0;
                else
                    filtered[key] = config[key];
            } else {
                filtered[key] = defaults[key];
            }
        }

        Hypr.extras.applyOptions(filtered);
    }

    function syncState(enableDisable: bool): void {
        if (RuntimeState.gameMode) {
            root.applyGameMode();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode enabled"), Tr.tr("Disabled Hyprland animations, blur, gaps and shadows"), "gamepad");
        } else if (enableDisable) {
            Hypr.extras.message("reload");
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Game mode disabled"), Tr.tr("Hyprland settings restored"), "gamepad");
        }
    }

    Component.onCompleted: syncState(false)

    Connections {
        function onGameModeChanged(): void {
            root.syncState(true);
        }

        target: RuntimeState
    }

    Connections {
        function onConfigReloaded(): void {
            if (RuntimeState.gameMode)
                root.applyGameMode();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return RuntimeState.gameMode;
        }

        function toggle(): void {
            RuntimeState.gameMode = !RuntimeState.gameMode;
        }

        function enable(): void {
            RuntimeState.gameMode = true;
        }

        function disable(): void {
            RuntimeState.gameMode = false;
        }

        target: "gameMode"
    }
}
