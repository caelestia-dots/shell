import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.services
import "../../../utils/scripts/fuzzysort.js" as Fuzzy

// Data and logic behind a launcher picker (i.e. emojis, kaomoji, symbols). The data is read from assets/<name>/<name>.json
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
    readonly property bool hideUnsupported: GlobalConfig.launcher.picker?.hideUnsupported ?? true
    readonly property real fuzzyThreshold: 0.3 // Min fuzzysort score (0-1) for a word to count as a match

    property bool loaded
    property var unfiltered: [] // Everything in the data file
    property var base: [] // The data file, without the items that can't be rendered if hideUnsupported is on
    property var localised: ({}) // From the translations file for the current language (key -> keywords)
    // Every keyword of every item, prepared for fuzzysort, built on the first fuzzy search. It's filled in place rather
    // than reassigned, as that happens while evaluating the search bindings, which would make them loop
    property var fuzzyCache: ({})

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
        if (!checkRenderable || !hideUnsupported)
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

    // Edit distance where swapping two neighbouring letters is a single edit. Returns max + 1 if it's more than max
    function editDistance(a: string, b: string, max: int): int {
        if (Math.abs(a.length - b.length) > max)
            return max + 1;

        let prev2 = [];
        let prev = [];
        for (let j = 0; j <= b.length; j++)
            prev.push(j);

        for (let i = 1; i <= a.length; i++) {
            const cur = [i];
            let min = i;

            for (let j = 1; j <= b.length; j++) {
                let v = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
                if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1])
                    v = Math.min(v, prev2[j - 2] + 1);

                cur.push(v);
                if (v < min)
                    min = v;
            }

            if (min > max)
                return max + 1;

            prev2 = prev;
            prev = cur;
        }

        return prev[b.length];
    }

    // Distance from the token to a keyword or to the start of it (so a half typed word still matches). The first
    // letter has to be right, which also skips most keywords without doing any work
    function typoDistance(token: string, word: string, max: int): int {
        if (token[0] !== word[0])
            return max + 1;

        let best = max + 1;
        for (let l = token.length - 1; l <= token.length + 1; l++)
            best = Math.min(best, editDistance(token, word.slice(0, l), max));
        return best;
    }

    // Each token is fuzzy matched against the individual keywords (not the whole keyword string, which matches way
    // too much), and an item must match every token. Scores of the best keyword per token are summed
    function fuzzySearch(tokens: var): var {
        if (!fuzzyCache.words) {
            const words = [];
            for (let i = 0; i < items.length; i++) {
                for (const w of new Set(items[i].s.split(/\s+/).filter(w => w)))
                    words.push({
                        i,
                        r: w,
                        w: Fuzzy.prepare(w)
                    });
            }
            fuzzyCache.words = words;
        }

        let scores = null; // Item index -> score
        for (const t of tokens) {
            const best = new Map();
            const put = (i, score) => {
                if (!best.has(i) || best.get(i) < score)
                    best.set(i, score);
            };

            for (const r of Fuzzy.go(t, fuzzyCache.words, {
                key: "w",
                threshold: fuzzyThreshold
            }))
                put(r.obj.i, r.score);

            // fuzzysort only matches letters that are in the keyword in order, so it misses wrong or swapped
            // letters (i.e. smilr, smiel). Those are caught by edit distance, unless the token is already the
            // start of a real keyword (i.e. frog shouldn't also match frown)
            const max = t.length >= 6 ? 2 : t.length >= 4 ? 1 : 0;
            if (max > 0 && !fuzzyCache.words.some(w => w.r.startsWith(t))) {
                for (const w of fuzzyCache.words) {
                    const d = typoDistance(t, w.r, max);
                    if (d <= max)
                        put(w.i, 0.6 - d * 0.1); // Ranks below most direct matches
                }
            }

            if (scores === null) {
                scores = best;
            } else {
                const next = new Map();
                for (const [i, score] of scores) {
                    if (best.has(i))
                        next.set(i, score + best.get(i));
                }
                scores = next;
            }

            if (scores.size === 0)
                return [];
        }

        return [...scores].sort((a, b) => b[1] - a[1] || a[0] - b[0]).map(s => items[s[0]]);
    }

    function search(query: string): var {
        const tokens = query.toLowerCase().split(/\s+/).filter(t => t);
        if (tokens.length === 0)
            return [];

        if (GlobalConfig.launcher.useFuzzy.pickers)
            return fuzzySearch(tokens);

        const scored = [];
        for (let i = 0; i < items.length; i++) {
            const s = items[i].s;
            let score = 0;
            let matched = true;

            for (const t of tokens) {
                if (s.includes(` ${t} `))
                    score += 3;
                else
                // Whole word
                if (s.includes(` ${t}`))
                    score += 2;
                else
                // Word prefix
                if (s.includes(t))
                    score += 1;
                else
                // Anywhere
                {
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
        const cmd = GlobalConfig.launcher.picker.pasteCommand;
        if (cmd.length > 0) {
            Quickshell.execDetached(cmd);
            return;
        }

        // Through Hyprland, as external tools create a virtual keyboard, which makes it toast a layout change
        const keys = GlobalConfig.launcher.picker.pasteShortcut;
        const mods = keys.slice(0, -1);
        const key = keys[keys.length - 1];
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.send_shortcut({ mods = "${mods.join("+")}", key = "${key}" })` : `sendshortcut ${mods.join(" ")}, ${key}, activewindow`);
    }

    onItemsChanged: fuzzyCache = ({})

    // The filtering is too slow for a binding (and changes the probe's text), so it's redone when the option changes
    onHideUnsupportedChanged: {
        if (loaded)
            base = filterRenderable(unfiltered);
    }

    onLocaleCandidatesChanged: {
        localeAttempt = 0;
        localised = ({});
        Qt.callLater(() => localeFile.reload());
    }

    Timer {
        id: pasteTimer

        // Give the compositor time to hand focus back to the previous window
        interval: GlobalConfig.launcher.picker.pasteDelay
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
                root.unfiltered = items;
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
