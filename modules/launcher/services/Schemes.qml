pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils

Searcher {
    id: root

    property string currentScheme
    property string currentVariant

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    function reload(): void {
        getCurrent.running = true;
    }

    function reloadList(): void {
        // Re-fetch so previews match the active light/dark mode
        if (getSchemes.running)
            getSchemes.running = false;
        getSchemes.running = true;
    }

    readonly property string quietCli: Quickshell.shellPath("scripts/caelestia-quiet.py")

    function setScheme(name: string, flavour: string): void {
        // Optimistic UI update; Colours.FileView confirms when scheme.json lands
        root.currentScheme = `${name} ${flavour}`;
        runSet(["python3", root.quietCli, "scheme", "set", "-n", name, "-f", flavour]);
    }

    function setVariant(variant: string): void {
        root.currentVariant = variant;
        // Only regenerates colours when the active scheme is "dynamic".
        // On static schemes this just stores the preference for later.
        runSet(["python3", root.quietCli, "scheme", "set", "-v", variant]);
    }

    function runSet(command: list<string>): void {
        setSchemeProc.command = command;
        if (setSchemeProc.running)
            setSchemeProc.running = false;
        setSchemeProc.running = true;
    }

    function syncFromColours(): void {
        if (Colours.scheme)
            root.currentScheme = `${Colours.scheme} ${Colours.flavour}`;
        if (Colours.variant)
            root.currentVariant = Colours.variant;
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    // Keep selection in sync with the live scheme.json via Colours
    Connections {
        target: Colours

        function onSchemeChanged(): void {
            root.syncFromColours();
        }

        function onFlavourChanged(): void {
            root.syncFromColours();
        }

        function onVariantChanged(): void {
            root.syncFromColours();
        }

        // `caelestia scheme list` returns colours for the current mode
        function onLightChanged(): void {
            root.reloadList();
        }
    }

    Component.onCompleted: root.syncFromColours()

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
                const raw = text.trim();
                if (!raw)
                    return;

                let schemeData;
                try {
                    schemeData = JSON.parse(raw);
                } catch (e) {
                    console.warn("Schemes: failed to parse scheme list:", e);
                    return;
                }

                const list = Object.entries(schemeData).map(([name, f]) => Object.entries(f).map(([flavour, colours]) => ({
                                name,
                                flavour,
                                colours
                            })));

                const flat = [];
                for (const s of list)
                    for (const f of s)
                        flat.push(f);

                schemes.model = flat.sort((a, b) => String(a.name + a.flavour).localeCompare((b.name + b.flavour)));
            }
        }
    }

    Process {
        id: getCurrent

        running: true
        command: ["caelestia", "scheme", "get", "-nfv"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Ignore noise from apply_colours (e.g. chrome policy warnings on stdout)
                const lines = text.trim().split("\n").map(l => l.trim()).filter(l => l && !l.startsWith("Unable to "));
                if (lines.length < 3)
                    return;
                const name = lines[lines.length - 3];
                const flavour = lines[lines.length - 2];
                const variant = lines[lines.length - 1];
                root.currentScheme = `${name} ${flavour}`;
                root.currentVariant = variant;
            }
        }
    }

    Process {
        id: setSchemeProc

        // apply_colours may print chrome policy warnings on stdout; ignore content
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property var colours: modelData.colours

        function apply(): void {
            root.setScheme(name, flavour);
        }

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            apply();
        }
    }
}
