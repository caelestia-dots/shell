pragma Singleton

import "../../utils/scripts/fzf.js" as Fzf
import "../../utils/scripts/settings-indexer.js" as SettingsIndexer
import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.utils

// Search service over the settings index. The index is built by the shell
// itself on first use - the page QML sources are parsed at runtime (see
// utils/scripts/settings-indexer.js) and the result is cached on disk, keyed
// by the plugin's git revision so an update rebuilds it. No build step, no
// hand-maintained entries, no user-editable data file.
//
Singleton {
    id: root

    // entries: forward index (one record per setting)
    // inverted: token -> [entry id...]
    // ranking:  token -> { entry id (string): weight }
    property var inverted: ({})
    property var ranking: ({})
    readonly property var highlightCache: ({
            "search": "",
            "pattern": null
        })
    // fzf finder over the entries (title + keywords), used as a fuzzy fallback
    // when the exact/prefix index lookup comes up short. fzf is the same matcher
    // the launcher uses, so typo and mid-word matching behave consistently.
    property var fzfFinder: null

    function query(search: string): list<QtObject> {
        const tokens = root.tokenize(search);
        if (tokens.length === 0)
            return [];

        // Accumulate a score per entry id across all query tokens. An entry must
        // match every query token (AND), and its score is the sum of the ranking
        // weights of the index tokens it matched, so results stay relevant.
        const scores = ({});
        const hitCounts = ({});
        for (const token of tokens) {
            const matches = root.lookup(token); // { id: weight }
            for (const id in matches) {
                scores[id] = (scores[id] ?? 0) + matches[id];
                hitCounts[id] = (hitCounts[id] ?? 0) + 1;
            }
        }

        // Sort by score, breaking ties by id so the order is stable (otherwise
        // entries with equal scores can be dropped arbitrarily by the limit).
        const ranked = Object.keys(scores).filter(id => hitCounts[id] === tokens.length).sort((a, b) => scores[b] - scores[a] || (parseInt(a) - parseInt(b))).slice(0, 25);

        const all = entries.instances;
        const out = ranked.map(id => all[parseInt(id)]).filter(e => e !== undefined);

        // The inverted index only does exact/prefix matches. When it finds little
        // or nothing - a typo ("trasparency") or a mid-word query ("paper") - fall
        // back to fzf over the same entries. fzf hits that the index already
        // returned are skipped, and the rest are appended after the (stronger)
        // index results, so precise matches always lead.
        if (out.length < 5 && root.fzfFinder) {
            const seen = ({});
            for (const id of ranked)
                seen[id] = true;
            const fuzzy = root.fzfFinder.find(search);
            for (const r of fuzzy) {
                const idx = r.item.idx;
                if (seen[idx])
                    continue;
                seen[idx] = true;
                const entry = all[idx];
                if (entry !== undefined)
                    out.push(entry);
                if (out.length >= 25)
                    break;
            }
        }

        return out;
    }

    // Look up a query token in the inverted index: exact match first, then any
    // indexed token that starts with it (prefix search, so "wif" finds "wifi").
    // Returns a map of entry id -> best ranking weight for that id.
    function lookup(token: string): var {
        const result = ({});
        const exact = root.inverted[token] !== undefined;
        const keys = exact ? [token] : Object.keys(root.inverted).filter(k => k.startsWith(token));
        for (const key of keys) {
            const rank = root.ranking[key] ?? ({});
            for (const id of root.inverted[key]) {
                const w = rank[id] ?? 0.1;
                if (result[id] === undefined || w > result[id])
                    result[id] = w;
            }
        }

        return result;
    }

    function tokenize(text: string): var {
        return text.toLowerCase().split(/[^a-z0-9]+/).filter(t => t.length > 0);
    }

    function highlight(text: string, search: string, colour: color): string {
        const escaped = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        if (search.length === 0)
            return escaped;

        // Rebuild the regex only when the search changes; every card reuses it.
        const cache = root.highlightCache;
        if (search !== cache.search) {
            const tokens = root.tokenize(search);
            cache.search = search;
            if (tokens.length === 0) {
                cache.pattern = null;
            } else {
                const escapedTokens = tokens.map(t => t.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
                cache.pattern = new RegExp("\\b(" + escapedTokens.join("|") + ")", "gi");
            }
        }

        const pattern = cache.pattern;
        if (!pattern)
            return escaped;

        // Skip building (and later rich-text parsing) an HTML string when this
        // text has no match - which is most subtexts. The caller checks for a
        // "<font" tag to decide between StyledText and the cheaper PlainText.
        pattern.lastIndex = 0;
        if (!pattern.test(escaped))
            return escaped;

        pattern.lastIndex = 0;
        return escaped.replace(pattern, `<font color="${colour}">$1</font>`);
    }

    function loadIndex(): var {
        const revision = CUtils.gitRevision();
        const cachePath = `${Paths.cache}/settings-index.json`;
        const cached = CUtils.readTextFile(cachePath);
        if (cached) {
            try {
                const parsed = JSON.parse(cached);
                if (parsed.version === 3 && revision && parsed.revision === revision)
                    return parsed;
            } catch (e) {}
        }
        const data = SettingsIndexer.buildIndex(`${Quickshell.shellDir}/modules/nexus`, p => CUtils.readTextFile(p), (d, s) => CUtils.listFiles(d, s));
        data.revision = revision;
        CUtils.writeTextFile(cachePath, JSON.stringify(data));
        console.log(`SettingsSearcher: indexed ${data.entries.length} settings (revision ${revision || "unknown"})`);
        return data;
    }

    Component.onCompleted: {
        try {
            const data = root.loadIndex();
            entries.model = data.entries;
            root.inverted = data.inverted ?? {};
            root.ranking = data.ranking ?? {};
            // One searchable string per entry: the title. fzf provides typo and
            // mid-word matching over titles as a fallback when the exact/prefix
            // index lookup comes up short.
            const docs = data.entries.map((e, i) => ({
                        idx: i,
                        text: e.title
                    }));
            root.fzfFinder = new Fzf.Finder(docs, {
                selector: d => d.text,
                limit: 25
            });
        } catch (e) {
            console.warn("SettingsSearcher: failed to build settings index:", e);
            entries.model = [];
            root.inverted = {};
            root.ranking = {};
            root.fzfFinder = null;
        }
    }

    Variants {
        id: entries

        SettingEntry {}
    }

    component SettingEntry: QtObject {
        required property var modelData

        readonly property int pageIdx: modelData.pageIdx
        readonly property var subPath: modelData.subPath
        readonly property var crumbIcons: modelData.crumbIcons
        readonly property var crumbLabels: modelData.crumbLabels
        readonly property string title: modelData.title
        readonly property string section: modelData.section ?? ""
        readonly property string subtext: modelData.subtext ?? ""
        readonly property string anchor: modelData.anchor ?? ""
        // The setting's own icon for the result card, baked by the index script.
        readonly property string icon: modelData.icon ?? ""

        // A non-empty togglePath means this is a plain on/off setting that can be
        // flipped straight from the results (e.g. "background.wallpaperEnabled").
        readonly property string togglePath: modelData.togglePath ?? ""
        readonly property bool isToggle: togglePath.length > 0
        // Live value of the config property, read by walking the path on
        // GlobalConfig. Re-evaluates when that property changes.
        readonly property bool toggleValue: {
            if (!isToggle)
                return false;
            let obj = GlobalConfig;
            const parts = togglePath.split(".");
            for (const part of parts) {
                if (obj === undefined || obj === null)
                    return false;
                obj = obj[part];
            }
            return obj ?? false;
        }

        // Write `value` back to the config property the path points at.
        function setToggle(value: bool): void {
            if (!isToggle)
                return;
            const parts = togglePath.split(".");
            let obj = GlobalConfig;
            for (let k = 0; k < parts.length - 1; k++) {
                if (obj === undefined || obj === null)
                    return;
                obj = obj[parts[k]];
            }
            if (obj !== undefined && obj !== null)
                obj[parts[parts.length - 1]] = value;
        }
    }
}
