pragma Singleton

import QtQuick
import Caelestia.Config
import Caelestia.Scheme
import qs.utils

Searcher {
    id: searcher

    list: Wallpapers.model.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })
}
