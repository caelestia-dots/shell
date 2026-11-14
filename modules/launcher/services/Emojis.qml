pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.services

Singleton {
    id: root

    readonly property int maxRecent: 24

    // The data follows the latest Unicode release, which is often newer than the installed emoji font. Emojis
    // from this version onwards are checked against the fonts, as older ones are universally supported
    readonly property real checkFromVersion: 12

    // Order matches the tab order in the picker. Icons are Material Symbols (not emojis)
    readonly property var groups: [
        {
            id: "recent",
            icon: "history",
            name: Tr.trCtx("Recent", "emoji category")
        },
        {
            id: "people",
            icon: "mood",
            name: Tr.trCtx("Smileys & People", "emoji category")
        },
        {
            id: "nature",
            icon: "pets",
            name: Tr.trCtx("Animals & Nature", "emoji category")
        },
        {
            id: "food",
            icon: "restaurant",
            name: Tr.trCtx("Food & Drink", "emoji category")
        },
        {
            id: "activities",
            icon: "sports_soccer",
            name: Tr.trCtx("Activities", "emoji category")
        },
        {
            id: "travel",
            icon: "directions_car",
            name: Tr.trCtx("Travel & Places", "emoji category")
        },
        {
            id: "objects",
            icon: "lightbulb",
            name: Tr.trCtx("Objects", "emoji category")
        },
        {
            id: "symbols",
            icon: "emoji_symbols",
            name: Tr.trCtx("Symbols", "emoji category")
        },
        {
            id: "flags",
            icon: "flag",
            name: Tr.trCtx("Flags", "emoji category")
        }
    ]

    property bool loaded
    property var base: []   // From assets/emojis/emojis.json (English)
    property var localised: ({})   // From assets/emojis/i18n/<locale>.json (hexcode -> keywords)

    // Keywords are never displayed, only searched. They're padded with spaces for cheap word matching
    readonly property var emojis: base.map(e => ({
                c: e.c,
                g: e.g,
                h: e.h,
                s: ` ${e.k} ${localised[e.h] ?? ""} `.toLowerCase()
            }))

    readonly property var byChar: {
        const map = {};
        for (const e of emojis)
            map[e.c] = e;
        return map;
    }

    readonly property var byGroup: {
        const map = {};
        for (const e of emojis) {
            if (!map[e.g])
                map[e.g] = [];
            map[e.g].push(e);
        }
        return map;
    }

    readonly property var recent: PersistentState.recentEmojis

    // emojibase locale codes are lowercase and dash separated (e.g. pt, zh-hant, en-gb), try the most specific first
    property int localeAttempt
    readonly property var localeCandidates: {
        const lang = Tr.language.toLowerCase().replace("_", "-");
        const base = lang.split("-")[0];
        return [...new Set([lang, base])].filter(l => l && l !== "en");
    }

    // An emoji is renderable if it shows up as a single glyph as wide as a known one. Missing glyphs fall back
    // to a different (narrow) .notdef glyph, and unsupported ZWJ sequences get split into multiple glyphs
    function filterRenderable(all: var): var {
        if (!GlobalConfig.launcher.emoji.hideUnsupported)
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
        for (let i = 0; i < emojis.length; i++) {
            const s = emojis[i].s;
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
                    emoji: emojis[i],
                    score,
                    i
                });
        }

        return scored.sort((a, b) => b.score - a.score || a.i - b.i).map(s => s.emoji);
    }

    // Copies the emoji, and optionally pastes it into the previously focused window (call after closing the launcher)
    function pick(char: string, paste: bool): void {
        Quickshell.execDetached(["wl-copy", "--", char]);
        PersistentState.recentEmojis = [char, ...recent.filter(c => c !== char)].slice(0, maxRecent);

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

    TextMetrics {
        id: probe

        font.pixelSize: 32
    }

    Timer {
        id: pasteTimer

        // Give the compositor time to hand focus back to the previous window
        interval: GlobalConfig.launcher.emoji.pasteDelay
        onTriggered: root.sendPaste()
    }

    FileView {
        path: Quickshell.shellPath("assets/emojis/emojis.json")
        onLoaded: {
            root.base = root.filterRenderable(JSON.parse(text()).emojis);
            root.loaded = true;
        }
    }

    FileView {
        id: localeFile

        path: root.localeAttempt < root.localeCandidates.length ? Quickshell.shellPath(`assets/emojis/i18n/${root.localeCandidates[root.localeAttempt]}.json`) : ""
        printErrors: false
        onLoaded: root.localised = JSON.parse(text())
        onLoadFailed: root.localeAttempt++ // Try the next candidate, if any
    }
}
