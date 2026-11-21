pragma Singleton

import "../../utils/scripts/fzf.js" as Fzf
import "../../utils/scripts/settings-indexer.js" as SettingsIndexer
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils

Singleton {
    id: root

    property var indexEntries: []
    property var inverted: ({})
    property var ranking: ({})
    readonly property var tokenKeys: Object.keys(inverted).sort()
    readonly property var highlightCache: ({
            "search": "",
            "tokens": []
        })
    readonly property var foldCache: ({})
    property var fzfFinder: null
    // Bump when the cached data's shape changes
    readonly property int cacheVersion: 7
    // Keep as a property: qmllint ignores identifiers in template literals and would flag qs.utils as unused
    readonly property string cachePath: Paths.cache + "/settings-index.json"
    property string cacheKey
    readonly property int maxResults: Math.max(1, GlobalConfig.nexus.maxSearchResults)

    function query(search: string): list<QtObject> {
        const tokens = SettingsIndexer.splitWords(search);
        if (tokens.length === 0)
            return [];

        const scores = ({});
        const hitCounts = ({});
        for (const token of tokens) {
            const matches = root.lookup(token);
            for (const id in matches) {
                scores[id] = (scores[id] ?? 0) + matches[id];
                hitCounts[id] = (hitCounts[id] ?? 0) + 1;
            }
        }

        const ranked = Object.keys(scores).filter(id => hitCounts[id] === tokens.length).sort((a, b) => scores[b] - scores[a] || (parseInt(a) - parseInt(b)));

        const all = entries.instances;
        const usable = e => e !== undefined && root.isAvailable(e.anchor);
        const out = [];
        for (const id of ranked) {
            const entry = all[parseInt(id)];
            if (usable(entry))
                out.push(entry);
            if (out.length >= root.maxResults)
                break;
        }

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
                if (usable(entry))
                    out.push(entry);
                if (out.length >= root.maxResults)
                    break;
            }
        }

        return out;
    }

    function isAvailable(anchor: string): bool {
        if (anchor.startsWith("ethernet-"))
            return Nmcli.hasAvailableEthernet;
        if (anchor === "network-add-network" || anchor.startsWith("add-network-"))
            return Nmcli.wifiEnabled;
        if (anchor === "network-all-networks")
            return Nmcli.wifiEnabled && Nmcli.networks.length > GlobalConfig.nexus.maxNetworksShown;
        if (anchor === "bluetooth-pair-device")
            return Bluetooth.defaultAdapter?.enabled ?? false;
        return true;
    }

    function lookup(token: string): var {
        const result = ({});
        const keys = root.tokenKeys;
        let lo = 0;
        let hi = keys.length;
        while (lo < hi) {
            const mid = (lo + hi) >> 1;
            if (keys[mid] < token)
                lo = mid + 1;
            else
                hi = mid;
        }
        for (let k = lo; k < keys.length && keys[k].startsWith(token); k++) {
            const key = keys[k];
            const factor = key === token ? 1 : 0.8;
            const rank = root.ranking[key] ?? ({});
            for (const id of root.inverted[key]) {
                const w = (rank[id] ?? 0.1) * factor;
                if (result[id] === undefined || w > result[id])
                    result[id] = w;
            }
        }

        return result;
    }

    function highlight(text: string, search: string, colour: color): string {
        const escape = t => t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

        const cache = root.highlightCache;
        if (search !== cache.search) {
            cache.search = search;
            cache.tokens = SettingsIndexer.splitWords(search);
        }

        // Unmatched text is returned unescaped on purpose, the caller shows it as PlainText
        const tokens = cache.tokens;
        if (tokens.length === 0)
            return text;

        let info = root.foldCache[text];
        if (info === undefined) {
            const folded = SettingsIndexer.foldAligned(text);
            const starts = [];
            for (let i = 0; i < folded.length; i++) {
                if (i === 0 || SettingsIndexer.isSeparator(folded[i - 1]))
                    starts.push(i);
            }
            info = {
                "folded": folded,
                "starts": starts
            };
            root.foldCache[text] = info;
        }

        const folded = info.folded;
        let out = "";
        let last = 0;
        for (const i of info.starts) {
            if (i < last)
                continue;
            const len = tokens.reduce((max, t) => folded.startsWith(t, i) ? Math.max(max, t.length) : max, 0);
            if (len === 0)
                continue;
            out += `${escape(text.slice(last, i))}<font color="${colour}">${escape(text.slice(i, i + len))}</font>`;
            last = i + len;
        }

        return last === 0 ? text : out + escape(text.slice(last));
    }

    function loadIndex(): var {
        const nexusDir = `${Quickshell.shellDir}/modules/nexus`;
        const sources = CUtils.listFiles(nexusDir, ".qml").concat([`${Quickshell.shellDir}/utils/scripts/settings-indexer.js`]);
        root.cacheKey = `${CUtils.gitRevision}:${CUtils.fileFingerprint(sources)}`;
        const cached = CUtils.readTextFile(root.cachePath);
        if (cached) {
            try {
                const parsed = JSON.parse(cached);
                if (parsed.version === root.cacheVersion && parsed.key === root.cacheKey)
                    return parsed;
            } catch (e) {}
        }
        const data = SettingsIndexer.buildIndex(nexusDir, p => CUtils.readTextFile(p), (d, s) => CUtils.listFiles(d, s));
        if (data.entries.length === 0)
            console.warn(`SettingsSearcher: no settings found in ${nexusDir}`);
        else
            console.log(`SettingsSearcher: indexed ${data.entries.length} settings (revision ${CUtils.gitRevision || "unknown"})`);
        return data;
    }

    function buildSearch(): void {
        const search = SettingsIndexer.buildSearch(root.indexEntries, text => Tr.trMarked(text));
        root.inverted = search.inverted;
        root.ranking = search.ranking;
        // Never cache an empty index (unreadable sources), it would keep search empty until they change
        if (root.indexEntries.length > 0)
            CUtils.writeTextFile(root.cachePath, JSON.stringify({
                version: root.cacheVersion,
                key: root.cacheKey,
                language: Tr.language,
                entries: root.indexEntries,
                inverted: search.inverted,
                ranking: search.ranking
            }));
        root.buildFinder();
    }

    function buildFinder(): void {
        const docs = root.indexEntries.map((e, i) => ({
                    idx: i,
                    text: SettingsIndexer.fold(SettingsIndexer.cleanLabel(Tr.trMarked(e.title)))
                }));
        root.fzfFinder = new Fzf.Finder(docs, {
            selector: d => d.text,
            limit: root.maxResults
        });
    }

    onMaxResultsChanged: {
        if (root.fzfFinder)
            root.buildFinder();
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
        readonly property var crumbLabels: modelData.crumbLabels.map(l => Tr.trMarked(l))
        readonly property string title: SettingsIndexer.cleanLabel(Tr.trMarked(modelData.title))
        readonly property string section: Tr.trMarked(modelData.section ?? "")
        readonly property string subtext: Tr.trMarked(modelData.subtext ?? "")
        readonly property string anchor: modelData.anchor ?? ""
        readonly property string icon: modelData.icon ?? ""

        readonly property string togglePath: modelData.togglePath ?? ""
        readonly property bool toggleGlobal: modelData.toggleGlobal ?? false
        readonly property bool isToggle: togglePath.length > 0

        // Always written to GlobalConfig, even for options read per screen, same as the pages' switches
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
