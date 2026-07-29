// Builds the settings search index by parsing the nexus page QML sources at
// runtime. This is the same logic the old build-time script
// (scripts/build-settings-index.py) ran, moved into the shell so the index is
// created on first use and cached, instead of being baked into the plugin at
// build time. IO is injected (readFile/listFiles) so the module stays a pure
// library - testable outside the shell.
.pragma library

// The Material Symbols icon shown on each setting's search-result card, keyed
// by its anchor. Hand-picked so every setting reads at a glance and none just
// repeats its page's icon; anything unmapped (e.g. a newly added setting)
// falls back to the deepest breadcrumb icon.
const SETTING_ICONS = {
    "style-display-wallpaper": "wallpaper",
    "style-transparency": "opacity",
    "style-dark-theme": "dark_mode",
    "network-wi-fi": "network_wifi",
    "ethernet-status": "link",
    "ethernet-interface": "settings_ethernet",
    "ethernet-speed": "speed",
    "ethernet-ip-address": "tag",
    "ethernet-gateway": "router",
    "ethernet-mac-address": "fingerprint",
    "ethernet-ip-assignment": "tune",
    "bluetooth-bluetooth": "bluetooth_connected",
    "bluetooth-discoverable": "visibility",
    "bluetooth-pairable": "add_link",
    "audio-output": "speaker",
    "audio-input": "mic",
    "panels-dashboard": "space_dashboard",
    "panels-taskbar": "toolbar",
    "panels-launcher": "apps",
    "panels-sidebar": "view_sidebar",
    "dash-enabled": "toggle_on",
    "dash-show-on-hover": "mouse",
    "dash-dashboard": "tab",
    "dash-media": "play_circle",
    "dash-performance": "speed",
    "dash-weather": "partly_cloudy_day",
    "dash-battery": "battery_full",
    "dash-gpu": "developer_board",
    "dash-cpu": "memory",
    "dash-memory": "memory_alt",
    "dash-storage": "hard_drive",
    "dash-network": "network_check",
    "dash-drag-threshold": "drag_pan",
    "taskbar-persistent": "push_pin",
    "taskbar-show-on-hover": "mouse",
    "taskbar-drag-threshold": "drag_pan",
    "taskbar-workspaces": "workspaces",
    "taskbar-active-window": "select_window",
    "taskbar-tray": "widgets",
    "taskbar-status-icons": "instant_mix",
    "taskbar-clock": "schedule",
    "taskbar-workspaces-2": "swipe",
    "taskbar-volume": "volume_up",
    "taskbar-brightness": "brightness_6",
    "bar-ws-shown": "format_list_numbered",
    "bar-ws-active-indicator": "radio_button_checked",
    "bar-ws-active-trail": "gesture",
    "bar-ws-occupied-background": "layers",
    "bar-ws-show-windows": "grid_view",
    "bar-ws-windows-on-special-workspaces": "star",
    "bar-ws-max-window-icons": "filter_9_plus",
    "bar-ws-per-monitor-workspaces": "desktop_windows",
    "bar-aw-compact": "compress",
    "bar-aw-inverted": "invert_colors",
    "bar-aw-show-on-hover": "mouse",
    "bar-aw-popout-on-hover": "open_in_new",
    "bar-tray-background": "format_color_fill",
    "bar-tray-recolour-icons": "format_paint",
    "bar-tray-compact": "compress",
    "bar-tray-popout-on-hover": "open_in_new",
    "bar-si-speakers": "speaker",
    "bar-si-microphone": "mic",
    "bar-si-keyboard-layout": "keyboard",
    "bar-si-network": "lan",
    "bar-si-wi-fi": "network_wifi",
    "bar-si-bluetooth": "bluetooth",
    "bar-si-battery": "battery_full",
    "bar-si-caps-lock": "keyboard_capslock_badge",
    "bar-si-popout-on-hover": "open_in_new",
    "bar-clock-background": "format_color_fill",
    "bar-clock-show-date": "calendar_month",
    "bar-clock-show-icon": "visibility",
    "launcher-enabled": "toggle_on",
    "launcher-show-on-hover": "mouse",
    "launcher-max-items-shown": "format_list_numbered",
    "launcher-max-wallpapers": "photo_library",
    "launcher-drag-threshold": "drag_pan",
    "launcher-vim-keybinds": "keyboard_command_key",
    "launcher-enable-dangerous-actions": "warning",
    "launcher-apps": "grid_view",
    "launcher-actions": "bolt",
    "launcher-schemes": "palette",
    "launcher-variants": "contrast",
    "launcher-wallpapers": "wallpaper",
    "sidebar-enabled": "toggle_on",
    "sidebar-drag-threshold": "drag_pan",
    "apps-default-terminal": "terminal",
    "apps-default-audio": "music_note",
    "apps-default-playback": "play_circle",
    "apps-default-file-manager": "folder",
    "apps-all-apps": "view_apps",
    "services-notifications": "notifications",
    "services-media-refresh": "autorenew",
    "services-system-stats-refresh": "monitoring",
    "services-wi-fi-rescan": "wifi_find",
    "services-lyrics-backend": "lyrics",
    "services-default-player": "queue_music",
    "services-volume-step": "volume_up",
    "services-brightness-step": "brightness_6",
    "services-max-volume": "vertical_align_top",
    "services-visualiser-bars": "graphic_eq",
    "services-smart-colour-scheme": "auto_awesome",
    "services-gpu": "developer_board",
    "notif-show-in-fullscreen": "fullscreen",
    "notif-expire-automatically": "auto_delete",
    "notif-open-expanded": "unfold_more",
    "notif-default-timeout": "timer",
    "notif-group-preview-count": "stacks",
    "notif-show-in-fullscreen-2": "fullscreen",
    "notif-visible-toasts": "filter_9_plus",
    "notif-charging-changes": "battery_charging_full",
    "notif-game-mode-changes": "sports_esports",
    "notif-do-not-disturb-changes": "do_not_disturb_on",
    "notif-audio-output-changes": "speaker",
    "notif-audio-input-changes": "mic",
    "notif-caps-lock-changes": "keyboard_capslock_badge",
    "notif-num-lock-changes": "looks_one",
    "notif-keyboard-layout-changes": "keyboard",
    "notif-vpn-changes": "vpn_key",
    "notif-now-playing": "play_circle",
    "lang-temperature": "thermostat",
    "lang-system-temperatures": "device_thermostat",
    "lang-clock-format": "schedule"
};

