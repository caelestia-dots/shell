pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string script: Quickshell.shellPath("assets/cliphist-action.sh")
    readonly property string imageDir: `${Paths.cache}/clipboard`
    readonly property string mainDb: GlobalConfig.launcher.clipboard.dbPath ? Paths.absolutePath(GlobalConfig.launcher.clipboard.dbPath) : "-"
    readonly property string pinsDb: Paths.absolutePath(GlobalConfig.launcher.clipboard.pinsDbPath)

    property var historyEntries: []
    property var pinnedEntries: []
    property var queue: []
    property var activeClipboard: ({
                                       kind: "",
                                       text: ""
                                   })
    property bool confirmingClear

    // Previews have their whitespace collapsed, so different texts can share one. These narrow
    // the entries that look like the clipboard down to the ones that hold exactly its content.
    property bool matching
    property var exactKeys: null // Null if no exact check was needed
    property var matchedKeys: []
    property int pendingMatches
    readonly property string activeText: activeClipboard.text.trim().split(/\s+/).join(" ")

    // Pinned entries first, then history without anything that is already pinned
    readonly property var entries: {
        const pinned = pinnedEntries;
        const seen = new Set(pinned.map(e => e.preview));
        const history = historyEntries.filter(e => !seen.has(e.preview));
        return [...pinned, ...history.slice(0, GlobalConfig.launcher.clipboard.maxEntries)].map((e, i) => Object.assign({}, e, {
                                                                                                                            order: i
                                                                                                                        }));
    }

    function parse(output: string, pinned: bool): var {
        const out = [];
        for (const line of output.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab < 1)
                continue;

            const clipId = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            const image = preview.match(/^\[\[ binary data (\S+ \S+) (\S+) (\d+x\d+) \]\]$/);

            if (image) {
                out.push({
                             clipId,
                             pinned,
                             preview,
                             image: true,
                             info: `${image[1]} ${image[2]} ${image[3]}`
                         });
            } else {
                // cliphist ends truncated previews with an ellipsis
                const truncated = preview.endsWith("…");
                const count = truncated ? preview.length - 1 : preview.length;
                out.push({
                             clipId,
                             pinned,
                             preview,
                             image: false,
                             info: truncated ? Tr.tr("%1+ chars").arg(count) : Tr.trN("%n char", "%n chars", count)
                         });
            }
        }
        return out;
    }

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}clip `.length);
    }

    function keyOf(entry: var): string {
        return `${entry.pinned ? "p" : "h"}:${entry.clipId}`;
    }

    // Plain copy of an entry, which stays valid when the entries reload
    function snapshot(entry: var): var {
        return {
            clipId: entry.clipId,
            pinned: entry.pinned,
            preview: entry.preview,
            image: entry.image,
            info: entry.info
        };
    }

    function warn(what: string, output: string): void {
        if (output.trim())
            console.warn(`[Clipboard] Error ${what}: ${output.trim()}`);
    }

    // Whether an entry's preview is what the clipboard text looks like, ignoring whitespace
    function looksActive(entry: var): bool {
        if (entry.image)
            return false;

        // Previews are cut off with an ellipsis if too long
        return entry.preview.endsWith("…") ? activeText.startsWith(entry.preview.slice(0, -1)) : activeText === entry.preview;
    }

    // Whether an entry is what the clipboard holds right now
    function isActive(entry: var): bool {
        const active = activeClipboard;
        if (active.kind === "image") {
            const newest = historyEntries[0];
            return entry.image && !!newest?.image && entry.preview === newest.preview;
        }

        if (active.kind !== "text" || !looksActive(entry) || matching)
            return false;

        // Several entries look alike, so only the ones with exactly the same content count
        return exactKeys === null || exactKeys.length === 0 || exactKeys.includes(keyOf(entry));
    }

    function matchActive(): void {
        exactKeys = null;
        matching = false;
        if (activeClipboard.kind !== "text")
            return;

        const history = historyEntries.filter(e => looksActive(e)).map(e => e.clipId);
        const pins = pinnedEntries.filter(e => looksActive(e)).map(e => e.clipId);
        // A single candidate can't be confused with another one
        if (history.length + pins.length <= 1)
            return;

        matchedKeys = [];
        pendingMatches = (history.length > 0 ? 1 : 0) + (pins.length > 0 ? 1 : 0);
        matching = true;
        if (history.length > 0)
            matchMainProc.exec(["sh", script, "active", mainDb, ...history]);
        if (pins.length > 0)
            matchPinsProc.exec(["sh", script, "active", pinsDb, ...pins]);
    }

    function onMatched(pinned: bool, output: string): void {
        const ids = output.split("\n").filter(id => id);
        matchedKeys = [...matchedKeys, ...ids.map(clipId => keyOf({
                                                                      pinned,
                                                                      clipId
                                                                  }))];
        if (--pendingMatches <= 0) {
            exactKeys = matchedKeys;
            matching = false;
        }
    }

    function refreshActive(): void {
        if (!currentProc.running)
            currentProc.running = true;
    }

    // Takes two calls within a few seconds, so history isn't wiped by accident
    function clear(): void {
        if (!confirmingClear) {
            confirmingClear = true;
            confirmTimer.restart();
            return;
        }

        confirmTimer.stop();
        confirmingClear = false;
        run(["wipe", mainDb]);
    }

    function reload(): void {
        confirmingClear = false;
        if (!mainProc.running)
            mainProc.running = true;
        if (!pinsProc.running)
            pinsProc.running = true;
    }

    function dbFor(entry: var): string {
        return entry.pinned ? pinsDb : mainDb;
    }

    function imagePath(entry: var): string {
        return `${imageDir}/${entry.pinned ? "pin" : "main"}-${entry.clipId}`;
    }

    function imageCommand(entry: var): var {
        return ["sh", script, "image", dbFor(entry), entry.clipId, imagePath(entry)];
    }

    function textCommand(entry: var): var {
        // Up to 4 bytes per char
        return ["sh", script, "text", dbFor(entry), entry.clipId, `${GlobalConfig.launcher.clipboard.previewMaxChars * 4}`];
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", script, "copy", dbFor(entry), entry.clipId]);
    }

    // Copies the entry, then once the launcher has closed and focus is back, sends the paste shortcut
    function paste(entry: var): void {
        copyProc.exec(["sh", script, "copy", dbFor(entry), entry.clipId]);
    }

    function sendPaste(): void {
        if (GlobalConfig.launcher.clipboard.pasteCommand.length > 0) {
            Quickshell.execDetached(GlobalConfig.launcher.clipboard.pasteCommand);
            return;
        }

        // Through Hyprland, as external tools create a virtual keyboard, which makes it toast a layout change
        const keys = GlobalConfig.launcher.clipboard.pasteShortcut;
        const mods = keys.slice(0, -1);
        const key = keys[keys.length - 1];
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.send_shortcut({ mods = "${mods.join("+")}", key = "${key}" })` : `sendshortcut ${mods.join(" ")}, ${key}, activewindow`);
    }

    function remove(entry: var): void {
        run(["delete", dbFor(entry), entry.clipId]);
    }

    function togglePin(entry: var): void {
        if (entry.pinned)
            run(["delete", pinsDb, entry.clipId]);
        else
            run(["pin", mainDb, entry.clipId, pinsDb]);
    }

    // Actions that change a database run one at a time, then the lists reload
    function run(args: var): void {
        queue = [...queue, args];
        if (!actionProc.running)
            next();
    }

    function next(): void {
        if (queue.length === 0) {
            reload();
            return;
        }

        const [args, ...rest] = queue;
        queue = rest;
        actionProc.exec(["sh", script, ...args]);
    }

    // Variants adds new instances at the end, so put the entries back in their order
    list: [...variants.instances].sort((a, b) => a.order - b.order)
    key: "preview"
    useFuzzy: GlobalConfig.launcher.useFuzzy.clipboard

    Component.onCompleted: pruneProc.running = true

    onHistoryEntriesChanged: matchTimer.restart()
    onPinnedEntriesChanged: matchTimer.restart()
    onActiveClipboardChanged: matchTimer.restart()

    Variants {
        id: variants

        model: root.entries

        ClipEntry {}
    }

    Process {
        id: mainProc

        command: ["sh", root.script, "list", root.mainDb]
        stdout: StdioCollector {
            onStreamFinished: root.historyEntries = root.parse(text, false)
        }
        stderr: StdioCollector {
            onStreamFinished: root.warn("listing history", text)
        }
    }

    Process {
        id: pinsProc

        command: ["sh", root.script, "list", root.pinsDb]
        stdout: StdioCollector {
            onStreamFinished: root.pinnedEntries = root.parse(text, true)
        }
        stderr: StdioCollector {
            onStreamFinished: root.warn("listing pins", text)
        }
    }

    Process {
        id: actionProc

        stderr: StdioCollector {
            onStreamFinished: root.warn("running action", text)
        }
        onExited: root.next()
    }

    Process {
        id: currentProc

        command: ["sh", root.script, "current", "-", "4096"]
        stdout: StdioCollector {
            onStreamFinished: {
                const nl = text.indexOf("\n");
                root.activeClipboard = {
                    kind: (nl < 0 ? text : text.slice(0, nl)).trim(),
                    text: nl < 0 ? "" : text.slice(nl + 1)
                };
            }
        }
    }

    Process {
        id: copyProc

        onExited: code => {
            if (code === 0)
                pasteTimer.restart();
        }
    }

    Timer {
        id: pasteTimer

        interval: GlobalConfig.launcher.clipboard.pasteDelay
        onTriggered: root.sendPaste()
    }

    // Lists and the active clipboard load separately, so wait for them to settle
    Timer {
        id: matchTimer

        interval: 50
        onTriggered: {
            if (matchMainProc.running || matchPinsProc.running)
                restart();
            else
                root.matchActive();
        }
    }

    Process {
        id: matchMainProc

        stdout: StdioCollector {
            onStreamFinished: root.onMatched(false, text)
        }
        stderr: StdioCollector {
            onStreamFinished: root.warn("matching clipboard", text)
        }
    }

    Process {
        id: matchPinsProc

        stdout: StdioCollector {
            onStreamFinished: root.onMatched(true, text)
        }
        stderr: StdioCollector {
            onStreamFinished: root.warn("matching pins", text)
        }
    }

    Timer {
        id: confirmTimer

        interval: 3000
        onTriggered: root.confirmingClear = false
    }

    // Decoded images are cached on disk, so drop the stale ones
    Process {
        id: pruneProc

        command: ["sh", root.script, "prune", "-", root.imageDir]
    }

    component ClipEntry: QtObject {
        required property var modelData
        readonly property int order: modelData.order
        readonly property string clipId: modelData.clipId
        readonly property bool pinned: modelData.pinned
        readonly property string preview: modelData.preview
        readonly property bool image: modelData.image
        readonly property string info: modelData.info
    }
}