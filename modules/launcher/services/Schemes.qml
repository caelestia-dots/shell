pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentScheme: `${Hallownest.styleData.name} ${Hallownest.flavour}`

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}theme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["flavour", "name"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        // "style flavour" for every combination
        model: Hallownest.styleNames.reduce((all, s) => all.concat(Hallownest.flavours.map(f => `${s} ${f}`)), [])

        Scheme {}
    }

    component Scheme: QtObject {
        required property string modelData
        readonly property string style: modelData.split(" ")[0]
        readonly property string name: Hallownest.styles[style].name
        readonly property string flavour: modelData.split(" ")[1]
        readonly property var colours: ({
                surface: Hallownest.styles[style].base.void.slice(1),
                outline: Hallownest.styles[style].flavours[flavour].steel.slice(1),
                primary: Hallownest.styles[style].flavours[flavour].accent.slice(1)
            })

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Hallownest.setTheme(style, flavour);
        }
    }
}
