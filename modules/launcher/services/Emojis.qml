pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

QtObject {
    id: root

    property var items: []
    property var frequencies: ({})
    property bool _loaded: false

    function reload(): void {
        if (_loaded) return;
        reader.running = true;
        loadFrequencies();
    }

    function loadFrequencies(): void {
        freqReader.running = true;
    }

    function saveFrequencies(): void {
        freqWriter.arguments = ["-echo", JSON.stringify(frequencies), ">", Paths.config + "emoji-frequencies.json"];
        freqWriter.running = true;
    }

    function recordUsage(char: string): void {
        frequencies[char] = (frequencies[char] || 0) + 1;
        saveFrequencies();
    }

    function getSortedItems(): var {
        if (!items.length) return [];
        const favEmojis = GlobalConfig.launcher.favouriteEmojis || [];
        const favSet = new Set(favEmojis);
        return [...items].sort((a, b) => {
            const aIsFav = favSet.has(a.char);
            const bIsFav = favSet.has(b.char);
            if (aIsFav !== bIsFav) return aIsFav ? -1 : 1;
            const freqA = frequencies[a.char] || 0;
            const freqB = frequencies[b.char] || 0;
            if (freqA !== freqB) return freqB - freqA;
            return 0;
        });
    }

    property Process reader: Process {
        running: false
        command: ["cat", "/usr/lib/python3.14/site-packages/caelestia/data/emojis.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                const lines = text.trim().split("\n");

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (!line) continue;

                    const spaceIdx = line.indexOf(" ");
                    if (spaceIdx < 0) continue;

                    result.push({
                        char: line.substring(0, spaceIdx),
                        name: line.substring(spaceIdx + 1).trim()
                    });
                }

                root.items = result;
                root._loaded = true;
            }
        }
    }

    property Process freqReader: Process {
        running: false
        command: ["test", "-f", Paths.config + "emoji-frequencies.json", "&&", "cat", Paths.config + "emoji-frequencies.json", "||", "echo", "{}"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.frequencies = JSON.parse(text) || {};
                } catch (e) {
                    root.frequencies = {};
                }
            }
        }
    }

    property Process freqWriter: Process {
        running: false
    }
}
