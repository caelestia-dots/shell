pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Search service over the settings index. The index is generated at build time
// from the page QML files by scripts/build-settings-index.py and shipped as
// assets/settings-index.json (version 2), so it stays in sync with the UI
// without any hand-maintained entries.
//
// Unlike the launcher's fuzzy searcher, this uses the real inverted index +
// ranking baked into the JSON: a query is tokenised, each token is looked up in
// the inverted index (exact token or prefix), the matching entry ids are scored
// with the precomputed per-token ranking, and the best entries are returned.
// SettingEntry QObjects are produced via Variants so the result objects expose
// the same properties the result list expects.
Singleton {
    id: root

    // entries: forward index (one record per setting)
    // inverted: token -> [entry id...]
    // ranking:  token -> { entry id (string): weight }
    property var inverted: ({})
    property var ranking: ({})

    function query(search: string): list<QtObject> {
        const tokens = root._tokenize(search);
        if (tokens.length === 0)
            return [];

        // Accumulate a score per entry id across all query tokens. An entry must
        // match every query token (AND), and its score is the sum of the ranking
        // weights of the index tokens it matched, so results stay relevant.
        const scores = ({});
        const hitCounts = ({});
        for (const token of tokens) {
            const matches = root._lookup(token); // { id: weight }
            for (const id in matches) {
                scores[id] = (scores[id] ?? 0) + matches[id];
                hitCounts[id] = (hitCounts[id] ?? 0) + 1;
            }
        }

        // Sort by score, breaking ties by id so the order is stable (otherwise
        // entries with equal scores can be dropped arbitrarily by the limit).
        const ranked = Object.keys(scores).filter(id => hitCounts[id] === tokens.length).sort((a, b) => scores[b] - scores[a] || (parseInt(a) - parseInt(b))).slice(0, 25);

        const all = entries.instances;
        return ranked.map(id => all[parseInt(id)]).filter(e => e !== undefined);
    }

    // Look up a query token in the inverted index: exact match first, then any
    // indexed token that starts with it (prefix search, so "wif" finds "wifi").
    // Returns a map of entry id -> best ranking weight for that id.
    function _lookup(token: string): var {
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

    function _tokenize(text: string): var {
        return text.toLowerCase().split(/[^a-z0-9]+/).filter(t => t.length > 0);
    }

    Variants {
        id: entries

        SettingEntry {}
    }

    FileView {
        path: Quickshell.shellPath("assets/settings-index.json")
        onLoaded: {
            try {
                const data = JSON.parse(text());
                entries.model = data.entries;
                root.inverted = data.inverted ?? {};
                root.ranking = data.ranking ?? {};
            } catch (e) {
                entries.model = [];
                root.inverted = {};
                root.ranking = {};
            }
        }
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
    }
}
