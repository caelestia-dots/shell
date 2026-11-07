pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Scheme
import qs.utils
import qs.modules.launcher

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    list: vars.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Variants {
        id: vars

        model: {
            const list = [];
            for (const s of Colours.schemes)
                for (const f of s.flavours)
                    list.push({
                        name: s.name,
                        flavour: f.flavour,
                        modes: f.modes
                    });
            return list;
        }

        Scheme {}
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property list<int> modes: modelData.modes

        function onClicked(list: AppList): void {
            Colours.setScheme(modelData.name, modelData.flavour);
            list.screenState.launcher = false;
        }
    }
}
