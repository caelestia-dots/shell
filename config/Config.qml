pragma Singleton

import "root:/utils"
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias bar: adapter.bar
    property alias border: adapter.border
    property alias dashboard: adapter.dashboard
    property alias launcher: adapter.launcher
    property alias notifs: adapter.notifs
    property alias osd: adapter.osd
    property alias session: adapter.session
    property alias winfo: adapter.winfo
    property alias lock: adapter.lock
    property alias paths: adapter.paths
    property alias background: adapter.background

    FileView {
        path: `${Paths.stringify(Paths.config)}/shell.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property JsonObject bar: BarConfig {}
            property JsonObject border: BorderConfig {}
            property JsonObject dashboard: DashboardConfig {}
            property JsonObject launcher: LauncherConfig {}
            property JsonObject notifs: NotifsConfig {}
            property JsonObject osd: OsdConfig {}
            property JsonObject session: SessionConfig {}
            property JsonObject winfo: WInfoConfig {}
            property JsonObject lock: LockConfig {}
            property JsonObject paths: UserPaths {}
            property JsonObject background: JsonObject { property bool enabled: true }
        }
    }
}
