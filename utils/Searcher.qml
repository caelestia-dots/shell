import "scripts/fzf.js" as Fzf
import "scripts/fuzzysort.js" as Fuzzy
import QtQuick
import Quickshell

Singleton {
    id: root

    required property list<QtObject> list
    property string key: "name"
    property bool useFuzzy: false
    property var extraOpts: ({})

    // Extra stuff for fuzzy
    property list<string> keys: [key]
    property list<real> weights: [1]

    property var cache: ({ fzf: null, fuzzyPrepped: [], lastList: null, lastKeys: null })

    function transformSearch(search: string): string {
        return search;
    }

    function selector(item: var): string {
        // Only for fzf
        return item[key];
    }

    function arraysEqual(a, b) {
        if (!a || !b) return false;
        if (a.length !== b.length) return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i]) return false;
        }
        return true;
    }

    function query(search, queryKeys = keys, queryWeights = weights) {
        search = transformSearch(search.trim().replace(/\s+/g, " "));
        if (!search)
            return [...list];

        if (cache.lastList !== list || !root.arraysEqual(cache.lastKeys, queryKeys) || (cache.fzf && cache.fzf.items.length !== list.length) || (useFuzzy && cache.fuzzyPrepped.length !== list.length)) {
            cache.lastList = list;
            cache.lastKeys = queryKeys;
            cache.fzf = null;
            cache.fuzzyPrepped = [];
        }

        if (useFuzzy) {
            if (cache.fuzzyPrepped.length === 0 && list.length > 0) {
                cache.fuzzyPrepped = list.map(e => {
                    const obj = {
                        _item: e
                    };
                    for (const k of queryKeys)
                        obj[k] = Fuzzy.prepare(e[k]);
                    return obj;
                });
            }
            return Fuzzy.go(search, cache.fuzzyPrepped, Object.assign({
                all: true,
                keys: queryKeys,
                scoreFn: r => queryWeights.reduce((a, w, i) => a + r[i].score * w, 0)
            }, extraOpts)).map(r => r.obj._item);
        }

        if (!cache.fzf) {
            cache.fzf = new Fzf.Finder(list, Object.assign({
                selector
            }, extraOpts));
        }

        return cache.fzf.find(search).sort((a, b) => {
            if (a.score === b.score)
                return selector(a.item).trim().length - selector(b.item).trim().length;
            return b.score - a.score;
        }).map(r => r.item);
    }
}
