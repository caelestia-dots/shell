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

    function applyGameMode(): void {
        // Compact layout only: maximise screen use. Keep animations, blur, shadows, wobble.
        Hypr.extras.applyOptions({
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 0,
            "decoration:rounding": 0
        });
    }

    function syncState(enableDisable: bool): void {
        if (RuntimeState.gameMode) {
            root.applyGameMode();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Compact layout enabled"), Tr.tr("Left bar only; no frame, gaps or window rounding"), "fit_screen");
        } else if (enableDisable) {
            Hypr.extras.message("reload");
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(Tr.tr("Compact layout disabled"), Tr.tr("Hyprland settings restored"), "fit_screen");
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
