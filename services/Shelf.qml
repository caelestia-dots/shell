pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n

Singleton {
    id: root

    property var items: []
    property bool dragging
    property var pendingMime: []
    readonly property bool converting: convertProc.running

    function nextId(): string {
        return `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
    }

    function pathOf(uri: string): string {
        return decodeURIComponent(uri.replace(/^file:\/\//, ""));
    }

    function nameOf(item: var): string {
        if (item.type === "text")
            return item.text;
        const path = pathOf(item.uri).replace(/\/$/, "");
        return path.slice(path.lastIndexOf("/") + 1) || path;
    }

    function addUrls(urls: var): void {
        const existing = new Set(items.filter(i => i.type === "file").map(i => i.uri));
        const added = [];
        for (const u of urls) {
            const uri = u.toString();
            if (!uri.startsWith("file://") || existing.has(uri))
                continue;
            existing.add(uri);
            added.push({
                id: nextId(),
                type: "file",
                uri,
                mime: "",
                added: Date.now()
            });
        }
        if (!added.length)
            return;
        items = items.concat(added);
        pendingMime = pendingMime.concat(added.map(i => i.id));
        detectMime();
        save();
    }

    function addText(text: string): void {
        const trimmed = text.trim();
        if (!trimmed)
            return;
        if (/^file:\/\//.test(trimmed)) {
            addUrls(trimmed.split(/\r?\n/).filter(l => l));
            return;
        }
        items = items.concat([
            {
                id: nextId(),
                type: "text",
                text: trimmed,
                added: Date.now()
            }
        ]);
        save();
    }

    function remove(ids: var): void {
        const set = new Set(ids);
        items = items.filter(i => !set.has(i.id));
        save();
    }

    function clear(): void {
        items = [];
        save();
    }

    function find(id: string): var {
        return items.find(i => i.id === id) ?? null;
    }

    function copyText(text: string): void {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function sizeStr(item: var): string {
        if (item.type === "text")
            return Tr.tr("%1 chars").arg(item.text.length);
        const bytes = item.size ?? 0;
        if (!bytes)
            return "";
        const units = ["B", "KB", "MB", "GB"];
        let v = bytes;
        let u = 0;
        while (v >= 1024 && u < units.length - 1) {
            v /= 1024;
            u++;
        }
        return `${u ? v.toFixed(1) : v} ${units[u]}`;
    }

    function open(item: var): void {
        if (item.type === "file")
            Quickshell.execDetached(["xdg-open", item.uri]);
    }

    function canConvert(item: var): bool {
        return item.type === "file" && /\.(docx?|pptx?|pdf)$/i.test(pathOf(item.uri));
    }

    // Converted with mdmaker next to the original; the .md files are added to the shelf
    function toMarkdown(targets: var): void {
        const paths = targets.filter(i => canConvert(i)).map(i => pathOf(i.uri));
        if (!paths.length || convertProc.running)
            return;
        convertProc.total = paths.length;
        convertProc.command = ["sh", "-c", 'for f; do m="${f%.*}.md"; mdmaker -- "$f" >/dev/null 2>&1 && [ -f "$m" ] && printf "%s\\n" "$m"; done', "sh"].concat(paths);
        convertProc.running = true;
    }

    function detectMime(): void {
        if (mimeProc.running || !pendingMime.length)
            return;
        const targets = pendingMime.map(id => find(id)).filter(i => i);
        pendingMime = [];
        if (!targets.length)
            return;
        mimeProc.targets = targets.map(i => i.id);
        mimeProc.command = ["sh", "-c", 'for f; do printf "%s\\t%s\\n" "$(file -b --mime-type -- "$f")" "$(du -sb -- "$f" 2>/dev/null | cut -f1)"; done', "sh"].concat(targets.map(i => pathOf(i.uri)));
        mimeProc.running = true;
    }

    function save(): void {
        saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: file.setText(JSON.stringify(root.items, null, 2))
    }

    Process {
        id: mimeProc

        property var targets: []

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").map(l => l.split("\t"));
                const byId = {};
                mimeProc.targets.forEach((id, i) => byId[id] = lines[i] ?? ["", ""]);
                root.items = root.items.map(i => byId[i.id] !== undefined ? Object.assign({}, i, {
                        mime: byId[i.id][0] ?? "",
                        size: parseInt(byId[i.id][1]) || 0
                    }) : i);
                root.save();
            }
        }

        onExited: root.detectMime()
    }

    Process {
        id: convertProc

        property int total

        stdout: StdioCollector {
            onStreamFinished: {
                const done = text.split("\n").filter(l => l);
                root.addUrls(done.map(p => "file://" + p.split("/").map(encodeURIComponent).join("/")));
                if (done.length === convertProc.total)
                    Toaster.toast(Tr.tr("Converted to Markdown"), done.length === 1 ? done[0].slice(done[0].lastIndexOf("/") + 1) : Tr.tr("%1 files").arg(done.length), "markdown");
                else
                    Toaster.toast(Tr.tr("Markdown conversion failed"), Tr.tr("%1 of %2 files converted").arg(done.length).arg(convertProc.total), "error");
            }
        }
    }

    // PaleSense (phone remote): qs -c paleshell ipc call shelf addFile /abs/path
    IpcHandler {
        function addFile(path: string): void {
            root.addUrls(["file://" + path.split("/").map(encodeURIComponent).join("/")]);
            Toaster.toast(Tr.tr("Received from phone"), path.slice(path.lastIndexOf("/") + 1), "smartphone");
        }

        target: "shelf"
    }

    // Files sent from the phone with KDE Connect land on the shelf too
    Process {
        running: true
        command: ["sh", "-c", "command -v kdeconnectd >/dev/null && exec dbus-monitor --session \"type='signal',interface='org.kde.kdeconnect.device.share',member='shareReceived'\""]
        stdout: SplitParser {
            onRead: line => {
                const m = /string "(file:\/\/[^"]+)"/.exec(line);
                if (m)
                    root.addUrls([m[1]]);
            }
        }
    }

    FileView {
        id: file

        path: `${NotchSettings.dir}/shelf.json`
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.items = Array.isArray(data) ? data : [];
            } catch (e) {
                root.items = [];
            }
            root.pendingMime = root.items.filter(i => i.type === "file" && (!i.mime || i.size === undefined)).map(i => i.id);
            root.detectMime();
        }
    }
}
