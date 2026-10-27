pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils

Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.utilities.clipboard.enabled
    readonly property int maxItems: Math.max(1, GlobalConfig.utilities.clipboard.maxItems)
    readonly property string favoritesDir: `${Paths.state}/clipboard/favorites`
    readonly property string favoritesPath: `${Paths.state}/clipboard/favorites.json`
    readonly property string thumbsDir: `${Paths.cache}/clipboard/thumbs`

    property bool open: false
    property bool loaded: false
    property real cursorX: 0
    property real cursorY: 0
    property string search: ""
    property int currentIndex: 0
    property var pendingPaste: null
    // Window that had focus before the Exclusive overlay stole it
    property string pasteTargetAddress: ""

    property list<var> history: []
    property list<var> favorites: []

    readonly property list<var> filteredFavorites: {
        const q = root.search.trim().toLowerCase();
        if (!q.length)
            return root.favorites;
        return root.favorites.filter(e => ((e.label || e.preview || "").toLowerCase().includes(q)));
    }

    readonly property list<var> filteredHistory: {
        const favText = new Set(root.favorites.filter(f => f.kind === "text").map(f => f.text || f.preview));
        const q = root.search.trim().toLowerCase();
        return root.history.filter(e => {
            if (e.kind === "text" && favText.has(e.preview))
                return false;
            if (!q.length)
                return true;
            return (e.label || e.preview || "").toLowerCase().includes(q);
        });
    }

    readonly property list<var> flatItems: [...root.filteredFavorites.map(e => Object.assign({}, e, {
                section: "favorite"
            })), ...root.filteredHistory.map(e => Object.assign({}, e, {
                section: "history"
            }))]

    function capturePasteTarget(): void {
        const t = Hypr.activeToplevel;
        const raw = String(t?.address ?? "");
        root.pasteTargetAddress = raw ? (raw.startsWith("0x") ? raw : `0x${raw}`) : "";
    }

    function restorePasteTarget(): void {
        const addr = root.pasteTargetAddress;
        if (!addr)
            return;
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:${addr}" })` : `focuswindow address:${addr}`);
    }

    function pasteKeyCommand(): string {
        // Prefer Hyprland's virtual shortcut (reliable after layer-shell Exclusive focus),
        // fall back to wtype for non-Hypr / older compositors.
        if (Hypr.usingLua)
            return `hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "v" })' 2>/dev/null || wtype -M ctrl -P v -m ctrl`;
        return `wtype -M ctrl -P v -m ctrl`;
    }

    function openAtCursor(): void {
        if (!root.enabled)
            return;
        root.capturePasteTarget();
        root.search = "";
        root.currentIndex = 0;
        root.reloadHistory();
        cursorProc.running = true;
    }

    function close(): void {
        root.open = false;
        root.search = "";
    }

    function toggle(): void {
        if (root.open)
            root.close();
        else
            root.openAtCursor();
    }

    function moveSelection(delta: int): void {
        const count = root.flatItems.length;
        if (count <= 0) {
            root.currentIndex = 0;
            return;
        }
        root.currentIndex = (root.currentIndex + delta + count) % count;
    }

    function activateCurrent(): void {
        const item = root.flatItems[root.currentIndex];
        if (item)
            root.select(item);
    }

    function select(item: var): void {
        if (!item)
            return;
        // Copy immediately while the overlay closes — don't serialize behind focus wait
        root.copyItem(item);
        root.pendingPaste = item;
        root.close();
        pasteTimer.restart();
    }

    function isFavorite(item: var): bool {
        if (!item)
            return false;
        if (item.uid)
            return root.favorites.some(f => f.uid === item.uid);
        if (item.kind === "text")
            return root.favorites.some(f => f.kind === "text" && (f.text === item.preview || f.preview === item.preview));
        return root.favorites.some(f => f.preview === item.preview && f.kind === item.kind);
    }

    function toggleFavorite(item: var): void {
        if (!item)
            return;
        if (item.section === "favorite" || item.uid || root.isFavorite(item)) {
            const uid = item.uid || root.favorites.find(f => f.kind === item.kind && (f.text === item.preview || f.preview === item.preview))?.uid;
            const removed = root.favorites.find(f => f.uid === uid);
            root.favorites = root.favorites.filter(f => f.uid !== uid);
            if (removed?.path)
                Quickshell.execDetached(["rm", "-f", removed.path]);
            root.persistFavorites();
            return;
        }
        // File-path images: copy the file into favourites (cliphist only has the path text)
        if (item.path && item.kind === "image") {
            const uid = `${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
            const ext = root.thumbExt(item.path);
            const finalPath = `${root.favoritesDir}/${uid}.${ext}`;
            Quickshell.execDetached(["bash", "-c", `mkdir -p \"$1\" && cp -f \"$2\" \"$3\"`, "_", root.favoritesDir, item.path, finalPath]);
            root.favorites = [{
                    uid,
                    preview: item.preview,
                    kind: "image",
                    label: root.displayPreview(item.preview, "image", item.path),
                    path: finalPath
                }, ...root.favorites];
            root.persistFavorites();
            return;
        }
        starProc.item = item;
        starProc.running = true;
    }

    function deleteEntry(item: var): void {
        if (!item)
            return;
        if (item.section === "favorite" || item.uid) {
            root.favorites = root.favorites.filter(f => f.uid !== item.uid);
            root.persistFavorites();
            if (item.path)
                Quickshell.execDetached(["rm", "-f", item.path]);
            return;
        }
        if (!item.id)
            return;
        const line = `${item.id}\t${item.preview}`;
        Quickshell.execDetached(["sh", "-c", `printf '%s\\n' ${JSON.stringify(line)} | cliphist delete`]);
        Qt.callLater(() => root.reloadHistory());
    }

    function clearHistory(): void {
        wipeProc.running = true;
    }

    function reloadHistory(): void {
        if (!listProc.running)
            listProc.running = true;
    }

    function syncCliphistMaxItems(): void {
        syncConfigProc.running = true;
    }

    function ensureWatchers(): void {
        if (!root.enabled)
            return;
        if (!textWatch.running)
            textWatch.running = true;
        if (!imageWatch.running)
            imageWatch.running = true;
    }

    function localImagePath(preview: string): string {
        const raw = (preview || "").trim();
        if (!raw.length)
            return "";

        // File managers often put text/uri-list (one URI per line) or a plain path
        const lines = raw.split(/\r?\n/).map(s => s.trim()).filter(s => s.length && !s.startsWith("#"));
        for (const line of lines) {
            let p = line;
            if (/^file:\/\//i.test(p)) {
                try {
                    p = decodeURIComponent(p.replace(/^file:\/\//i, ""));
                } catch (e) {
                    p = p.replace(/^file:\/\//i, "");
                }
            } else if ((p.startsWith("\"") && p.endsWith("\"")) || (p.startsWith("'") && p.endsWith("'"))) {
                p = p.slice(1, -1);
            }

            if (!p.startsWith("/"))
                continue;
            if (!/\.(png|jpe?g|webp|gif|bmp|svg)$/i.test(p))
                continue;
            return p;
        }
        return "";
    }

    function kindFromPreview(preview: string): string {
        if (root.localImagePath(preview))
            return "image";
        const p = preview || "";
        if (/\[\[\s*binary data/i.test(p)) {
            if (/\b(png|jpe?g|webp|gif|bmp|svg)\b/i.test(p))
                return "image";
            return "binary";
        }
        return "text";
    }

    function iconForKind(kind: string): string {
        if (kind === "image")
            return "image";
        if (kind === "binary")
            return "draft";
        return "content_paste";
    }

    function thumbExt(preview: string): string {
        const m = (preview || "").match(/\.(png|jpe?g|webp|gif|bmp|svg)\b/i) || (preview || "").match(/\b(png|jpe?g|webp|gif|bmp|svg)\b/i);
        if (!m)
            return "png";
        const t = m[1].toLowerCase();
        return (t === "jpeg" || t === "jpg") ? "jpg" : t;
    }

    function mimeForImagePath(path: string): string {
        const ext = root.thumbExt(path);
        if (ext === "jpg")
            return "image/jpeg";
        if (ext === "svg")
            return "image/svg+xml";
        return `image/${ext}`;
    }

    function thumbPathFor(item: var): string {
        if (!item || item.kind !== "image")
            return "";
        if (item.path)
            return item.path;
        if (!item.id)
            return "";
        return `${root.thumbsDir}/${item.id}.${root.thumbExt(item.preview)}`;
    }

    function displayPreview(preview: string, kind: string, path: string): string {
        if (kind === "image") {
            if (path && path.length) {
                const name = path.split("/").pop();
                return name || Tr.tr("Image");
            }
            const m = (preview || "").match(/\[\[\s*binary data\s+(.+?)\s*\]\]/i);
            return m ? Tr.tr("Image · %1").arg(m[1]) : Tr.tr("Image");
        }
        if (kind === "binary") {
            const m = (preview || "").match(/\[\[\s*binary data\s+(.+?)\s*\]\]/i);
            return m ? Tr.tr("Binary · %1").arg(m[1]) : Tr.tr("Binary data");
        }
        return (preview || "").replace(/\s+/g, " ").trim();
    }

    function parseHistory(text: string): list<var> {
        const lines = (text || "").split("\n").filter(l => l.length > 0);
        const out = [];
        for (const line of lines) {
            const tab = line.indexOf("\t");
            if (tab < 0)
                continue;
            const id = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            const path = root.localImagePath(preview);
            const kind = path ? "image" : root.kindFromPreview(preview);
            const entry = {
                id,
                preview,
                kind,
                label: root.displayPreview(preview, kind, path)
            };
            if (path)
                entry.path = path;
            out.push(entry);
        }
        return out;
    }

    function persistFavorites(): void {
        if (!root.loaded)
            return;
        favoritesFile.setText(JSON.stringify({
                favorites: root.favorites
            }, null, 2));
    }

    function copyItem(item: var): void {
        if (!item)
            return;
        if (item.uid && item.kind === "text" && item.text !== undefined) {
            Quickshell.execDetached(["sh", "-c", `printf '%s' ${JSON.stringify(item.text)} | wl-copy`]);
            return;
        }
        if (item.path && item.kind === "image") {
            const mime = root.mimeForImagePath(item.path);
            Quickshell.execDetached(["sh", "-c", `wl-copy --type ${JSON.stringify(mime)} < ${JSON.stringify(item.path)}`]);
            return;
        }
        if (item.id)
            Quickshell.execDetached(["sh", "-c", `cliphist decode ${JSON.stringify(String(item.id))} | wl-copy`]);
    }

    function pasteItem(item: var): void {
        if (!item)
            return;

        // Focus was captured at open; restore then fire Ctrl+V (copy already started in select)
        root.restorePasteTarget();
        Quickshell.execDetached(["sh", "-c", `sleep 0.05 && ${root.pasteKeyCommand()}`]);
    }

    onMaxItemsChanged: root.syncCliphistMaxItems()
    onEnabledChanged: {
        if (root.enabled)
            root.ensureWatchers();
        else
            root.close();
    }

    Component.onCompleted: {
        root.syncCliphistMaxItems();
        root.ensureWatchers();
        root.reloadHistory();
    }

    Timer {
        id: pasteTimer

        // Minimum for Exclusive layer teardown; copy already ran in parallel
        interval: 100
        repeat: false
        onTriggered: {
            root.pasteItem(root.pendingPaste);
            root.pendingPaste = null;
        }
    }

    Process {
        id: cursorProc

        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const pos = JSON.parse(text);
                    root.cursorX = pos.x;
                    root.cursorY = pos.y;
                } catch (e) {
                    root.cursorX = 0;
                    root.cursorY = 0;
                }
                root.open = true;
            }
        }
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.history = root.parseHistory(text);
                if (root.currentIndex >= root.flatItems.length)
                    root.currentIndex = Math.max(0, root.flatItems.length - 1);
            }
        }
    }

    Process {
        id: textWatch

        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    }

    Process {
        id: imageWatch

        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    }

    // cliphist store does not print; poll while open / periodically
    Timer {
        interval: 1500
        running: root.enabled
        repeat: true
        onTriggered: {
            if (root.open || root.history.length === 0)
                root.reloadHistory();
        }
    }

    Process {
        id: syncConfigProc

        command: ["sh", "-c", `mkdir -p \"$HOME/.config/cliphist\" \"$HOME/.cache/cliphist\" ${JSON.stringify(root.favoritesDir)} ${JSON.stringify(root.thumbsDir)} && printf 'max-items %d\\n' '${root.maxItems}' > \"$HOME/.config/cliphist/config\"`]
    }

    Process {
        id: wipeProc

        command: ["cliphist", "wipe"]
        onExited: root.reloadHistory()
    }

    Process {
        id: starProc

        property var item: null

        command: {
            const it = item;
            if (!it?.id)
                return ["true"];
            if (it.kind === "text")
                return ["cliphist", "decode", String(it.id)];
            const ext = it.kind === "image" ? "png" : "bin";
            return ["bash", "-c", `mkdir -p \"$1\" && out=\"$1/fav-tmp.$$$$.${ext}\" && cliphist decode \"$2\" > \"$out\" && printf '%s' \"$out\"`, "_", root.favoritesDir, String(it.id)];
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const it = starProc.item;
                if (!it)
                    return;
                const uid = `${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
                if (it.kind === "text") {
                    const body = text;
                    root.favorites = [{
                            uid,
                            preview: it.preview || body.slice(0, 120),
                            kind: "text",
                            label: root.displayPreview(it.preview || body, "text", ""),
                            text: body
                        }, ...root.favorites];
                } else {
                    const path = text.trim();
                    if (!path.length)
                        return;
                    const finalPath = `${root.favoritesDir}/${uid}.${it.kind === "image" ? "png" : "bin"}`;
                    Quickshell.execDetached(["mv", path, finalPath]);
                    root.favorites = [{
                            uid,
                            preview: it.preview,
                            kind: it.kind,
                            label: root.displayPreview(it.preview, it.kind, finalPath),
                            path: finalPath
                        }, ...root.favorites];
                }
                root.persistFavorites();
            }
        }
    }

    FileView {
        id: favoritesFile

        printErrors: false
        path: root.favoritesPath
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.favorites = Array.isArray(data?.favorites) ? data.favorites : [];
            } catch (e) {
                console.warn(`Unable to parse clipboard favorites: ${e}`);
                root.favorites = [];
            }
            root.loaded = true;
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => root.persistFavorites());
            else
                console.warn(`Unable to load clipboard favorites: ${err}`);
        }
    }
}