const STOPWORDS = ["a", "an", "and", "are", "for", "in", "not", "notification", "of", "on", "or", "out", "the", "to"];

const FIELD_WEIGHT = {
    title: 1.0,
    keywords: 0.4
};
const SKIP_LABELS = ["Muted", "None"];

const ROW_RE = /^\s*(ToggleRow|SliderRow|SelectRow|StepperRow|NavRow|InfoRow|PopupRow|DefaultRow)\s*\{/;
const LABEL_RE = /^\s*(?:label|text):\s*qsTr\("([^"]+)"\)/;
const ANCHOR_RE = /^\s*settingAnchor:\s*"([^"]+)"/;
// A ToggleRow whose value is a plain config property can be flipped straight
// from the search results. We capture the property path from `checked:` and
// require `onToggled:` to write the same path back (a symmetric binding), so
// reading and writing go through one path. Toggles bound to functions or
// multi-line handlers are left without a path and just deep-link as usual.
const CHECKED_RE = /^\s*checked:\s*(?:GlobalConfig|Config)\.([\w.]+)\s*$/;
const ONTOGGLED_RE = /^\s*onToggled:\s*(?:GlobalConfig|Config)\.([\w.]+)\s*=\s*checked\s*$/;
const ICON_RE = /^\s*icon:\s*"([^"]+)"/;
const SUBTEXT_RE = /^\s*(?:subtext|status):\s*qsTr\("([^"]+)"\)/;
const SECTION_RE = /^\s*SectionHeader\s*\{/;

function tokenize(text) {
    const toks = [];
    // Process word by word (split on whitespace) so we only collapse separators
    // inside a single word like "Wi-Fi" -> "wifi", not across a whole phrase.
    for (const word of text.toLowerCase().split(/\s+/)) {
        if (!word)
            continue;
        const parts = word.split(/[^a-z0-9]+/).filter(p => p);
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

// component name -> file path, discovered by walking pages/.
function discoverFiles(nexusDir, listFiles) {
    const files = {};
    for (const p of listFiles(`${nexusDir}/pages`, ".qml")) {
        const name = p.slice(p.lastIndexOf("/") + 1).replace(/\.qml$/, "");
        files[name] = p;
    }
    return files;
}

// Ordered [icon, label] for each *active* page entry in PageRegistry.
// Commented-out entries are ignored, matching pageComps ordering.
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
                label = m[1];
            const mi = ICON_RE.exec(line);
            if (mi && icon === null)
                icon = mi[1];
        }
    }
    return out;
}

// Per top-level pageComps entry, ordered component names inside it.
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

// Drop consecutive duplicate labels (e.g. a section header that repeats the
// page name), keeping icons aligned.
function dedupCrumbs(labels, icons) {
    const outLabels = [];
    const outIcons = [];
    for (let i = 0; i < labels.length; i++) {
        if (outLabels.length > 0 && outLabels[outLabels.length - 1] === labels[i])
            continue;
        outLabels.push(labels[i]);
        outIcons.push(icons[i]);
    }
    return [outLabels, outIcons];
}

