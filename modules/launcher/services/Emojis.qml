pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var items: []
    property bool _loaded: false

    function reload(): void {
        if (_loaded) return;
        reader.running = true;
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
}
