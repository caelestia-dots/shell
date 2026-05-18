pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var items: []

    function reload(): void {
        fetcher.running = true;
    }

    property Process fetcher: Process {
        running: false
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                const lines = text.trim().split("\n");

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (!line) continue;

                    const match = line.match(/^(\d+)\t(.+)/);
                    if (!match) continue;

                    result.push({
                        id: parseInt(match[1]),
                        preview: match[2]
                    });
                }

                root.items = result;
            }
        }
    }
}
