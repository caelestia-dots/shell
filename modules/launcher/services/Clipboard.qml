pragma Singleton

import QtQuick
import Quickshell.Io
import Caelestia.Config

QtObject {
    id: root

    property var items: []

    function reload(): void {
        fetcher.running = true;
    }

    function getSortedItems(): var {
        if (!items.length) return [];
        const favClips = GlobalConfig.launcher.favouriteClips || [];
        return [...items].sort((a, b) => {
            const aIsFav = favClips.includes(String(a.id));
            const bIsFav = favClips.includes(String(b.id));
            if (aIsFav !== bIsFav) return aIsFav ? -1 : 1;
            return 0;
        });
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
