pragma Singleton

import Quickshell
import Caelestia
import qs.config
import qs.utils

Searcher {
    property alias appDb: allAppsDb

    list: allAppsDb.apps
    useFuzzy: true
    key: "name"

    AppDb {
        id: allAppsDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: Config.launcher.favouriteApps
        entries: DesktopEntries.applications.values
    }
}
