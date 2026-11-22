pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.utils

// The styles for ">theme", each previewed with the current flavour
Searcher {
    id: root

    function coloursFor(style: string, flavour: string): var {
        const s = Hallownest.styles[style];
        return {
            surface: s.base.void.slice(1),
            outline: s.flavours[flavour].steel.slice(1),
            primary: s.flavours[flavour].accent.slice(1)
        };
    }

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}theme `.length);
    }

    function selector(item: var): string {
        return item.title;
    }

    list: styles.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["title", "style"]
    weights: [0.9, 0.1]

    Variants {
        id: styles

        model: Hallownest.styleNames

        Scheme {}
    }

    component Scheme: QtObject {
        required property string modelData
        readonly property string style: modelData
        readonly property string title: Hallownest.styles[style].name
        readonly property string subtitle: Hallownest.flavour
        readonly property bool current: style === Hallownest.style
        readonly property var colours: root.coloursFor(style, Hallownest.flavour)

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Hallownest.setStyle(style);
        }
    }
}
