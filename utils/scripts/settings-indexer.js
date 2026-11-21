// Builds the settings search index by reading the nexus page sources line by line. Labels are kept
// as marked strings (see plugin/include/util/i18n.hpp), so the entries don't depend on the language.
.pragma library

const STOPWORDS = ["a", "an", "and", "are", "for", "in", "not", "notification", "of", "on", "or", "out", "the", "to"];

const FIELD_WEIGHT = {
    title: 1.0,
    keywords: 0.4,
    source: 0.3
};

// Must match util::i18n::doMark without args or plurals
const MARK = "\x01";
const CONTEXT_SEP = "\x04";

function mark(text, context) {
    return MARK + (context ? context + CONTEXT_SEP : "") + text;
}

function unmark(text) {
    if (!text.startsWith(MARK))
        return text;
    const body = text.slice(1);
    return body.slice(body.indexOf(CONTEXT_SEP) + 1);
}

const STR = String.raw`"((?:\\.|[^"\\])*)"`;
const TR_CALL = String.raw`Tr\.(?:tr\(\s*${STR}\s*\)|trCtx\(\s*${STR}\s*,\s*${STR}\s*\))`;

function unescape(text) {
    return text.replace(/\\(.)/g, "$1");
}

function markedMatch(m, first) {
    if (m[first] !== undefined)
        return mark(unescape(m[first]), "");
    return mark(unescape(m[first + 1]), unescape(m[first + 2]));
}

function cleanLabel(text) {
    return String(text ?? "").replace(/\s*\(?%\d+\)?/g, "").trim();
}

const ROW_RE = /^\s*(ToggleRow|SliderRow|SelectRow|StepperRow|NavRow|RowButton|InfoRow|PopupRow|DefaultRow|TextFieldRow)\s*\{/;
const LABEL_RE = new RegExp(String.raw`^\s*(?:label|text):\s*` + TR_CALL);
const ANCHOR_RE = /^\s*settingAnchor:\s*"([^"]+)"/;
const CHECKED_RE = /^\s*checked:\s*(GlobalConfig|Config)\.([\w.]+)\s*$/;
const ONTOGGLED_RE = /^\s*onToggled:\s*(?:GlobalConfig|Config)\.([\w.]+)\s*=\s*checked\s*$/;
const ICON_RE = /^\s*icon:\s*"([^"]+)"/;
const SEARCH_ICON_RE = /^\s*searchIcon:\s*"([^"]+)"/;
const SUBTEXT_RE = new RegExp(String.raw`^\s*(?:subtext|status):\s*` + TR_CALL);
const SECTION_RE = /^\s*SectionHeader\s*\{/;

// Qt's JS engine has no \p{L}, so words are split on explicit space and punctuation ranges
const SEPARATORS = /[\s\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x7e\u00a0-\u00bf\u00d7\u00f7\u2000-\u206f\u3000-\u303f]+/;

// Dotless i has no decomposition, so it's folded by hand
function fold(text) {
    return text.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/\u0131/g, "i");
}

// Keeps the length, so highlight positions map back onto the original text
function foldAligned(text) {
    let out = "";
    for (const c of text) {
        const f = fold(c);
        out += f.length === c.length ? f : c;
    }
    return out;
}

function isSeparator(c) {
    return SEPARATORS.test(c);
}

// Stopwords are never indexed, so they're dropped unless the query has nothing else
function splitWords(text) {
    const words = fold(text).split(SEPARATORS).filter(w => w.length > 0);
    const kept = words.filter(w => !STOPWORDS.includes(w));
    return kept.length > 0 ? kept : words;
}

function tokenize(text) {
    const toks = [];
    for (const word of fold(text).split(/\s+/)) {
        if (!word)
            continue;
        const parts = word.split(SEPARATORS).filter(p => p);
        for (const p of parts) {
            if (!STOPWORDS.includes(p) && !toks.includes(p))
                toks.push(p);
        }
        if (parts.length > 1) {
            const joined = parts.join("");
            if (!toks.includes(joined))
                toks.push(joined);
        }
    }
    return toks;
}