function buildNavMap(nexusDir, files, readFile, readLines) {
    const comps = parsePageComps(nexusDir, readFile);
    const registry = parsePageRegistry(nexusDir, readLines);

    // parentName -> {childPos: [icon, label, section]} from openSubPage() +
    // nearby NavRow, remembering the section header the NavRow sits under.
    const navChildren = {};
    for (const names of comps) {
        for (const name of names) {
            const pf = files[name];
            if (!pf)
                continue;
            let pendingIcon = null;
            let pendingLabel = null;
            let section = ""; // text of the most recent SectionHeader
            let expectSection = false; // next label line is that header's text
            for (const ln of readLines(pf)) {
                if (SECTION_RE.test(ln)) {
                    expectSection = true;
                    continue;
                }
                const ml = LABEL_RE.exec(ln);
                if (ml) {
                    if (expectSection) {
                        section = ml[1];
                        expectSection = false;
                    } else {
                        pendingLabel = ml[1];
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
        // Components that some other page opens via openSubPage. Those are
        // reached through that page (e.g. the bar pages are opened from inside
        // Taskbar's "Components" section), so they must not be linked directly
        // here, which would give them a wrong, shorter breadcrumb and path.
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
        // Fallback: a StackPage may list sub-pages (pos > 0) whose openSubPage()
        // call lives in a separate component file we don't scan (e.g. the
        // Ethernet detail page is opened from EthernetSection.qml). Link any
        // such sub-page by its position, deriving a label from its component
        // name - but skip ones already reached through another page.
        for (let pos = 1; pos < names.length; pos++) {
            if (!(pos in children) && !openedViaSubpage.includes(names[pos])) {
                let label = names[pos].replace(/(Detail)?Page$/, "");
                label = label.replace(/(?<!^)(?=[A-Z])/g, " ");
                children[pos] = [mainIcon, label, ""];
            }
        }
        for (const posKey in children) {
            const pos = parseInt(posKey, 10);
            if (pos >= names.length)
                continue;
            const [icon, label, section] = children[posKey];
            const child = names[pos];
            // Insert the section header (e.g. "Components") as a breadcrumb
            // step between the parent page and the sub-page, when present.
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

function extractSettings(files, nav, readLines) {
    const entries = [];
    for (const comp in nav) {
        const meta = nav[comp];
        const pf = files[comp];
        if (!pf)
            continue;
        const lines = readLines(pf);
        let section = ""; // text of the most recent SectionHeader
        for (let i = 0; i < lines.length; i++) {
            // Track the current section header so its words are searchable too.
            if (SECTION_RE.test(lines[i])) {
                for (let j = i + 1; j < Math.min(i + 4, lines.length); j++) {
                    const m = LABEL_RE.exec(lines[j]);
                    if (m) {
                        section = m[1];
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
            let checkedPath = null;
            let toggledPath = null;
            for (let j = i + 1; j < Math.min(i + 12, lines.length); j++) {
                if (label === null) {
                    const m = LABEL_RE.exec(lines[j]);
                    if (m)
                        label = m[1];
                }
                if (anchor === null) {
                    const a = ANCHOR_RE.exec(lines[j]);
                    if (a)
                        anchor = a[1];
                }
                if (subtext === null) {
                    const st = SUBTEXT_RE.exec(lines[j]);
                    if (st)
                        subtext = st[1];
                }
                if (checkedPath === null) {
                    const ch = CHECKED_RE.exec(lines[j]);
                    if (ch)
                        checkedPath = ch[1];
                }
                if (toggledPath === null) {
                    const tg = ONTOGGLED_RE.exec(lines[j]);
                    if (tg)
                        toggledPath = tg[1];
                }
            }
            // Only expose a toggle path when read and write target the same
            // property (symmetric), so flipping from search is safe.
            const togglePath = rowType === "ToggleRow" && checkedPath && checkedPath === toggledPath ? checkedPath : "";
            if (label && !SKIP_LABELS.includes(label) && anchor) {
                // keyword sources: breadcrumb path, section header, subtext.
                const extra = meta.crumbLabels.join(" ") + " " + section + " " + (subtext ?? "");
                entries.push({
                    pageIdx: meta.pageIdx,
                    subPath: meta.subPath,
                    crumbIcons: meta.crumbIcons,
                    crumbLabels: meta.crumbLabels,
                    title: label,
                    anchor: anchor,
                    section: section,
                    subtext: subtext ?? "",
                    togglePath: togglePath,
                    icon: SETTING_ICONS[anchor] ?? (meta.crumbIcons.length > 0 ? meta.crumbIcons[meta.crumbIcons.length - 1] : "")
                });
            }
        }
    }
    return entries;
}

// Classic inverted index + precomputed per-token ranking weights. Keywords are
// tokenised on the fly here rather than stored on the entries.
function buildInvertedAndRanking(entries) {
    const inverted = {};
    const ranking = {};
    for (let idx = 0; idx < entries.length; idx++) {
        const e = entries[idx];
        const extra = e.crumbLabels.join(" ") + " " + e.section + " " + e.subtext;
        const fields = {
            title: e.title,
            keywords: tokenize(e.title + " " + extra).sort().join(" ")
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
    // sort each posting list by descending rank so runtime can stop early
    for (const tok in inverted)
        inverted[tok].sort((a, b) => ranking[tok][b] - ranking[tok][a]);
    return [inverted, ranking];
}

// Builds the whole index. readFile(path) -> string ("" if unreadable);
// listFiles(dir, suffix) -> recursive absolute paths.
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
    const [inverted, ranking] = buildInvertedAndRanking(entries);
    return {
        version: 3,
        entries: entries,
        inverted: inverted,
        ranking: ranking
    };
}
