pragma Singleton

import "root:/utils/scripts/fuzzysort.js" as Fuzzy
import "root:/config"
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<var> preppedSchemes: schemes.instances.map(s => ({
                name: Fuzzy.prepare(s.name),
                flavour: Fuzzy.prepare(s.flavour),
                scheme: s
            }))

    function fuzzyQuery(search: string): var {
        return Fuzzy.go(search.slice(`${Config.launcher.actionPrefix}scheme `.length), preppedSchemes, {
            all: true,
            keys: ["name", "flavour"],
            scoreFn: r => r[0].score > 0 ? r[0].score * 0.9 + r[1].score * 0.1 : 0
        }).map(r => r.obj.scheme);
    }

    Variants {
        id: schemes

        Scheme {}
    }

    Process {
        id: getSchemes

        running: true
        command: ["caelestia", "scheme", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const schemeData = JSON.parse(text);
                const list = Object.entries(schemeData).map(([name, f]) => Object.entries(f).map(([flavour, colours]) => ({
                                name,
                                flavour,
                                colours
                            })));

                const flat = [];
                for (const s of list)
                    for (const f of s)
                        flat.push(f);

                schemes.model = flat;
            }
        }
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property var colours: modelData.colours

        function onClicked(list: AppList): void {
            list.visibilities.launcher = false;
            Quickshell.execDetached(["caelestia", "scheme", "set", "-n", name, "-f", flavour]);
        }
    }
}