function discoverFiles(nexusDir, listFiles) {
    const files = {};
    for (const p of listFiles(`${nexusDir}/pages`, ".qml")) {
        const name = p.slice(p.lastIndexOf("/") + 1).replace(/\.qml$/, "");
        files[name] = p;
    }
    return files;
}

function parsePageRegistry(nexusDir, readLines) {
    const lines = readLines(`${nexusDir}/PageRegistry.qml`);
    const out = [];
    let inArray = false;
    let depth = 0;
    let label = null;
    let icon = null;
    for (const line of lines) {
        const s = line.trim();
        if (s.includes("pages:") && s.includes("[")) {
            inArray = true;
            continue;
        }
        if (!inArray)
            continue;
        if (s.startsWith("//"))
            continue;
        if (s.startsWith("{")) {
            depth++;
            label = icon = null;
            continue;
        }
        if (s.startsWith("}")) {
            if (label !== null)
                out.push([icon || "tune", label]);
            depth--;
            continue;
        }
        if (depth >= 1) {
            const m = LABEL_RE.exec(line);
            if (m && label === null)
                label = markedMatch(m, 1);
            const mi = ICON_RE.exec(line);
            if (mi && icon === null)
                icon = mi[1];
        }
    }
    return out;
}

function parsePageComps(nexusDir, readFile) {
    const text = readFile(`${nexusDir}/PageCompRegistry.qml`);
    const body = text.slice(text.indexOf("pageComps:"));
    const comps = [];
    let current = null;
    for (const line of body.split("\n")) {
        if (/^        Component \{/.test(line)) {
            current = [];
            comps.push(current);
        }
        const m = /([A-Z][A-Za-z]+)\s*\{\}/.exec(line);
        if (m && current !== null)
            current.push(m[1]);
    }
    return comps;
}

function dedupCrumbs(labels, icons) {
    const outLabels = [];
    const outIcons = [];
    for (let i = 0; i < labels.length; i++) {
        if (outLabels.length > 0 && unmark(outLabels[outLabels.length - 1]) === unmark(labels[i]))
            continue;
        outLabels.push(labels[i]);
        outIcons.push(icons[i]);
    }
    return [outLabels, outIcons];
}

function buildNavMap(nexusDir, files, readFile, readLines) {
    const comps = parsePageComps(nexusDir, readFile);
    const registry = parsePageRegistry(nexusDir, readLines);

    const navChildren = {};
    for (const names of comps) {
        for (const name of names) {
            const pf = files[name];
            if (!pf)
                continue;
            let pendingIcon = null;
            let pendingLabel = null;
            let section = "";
            let expectSection = false;
            for (const ln of readLines(pf)) {
                if (SECTION_RE.test(ln)) {
                    expectSection = true;
                    continue;
                }
                const ml = LABEL_RE.exec(ln);
                if (ml) {
                    if (expectSection) {
                        section = markedMatch(ml, 1);
                        expectSection = false;
                    } else {
                        pendingLabel = markedMatch(ml, 1);
                    }
                    continue;
                }
                const mi = ICON_RE.exec(ln);
                if (mi)
                    pendingIcon = mi[1];
                const mo = /openSubPage\((\d+)\)/.exec(ln);
                if (mo) {
                    const pos = parseInt(mo[1], 10);
                    if (!navChildren[name])
                        navChildren[name] = {};
                    navChildren[name][pos] = [pendingIcon || "tune", pendingLabel || "", section];
                    pendingIcon = pendingLabel = null;
                }
            }
        }
    }

    const nav = {};
    for (let topIdx = 0; topIdx < comps.length; topIdx++) {
        const names = comps[topIdx];
        if (names.length === 0)
            continue;
        const main = names[0];
        const [mainIcon, mainLabel] = registry[topIdx] ?? ["tune", main];
        nav[main] = {
            pageIdx: topIdx,
            subPath: [],
            crumbIcons: [mainIcon],
            crumbLabels: [mainLabel]
        };
        const children = Object.assign({}, navChildren[main] ?? {});
        // Pages opened from another page are linked through it, linking them directly gives a wrong path
        const openedViaSubpage = [];
        for (const owner in navChildren) {
            const ownerGroup = comps.find(ns => ns.includes(owner));
            if (!ownerGroup)
                continue;
            for (const kpos in navChildren[owner]) {
                const k = parseInt(kpos, 10);
                if (k < ownerGroup.length)
                    openedViaSubpage.push(ownerGroup[k]);
            }
        }
        // Sub-pages opened from a file that isn't scanned (e.g. EthernetSection.qml) are linked by position
        for (let pos = 1; pos < names.length; pos++) {
            if (!(pos in children) && !openedViaSubpage.includes(names[pos])) {
                let label = names[pos].replace(/(Detail)?Page$/, "");
                label = label.replace(/([a-z])([A-Z])/g, "$1 $2");
                children[pos] = [mainIcon, label, ""];
            }
        }
        for (const posKey in children) {
            const pos = parseInt(posKey, 10);
            if (pos >= names.length)
                continue;
            const [icon, label, section] = children[posKey];
            const child = names[pos];
            let labels = [mainLabel].concat(section ? [section] : []).concat([label]);
            let icons = [mainIcon].concat(section ? [icon] : []).concat([icon]);
            [labels, icons] = dedupCrumbs(labels, icons);
            nav[child] = {
                pageIdx: topIdx,
                subPath: [pos],
                crumbIcons: icons,
                crumbLabels: labels
            };
            const grandChildren = navChildren[child] ?? {};
            for (const gposKey in grandChildren) {
                const gpos = parseInt(gposKey, 10);
                if (gpos >= names.length)
                    continue;
                const [gicon, glabel, gsection] = grandChildren[gposKey];
                let glabels = labels.concat(gsection ? [gsection] : []).concat([glabel]);
                let gicons = icons.concat(gsection ? [gicon] : []).concat([gicon]);
                [glabels, gicons] = dedupCrumbs(glabels, gicons);
                nav[names[gpos]] = {
                    pageIdx: topIdx,
                    subPath: [pos, gpos],
                    crumbIcons: gicons,
                    crumbLabels: glabels
                };
            }
        }
    }
    return nav;
}

function braceDelta(line) {
    const code = line.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/g, '""').replace(/\/\/.*$/, "");
    let delta = 0;
    for (const c of code) {
        if (c === "{")
            delta++;
        else if (c === "}")
            delta--;
    }
    return delta;
}

