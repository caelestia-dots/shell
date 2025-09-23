pragma Singleton

import qs.utils
import Caelestia
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias appearance: adapter.appearance
    property alias general: adapter.general
    property alias background: adapter.background
    property alias bar: adapter.bar
    property alias border: adapter.border
    property alias dashboard: adapter.dashboard
    property alias controlCenter: adapter.controlCenter
    property alias launcher: adapter.launcher
    property alias notifs: adapter.notifs
    property alias osd: adapter.osd
    property alias session: adapter.session
    property alias winfo: adapter.winfo
    property alias lock: adapter.lock
    property alias utilities: adapter.utilities
    property alias sidebar: adapter.sidebar
    property alias services: adapter.services
    property alias paths: adapter.paths

    ElapsedTimer {
        id: timer
    }

    FileView {
        path: `${Paths.config}/shell.json`
        watchChanges: true
        onFileChanged: {
            timer.restart();
            reload();
        }
        onLoaded: {
            try {
                JSON.parse(text());
                if (adapter.utilities.toasts.configLoaded)
                    Toaster.toast(qsTr("Config loaded"), qsTr("Config loaded in %1ms").arg(timer.elapsedMs()), "rule_settings");
            } catch (e) {
                Toaster.toast(qsTr("Failed to load config"), e.message, "settings_alert", Toast.Error);
            }
        }
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                Toaster.toast(qsTr("Failed to read config file"), FileViewError.toString(err), "settings_alert", Toast.Warning);
        }
        onSaveFailed: err => Toaster.toast(qsTr("Failed to save config"), FileViewError.toString(err), "settings_alert", Toast.Error)

        JsonAdapter {
            id: adapter

            property AppearanceConfig appearance: AppearanceConfig {}
            property GeneralConfig general: GeneralConfig {}
            property BackgroundConfig background: BackgroundConfig {}
            property BarConfig bar: BarConfig {}
            property BorderConfig border: BorderConfig {}
            property DashboardConfig dashboard: DashboardConfig {}
            property ControlCenterConfig controlCenter: ControlCenterConfig {}
            property LauncherConfig launcher: LauncherConfig {}
            property NotifsConfig notifs: NotifsConfig {}
            property OsdConfig osd: OsdConfig {}
            property SessionConfig session: SessionConfig {}
            property WInfoConfig winfo: WInfoConfig {}
            property LockConfig lock: LockConfig {}
            property UtilitiesConfig utilities: UtilitiesConfig {}
            property SidebarConfig sidebar: SidebarConfig {}
            property ServiceConfig services: ServiceConfig {}
            property UserPaths paths: UserPaths {}
        }
    }
}
