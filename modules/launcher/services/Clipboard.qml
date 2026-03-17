pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool pendingOpen: false
    property list<var> entries: []

    function reload(): void {
        listProc.running = true
    }

    function query(search: string): list<var> {
        const term = search.slice(`${Config.launcher.actionPrefix}clipboard `.length).toLowerCase().trim()
        if (!term)
            return [...entries]
        return entries.filter(e => e.preview.toLowerCase().includes(term))
    }

    Process {
        id: listProc

        running: true
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                root.entries = lines.filter(l => l.includes("\t")).map(line => {
                    const tabIdx = line.indexOf("\t")
                    const id = line.slice(0, tabIdx)
                    const preview = line.slice(tabIdx + 1)
                    const isImage = preview.startsWith("[[ binary data")
                    return { id, preview, isImage }
                })
            }
        }
    }
}