function extractSettings(files, nav, readLines) {
    const entries = [];
    for (const comp in nav) {
        const meta = nav[comp];
        const pf = files[comp];
        if (!pf)
            continue;
        const lines = readLines(pf);
        let section = "";
        for (let i = 0; i < lines.length; i++) {
            if (SECTION_RE.test(lines[i])) {
                for (let j = i + 1; j < Math.min(i + 4, lines.length); j++) {
                    const m = LABEL_RE.exec(lines[j]);
                    if (m) {
                        section = markedMatch(m, 1);
                        break;
                    }
                }
            }
            const rowMatch = ROW_RE.exec(lines[i]);
            if (!rowMatch)
                continue;
            const rowType = rowMatch[1];
            let label = null;
            let anchor = null;
            let subtext = null;
            let icon = null;
            let searchIcon = null;
            let checkedRoot = null;
            let checkedPath = null;
            let toggledPath = null;
            // Only the row's own bindings, nested objects are skipped
            let depth = braceDelta(lines[i]);
            for (let j = i + 1; j < lines.length && depth > 0; depth += braceDelta(lines[j]), j++) {
                if (depth > 1)
                    continue;
                if (label === null) {
                    const m = LABEL_RE.exec(lines[j]);
                    if (m)
                        label = markedMatch(m, 1);
                }
                if (anchor === null) {
                    const a = ANCHOR_RE.exec(lines[j]);
                    if (a)
                        anchor = a[1];
                }
                if (subtext === null) {
                    const st = SUBTEXT_RE.exec(lines[j]);
                    if (st)
                        subtext = markedMatch(st, 1);
                }
                if (icon === null) {
                    const ic = ICON_RE.exec(lines[j]);
                    if (ic)
                        icon = ic[1];
                }
                if (searchIcon === null) {
                    const si = SEARCH_ICON_RE.exec(lines[j]);
                    if (si)
                        searchIcon = si[1];
                }
                if (checkedPath === null) {
                    const ch = CHECKED_RE.exec(lines[j]);
                    if (ch) {
                        checkedRoot = ch[1];
                        checkedPath = ch[2];
                    }
                }
                if (toggledPath === null) {
                    const tg = ONTOGGLED_RE.exec(lines[j]);
                    if (tg)
                        toggledPath = tg[1];
                }
            }
            // Only flippable from search when checked and onToggled use the same property
            const togglePath = rowType === "ToggleRow" && checkedPath && checkedPath === toggledPath ? checkedPath : "";
            if (label && anchor) {
                entries.push({
                    rowType: rowType,
                    pageIdx: meta.pageIdx,
                    subPath: meta.subPath,
                    crumbIcons: meta.crumbIcons,
                    crumbLabels: meta.crumbLabels,
                    trailKey: meta.crumbLabels.join("/"),
                    title: label,
                    anchor: anchor,
                    section: section,
                    subtext: subtext && !/%\d/.test(unmark(subtext)) ? subtext : "",
                    togglePath: togglePath,
                    toggleGlobal: togglePath !== "" && checkedRoot === "GlobalConfig",
                    icon: searchIcon ?? icon ?? (meta.crumbIcons.length > 0 ? meta.crumbIcons[meta.crumbIcons.length - 1] : "")
                });
            }
        }
    }
    return mergeInfoRows(entries);
}

