pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.utils

// The flavours (accent colours) of the current style for ">color"
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
        return search.slice(`${GlobalConfig.launcher.actionPrefix}color `.length);
    }

    function selector(item: var): string {
        return item.title;
    }

    list: flavours.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["title"]
    weights: [1]

    Variants {
        id: flavours

        model: Hallownest.flavours

        Flavour {}
    }

    component Flavour: QtObject {
        required property string modelData
        readonly property string title: modelData
        readonly property string subtitle: Hallownest.styleData.name
        readonly property bool current: modelData === Hallownest.flavour
        readonly property var colours: root.coloursFor(Hallownest.style, modelData)

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Hallownest.setFlavour(modelData);
        }
    }
}
