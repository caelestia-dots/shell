pragma Singleton

import "../../utils/scripts/fzf.js" as Fzf
import "../../utils/scripts/settings-indexer.js" as SettingsIndexer
import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n // qmllint disable
import qs.utils

// Search service over the settings index. The index is built by the shell
// itself on first use - the page QML sources are parsed at runtime (see
// utils/scripts/settings-indexer.js) and the result is cached on disk, keyed
// by the plugin's git revision so an update rebuilds it. No build step, no
// hand-maintained entries, no user-editable data file.
//
// Entries hold marked strings, so they only depend on the revision. The search
// tokens come from the translated labels, so they're cached with the language
// they were built in and rebuilt when it differs or changes.
Singleton {
    id: root

    // indexEntries: forward index (one record per setting), labels marked
    // inverted: token -> [entry id...]
    // ranking:  token -> { entry id (string): weight }
    property var indexEntries: []
    property var inverted: ({})
    property var ranking: ({})
    readonly property var highlightCache: ({
            "search": "",
            "tokens": []
        })
    // fzf finder over the entries (title + keywords), used as a fuzzy fallback
    // when the exact/prefix index lookup comes up short. fzf is the same matcher
    // the launcher uses, so typo and mid-word matching behave consistently.
    property var fzfFinder: null
    // Bump when the cached data's shape changes
    readonly property int cacheVersion: 5
    // Declared here rather than inlined in loadIndex(): qmllint doesn't see
    // identifiers used inside template literals in a function body, so
    // referencing Paths only there had it report qs.utils as unused.
    readonly property string cachePath: Paths.cache + "/settings-index.json"

    function query(search: string): list<QtObject> {
        const tokens = SettingsIndexer.splitWords(search);
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
            const fuzzy = root.fzfFinder.find(SettingsIndexer.fold(search));
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

    function highlight(text: string, search: string, colour: color): string {
        const escape = t => t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

        // Split the search only when it changes; every card reuses the tokens.
        const cache = root.highlightCache;
        if (search !== cache.search) {
            cache.search = search;
            cache.tokens = SettingsIndexer.splitWords(search);
        }

        const tokens = cache.tokens;
        if (tokens.length === 0)
            return escape(text);

        // Match against the folded text so "gorunum" lights up "Görünüm", then
        // cut the original at the same offsets. Only word starts match, like
        // the index's prefix lookup.
        const folded = SettingsIndexer.foldAligned(text);
        let out = "";
        let last = 0;
        for (let i = 0; i < folded.length; i++) {
            if (i > 0 && !SettingsIndexer.isSeparator(folded[i - 1]))
                continue;
            const len = tokens.reduce((max, t) => folded.startsWith(t, i) ? Math.max(max, t.length) : max, 0);
            if (len === 0)
                continue;
            out += `${escape(text.slice(last, i))}<font color="${colour}">${escape(text.slice(i, i + len))}</font>`;
            last = i + len;
            i = last - 1;
        }

        // Most subtexts have no match. The caller checks for a "<font" tag to
        // decide between StyledText and the cheaper PlainText.
        return last === 0 ? escape(text) : out + escape(text.slice(last));
    }

    function loadIndex(): var {
        const revision = CUtils.gitRevision;
        const cached = CUtils.readTextFile(root.cachePath);
        if (cached) {
            try {
                const parsed = JSON.parse(cached);
                if (parsed.version === root.cacheVersion && revision && parsed.revision === revision)
                    return parsed;
            } catch (e) {}
        }
        const data = SettingsIndexer.buildIndex(`${Quickshell.shellDir}/modules/nexus`, p => CUtils.readTextFile(p), (d, s) => CUtils.listFiles(d, s));
        console.log(`SettingsSearcher: indexed ${data.entries.length} settings (revision ${revision || "unknown"})`);
        return data;
    }

    // Tokenises the translated labels, so this runs again on a language change.
    function buildSearch(): void {
        const search = SettingsIndexer.buildSearch(root.indexEntries, text => Tr.trMarked(text));
        root.inverted = search.inverted;
        root.ranking = search.ranking;
        CUtils.writeTextFile(root.cachePath, JSON.stringify({
            version: root.cacheVersion,
            revision: CUtils.gitRevision,
            language: Tr.language,
            entries: root.indexEntries,
            inverted: search.inverted,
            ranking: search.ranking
        }));
        root.buildFinder();
    }

    // One searchable string per entry: the title. fzf provides typo and
    // mid-word matching over titles as a fallback when the exact/prefix index
    // lookup comes up short. Cheap, so never cached.
    function buildFinder(): void {
        const docs = root.indexEntries.map((e, i) => ({
                    idx: i,
                    text: SettingsIndexer.fold(SettingsIndexer.cleanLabel(Tr.trMarked(e.title)))
                }));
        root.fzfFinder = new Fzf.Finder(docs, {
            selector: d => d.text,
            limit: 25
        });
    }

    Component.onCompleted: {
        try {
            const data = root.loadIndex();
            root.indexEntries = data.entries;
            if (data.inverted && data.language === Tr.language) {
                root.inverted = data.inverted;
                root.ranking = data.ranking;
                root.buildFinder();
            } else {
                root.buildSearch();
            }
        } catch (e) {
            console.warn("SettingsSearcher: failed to build settings index:", e);
            root.indexEntries = [];
            root.inverted = {};
            root.ranking = {};
            root.fzfFinder = null;
        }
    }

    Connections {
        function onLanguageChanged(): void {
            root.buildSearch();
        }

        target: Tr
    }

    Variants {
        id: entries

        model: root.indexEntries

        SettingEntry {}
    }

    component SettingEntry: QtObject {
        required property var modelData

        readonly property int pageIdx: modelData.pageIdx
        readonly property var subPath: modelData.subPath
        readonly property var crumbIcons: modelData.crumbIcons
        // Labels are marked in the index, trMarked() re-evaluates these on a
        // language change.
        readonly property var crumbLabels: modelData.crumbLabels.map(l => Tr.trMarked(l))
        readonly property string title: SettingsIndexer.cleanLabel(Tr.trMarked(modelData.title))
        readonly property string section: Tr.trMarked(modelData.section ?? "")
        readonly property string subtext: Tr.trMarked(modelData.subtext ?? "")
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
