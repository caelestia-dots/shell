import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.services

// Data and logic behind a launcher picker (i.e. emojis, kaomoji). The data is read from assets/<name>/<name>.json
// and the keywords for other languages from assets/<name>/i18n/<locale>.json
Scope {
    id: root

    required property string name
    required property string mode // What follows the action prefix to open the picker, i.e. "emoji" for `>emoji `
    required property var groups // [{ id, icon, name }], the "recent" group is filled in from recent
    required property var recent // Persisted recents, most recent first

    property int columns: 12
    property bool wide // Wide rows of text (i.e. kaomoji) rather than square cells of single glyphs
    property bool checkRenderable // Hide items whose glyphs aren't in the installed fonts (see filterRenderable)

    // The emoji data follows the latest Unicode release, which is often newer than the installed emoji font. Emojis
    // from this version onwards are checked against the fonts, as older ones are universally supported
    readonly property real checkFromVersion: 12
    readonly property int maxRecent: 24

    property bool loaded
    property var base: [] // From the data file
    property var localised: ({}) // From the translations file for the current language (key -> keywords)

    // Keywords are never displayed, only searched. They're padded with spaces for cheap word matching
    readonly property var items: base.map(e => ({
                c: e.c,
                g: e.g,
                k: e.h ?? e.c,
                s: ` ${e.k} ${localised[e.h ?? e.c] ?? ""} `.toLowerCase()
            }))

    readonly property var byChar: {
        const map = {};
        for (const e of items)
            map[e.c] = e;
        return map;
    }

    readonly property var byGroup: {
        const map = {};
        for (const e of items) {
            if (!map[e.g])
                map[e.g] = [];
            map[e.g].push(e);
        }
        return map;
    }

    // emojibase locale codes are lowercase and dash separated (e.g. pt, zh-hant, en-gb), try the most specific first
    property int localeAttempt
    readonly property var localeCandidates: {
        const lang = Tr.language.toLowerCase().replace("_", "-");
        const base = lang.split("-")[0];
        return [...new Set([lang, base])].filter(l => l && l !== "en");
    }

    signal recentRequested(var list)

    // An emoji is renderable if it shows up as a single glyph as wide as a known one. Missing glyphs fall back
    // to a different (narrow) .notdef glyph, and unsupported ZWJ sequences get split into multiple glyphs
    function filterRenderable(all: var): var {
        if (!checkRenderable || !(GlobalConfig.launcher.emoji?.hideUnsupported ?? true))
            return all;

        probe.text = "😀";
        const reference = probe.advanceWidth;
        if (reference <= 0)
            return all;

        return all.filter(e => {
            if (e.v < checkFromVersion)
                return true;

            probe.text = e.c;
            return Math.abs(probe.advanceWidth - reference) < 1;
        });
    }

    function search(query: string): var {
        const tokens = query.toLowerCase().split(/\s+/).filter(t => t);
        if (tokens.length === 0)
            return [];

        const scored = [];
        for (let i = 0; i < items.length; i++) {
            const s = items[i].s;
            let score = 0;
            let matched = true;

            for (const t of tokens) {
                if (s.includes(` ${t} `))
                    score += 3; // Whole word
                else if (s.includes(` ${t}`))
                    score += 2; // Word prefix
                else if (s.includes(t))
                    score += 1; // Anywhere
                else {
                    matched = false;
                    break;
                }

                if (s.startsWith(` ${t}`))
                    score += 1; // Starts with the main name
            }

            if (matched)
                scored.push({
                    item: items[i],
                    score,
                    i
                });
        }

        return scored.sort((a, b) => b.score - a.score || a.i - b.i).map(s => s.item);
    }

    // Copies the text, and optionally pastes it into the previously focused window (call after closing the launcher)
    function pick(text: string, paste: bool): void {
        Quickshell.execDetached(["wl-copy", "--", text]);
        recentRequested([text, ...recent.filter(c => c !== text)].slice(0, maxRecent));

        if (paste)
            pasteTimer.restart();
    }

    // Mimics CTRL + V by default with a hyprland dispatch
    function sendPaste(): void {
        const cmd = GlobalConfig.launcher.emoji.pasteCommand;
        if (cmd.length > 0) {
            Quickshell.execDetached(cmd);
            return;
        }

        // Through Hyprland, as external tools create a virtual keyboard, which makes it toast a layout change
        const keys = GlobalConfig.launcher.emoji.pasteShortcut;
        const mods = keys.slice(0, -1);
        const key = keys[keys.length - 1];
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.send_shortcut({ mods = "${mods.join("+")}", key = "${key}" })` : `sendshortcut ${mods.join(" ")}, ${key}, activewindow`);
    }

    onLocaleCandidatesChanged: {
        localeAttempt = 0;
        localised = ({});
        Qt.callLater(() => localeFile.reload());
    }

    Timer {
        id: pasteTimer

        // Give the compositor time to hand focus back to the previous window
        interval: GlobalConfig.launcher.emoji.pasteDelay
        onTriggered: root.sendPaste()
    }

    TextMetrics {
        id: probe

        font.pixelSize: 32
    }

    FileView {
        path: Quickshell.shellPath(`assets/${root.name}/${root.name}.json`)
        onLoaded: {
            try {
                const items = JSON.parse(text()).items ?? [];
                root.base = root.filterRenderable(items);
                root.loaded = true;
                console.log(`PickerSource(${root.name}): loaded ${root.base.length}/${items.length} items`);
            } catch (e) {
                console.warn(`PickerSource(${root.name}): failed to load ${path}:`, e);
            }
        }
        onLoadFailed: err => console.warn(`PickerSource(${root.name}): failed to read ${path}:`, err)
    }

    FileView {
        id: localeFile

        path: root.localeAttempt < root.localeCandidates.length ? Quickshell.shellPath(`assets/${root.name}/i18n/${root.localeCandidates[root.localeAttempt]}.json`) : ""
        printErrors: false
        onLoaded: root.localised = JSON.parse(text())
        onLoadFailed: root.localeAttempt++ // Try the next candidate, if any
    }
}
