pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Fuzzy searcher over the settings index. The index is generated at build time
// from the page QML files by scripts/build-settings-index.py and shipped as
// assets/settings-index.json, so it stays in sync with the UI without any
// hand-maintained entries. Loaded here into Variants instances (QObjects) so
// the Searcher util (same engine as the launcher) can query them. Breadcrumb
// words are folded into keywords by the build script, so matching on title and
// keywords also matches page/section names.
Searcher {
    id: root

    list: entries.instances
    useFuzzy: true
    keys: ["title", "keywords"]
    weights: [0.7, 0.3]
    extraOpts: ({
            all: false,
            limit: 12
        })

    Variants {
        id: entries

        SettingEntry {}
    }

    FileView {
        path: Quickshell.shellPath("assets/settings-index.json")
        onLoaded: {
            try {
                entries.model = JSON.parse(text()).entries;
            } catch (e) {
                entries.model = [];
            }
        }
    }

    component SettingEntry: QtObject {
        required property var modelData

        readonly property int pageIdx: modelData.pageIdx
        readonly property var subPath: modelData.subPath
        readonly property var crumbIcons: modelData.crumbIcons
        readonly property var crumbLabels: modelData.crumbLabels
        readonly property string title: modelData.title
        readonly property string keywords: modelData.keywords ?? ""
        readonly property string anchor: modelData.anchor ?? ""
    }
}