// A section's InfoRows become one entry named after the section, their labels kept as keywords.
// Each row still needs a settingAnchor to be indexed, the entry jumps to the first one.
function mergeInfoRows(entries) {
    const out = [];
    const merged = {};

    for (const entry of entries) {
        const isInfo = entry.rowType === "InfoRow";
        delete entry.rowType;

        if (!isInfo || !entry.section) {
            out.push(entry);
            continue;
        }

        const key = entry.anchor.split("-")[0] + "/" + entry.trailKey + "/" + entry.section;
        const existing = merged[key];
        if (existing === undefined) {
            entry.keywords = [entry.title];
            entry.title = entry.section;
            merged[key] = entry;
            out.push(entry);
        } else {
            existing.keywords.push(entry.title);
        }
    }
    return out;
}

function buildSearch(entries, translate) {
    const inverted = {};
    const ranking = {};
    for (let idx = 0; idx < entries.length; idx++) {
        const e = entries[idx];
        const title = cleanLabel(translate(e.title));
        const extra = e.crumbLabels.concat(e.section, e.subtext, e.keywords ?? []).filter(l => l).map(translate);
        const fields = {
            title: title,
            keywords: title + " " + extra.join(" "),
            // So the English names keep working under any language
            source: cleanLabel(unmark(e.title))
        };
        for (const field in fields) {
            const weight = FIELD_WEIGHT[field] ?? 0.2;
            for (const tok of tokenize(fields[field])) {
                if (!inverted[tok])
                    inverted[tok] = [];
                if (!inverted[tok].includes(idx))
                    inverted[tok].push(idx);
                if (!ranking[tok])
                    ranking[tok] = {};
                ranking[tok][idx] = Math.max(ranking[tok][idx] ?? 0.0, weight);
            }
        }
    }
    return {
        inverted: inverted,
        ranking: ranking
    };
}

// readFile(path) -> string ("" if unreadable), listFiles(dir, suffix) -> recursive absolute paths
function buildIndex(nexusDir, readFile, listFiles) {
    const lineCache = {};
    const readLines = path => {
        if (!(path in lineCache))
            lineCache[path] = readFile(path).split("\n");
        return lineCache[path];
    };
    const files = discoverFiles(nexusDir, listFiles);
    const nav = buildNavMap(nexusDir, files, readFile, readLines);
    const entries = extractSettings(files, nav, readLines);

    return {
        entries: entries
    };
}
