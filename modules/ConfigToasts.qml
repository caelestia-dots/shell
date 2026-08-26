import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Services

Scope {
    Component.onCompleted: {
        // Flush signals on completion so toasts are shown
        GlobalConfig.flushLoadSignals();
        TokenConfig.flushLoadSignals();
    }

    Connections {
        function onLoaded(screen: string): void {
            if (!screen && GlobalConfig.utilities.toasts.configLoaded) {
                const issues = GlobalConfig.diagnostics.length;
                const msg = issues > 0 ? qsTr("Config loaded with %1 issue%2.").arg(issues).arg(issues > 1 ? "s" : "") : qsTr("Config loaded successfully!");
                Toaster.toast(qsTr("Config loaded"), msg, issues > 0 ? "settings_alert" : "rule_settings", issues > 0 ? Toast.Warning : Toast.Info);
            }
        }

        function onLoadFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Failed to parse config%1").arg(screen ? " for " + screen : ""), error, "settings_alert", Toast.Warning);
        }

        function onSaveFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Failed to save config%1").arg(screen ? " for " + screen : ""), error, "settings_alert", Toast.Error);
        }

        target: GlobalConfig
    }

    Connections {
        function onLoadFailed(error: string, screen: string): void {
            Toaster.toast(qsTr("Failed to parse token config%1").arg(screen ? " for " + screen : ""), error, "settings_alert", Toast.Warning);
        }

        target: TokenConfig
    }
}
