pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import Caelestia.State
import qs.services
import qs.utils
import qs.modules.nexus
import "MenuModel.js" as MenuModel

Singleton {
    id: root

    readonly property string bundledMenuDir: `${Quickshell.shellDir}/assets/menu`
    readonly property string bundledBinDir: `${bundledMenuDir}/bin`
    readonly property string userMenuDir: `${Paths.config}/menu`
    readonly property string userBinDir: `${userMenuDir}/bin`

    property var defaultTree: null
    property var userTree: null
    property var tree: null
    property bool loaded: false
    property string error: ""

    property string route: ""
    property string mode: "menu" // "menu" | "keybindings"
    property var navStack: []
    property bool pendingOpen: false

    property var conds: ({})
    property int condRevision: 0
    property var bindings: []

    property bool _condsQueued: false
    property real _lastCondRun: 0

    signal viewChanged
    signal overlayRequested(string name)

    function rebuildTree(): void {
        if (!root.defaultTree && !root.userTree)
            return;
        root.tree = MenuModel.mergeTrees(root.defaultTree, root.userTree);
        root.loaded = true;
        root.evalConds(true);
        root.viewChanged();
    }

    function scheduleCondRefresh(): void {
        condRefreshTimer.restart();
    }

    function scheduleRootReset(): void {
        rootResetTimer.restart();
    }

    function flushRootReset(): void {
        if (rootResetTimer.running) {
            rootResetTimer.stop();
            doRootReset();
        }
    }

    function doRootReset(): void {
        root.route = "";
        root.mode = "menu";
        root.navStack = [];
        root.viewChanged();
    }

    function terminalEnv(): string {
        const term = GlobalConfig.general.apps.terminal;
        if (!term || term.length === 0)
            return "";
        return term.join(" ");
    }

    function actionPath(): string {
        return `${root.userBinDir}:${root.bundledBinDir}:$PATH`;
    }

    function rootChildren(): var {
        if (!root.tree)
            return [];
        return Object.entries(root.tree).filter(([, n]) => n && n.enabled !== false).map(([id, n]) => Object.assign({
                id
            }, n));
    }

    function childrenOf(id: string): var {
        if (id === "")
            return root.rootChildren().filter(n => !n.id.includes("."));
        const prefix = `${id}.`;
        return root.rootChildren().filter(n => n.id.startsWith(prefix) && !n.id.slice(prefix.length).includes("."));
    }

    function nodeAt(path: string): var {
        const fid = path.split("/").join(".");
        const selfNode = fid !== "" && root.tree && root.tree[fid] && root.tree[fid].enabled !== false ? Object.assign({
            id: fid
        }, root.tree[fid]) : null;
        return {
            children: root.childrenOf(fid),
            self: selfNode
        };
    }

    function condPasses(cond: var): bool {
        return !cond || root.conds[cond] === true;
    }

    function isChecked(node: var): bool {
        if (node.internal === "toggle-idle")
            return RuntimeState.inhibitIdle;
        if (node.internal === "toggle-dnd")
            return !PersistentState.doNotDisturb;
        return !!node.checked && root.conds[node.checked] === true;
    }

    function isDisabled(node: var): bool {
        return !!node.disabled && root.conds[node.disabled] === true;
    }

    function breadcrumb(): string {
        if (root.mode === "keybindings")
            return Tr.tr("Keybindings");
        if (root.route === "")
            return "";
        const parts = [];
        const segs = root.route.split(".");
        for (let i = 0; i < segs.length; i++) {
            const fid = segs.slice(0, i + 1).join(".");
            const n = root.tree ? root.tree[fid] : null;
            if (!n)
                break;
            parts.push(n.title ?? n.label ?? fid);
        }
        return parts.join(" › ");
    }

    function rowsForNode(node: var, query: string, expandProvider = false): var {
        if (!root.condPasses(node.when))
            return [];

        const q = query.trim().toLowerCase();

        if (node.provider && !expandProvider && q === "") {
            return [
                {
                    type: "submenu",
                    label: node.label ?? "",
                    desc: node.desc ?? "",
                    icon: node.icon ?? "",
                    id: node.id
                }
            ];
        }

        if (node.provider) {
            switch (node.provider) {
            case "apps":
                {
                    const apps = Apps.search(q).slice().sort((a, b) => String(a.name).localeCompare(String(b.name)));
                    return apps.map(e => ({
                                type: "app",
                                entry: e,
                                icon: e.icon,
                                label: e.name ?? "",
                                desc: e.comment ?? e.genericName ?? ""
                            }));
                }
            case "schemes":
                {
                    Schemes.reload();
                    const schemes = Schemes.query(q).slice().sort((a, b) => String(a.name + a.flavour).localeCompare(String(b.name + b.flavour)));
                    return schemes.map(s => ({
                                type: "scheme",
                                label: s.flavour,
                                desc: s.name,
                                schemeName: s.name,
                                flavour: s.flavour
                            }));
                }
            case "wallpapers":
                {
                    return Wallpapers.list.filter(w => q === "" || w.name.toLowerCase().includes(q)).map(w => ({
                                type: "wallpaper",
                                label: w.name,
                                path: w.path
                            }));
                }
            }
            return [];
        }

        const hay = `${node.label ?? ""} ${(node.aliases ?? []).join(" ")} ${node.desc ?? ""}`.toLowerCase();
        const matched = q === "" || hay.includes(q) || q.split("").every(ch => hay.includes(ch));

        if (node.internal) {
            if (!matched)
                return [];
            return [
                {
                    type: "internal",
                    label: node.label ?? "",
                    desc: node.desc ?? "",
                    icon: node.icon ?? "",
                    internal: node.internal,
                    checked: root.isChecked(node),
                    toggle: !!node.toggle,
                    id: node.id
                }
            ];
        }

        const kids = root.childrenOf(node.id);
        if (kids.length > 0) {
            if (q === "") {
                return [
                    {
                        type: "submenu",
                        label: node.label ?? "",
                        desc: node.desc ?? "",
                        icon: node.icon ?? "",
                        id: node.id
                    }
                ];
            }
            const childRows = [];
            for (const c of kids)
                childRows.push(...root.rowsForNode(c, q, true));
            return childRows;
        }

        if (!matched)
            return [];

        return [
            {
                type: "item",
                label: node.label ?? "",
                desc: node.desc ?? "",
                icon: node.icon ?? "",
                action: node.action ?? "",
                checked: root.isChecked(node),
                toggle: !!node.toggle,
                disabled: root.isDisabled(node),
                id: node.id
            }
        ];
    }

    function leafToken(id: string): string {
        return (String(id).split(".").pop() ?? "").replace(/[._-]+/g, " ");
    }

    function nameText(node: var): string {
        return [node.label ?? "", leafToken(node.id), (node.aliases ?? []).join(" ")].join(" ").toLowerCase();
    }

    function baseScore(node: var, needle: string): real {
        const label = (node.label ?? "").toLowerCase();
        if (label === needle)
            return String(node.id).split(".").length > 1 ? 0 : 2;
        if (label.startsWith(needle))
            return 10;
        if (label.includes(needle))
            return 30;
        if (root.nameText(node).includes(needle))
            return 40;
        return 60;
    }

    function parentPathFor(id: string): string {
        const segs = String(id).split(".");
        if (segs.length < 2)
            return "";
        const parts = [];
        for (let i = 0; i < segs.length - 1; i++) {
            const fid = segs.slice(0, i + 1).join(".");
            const n = root.tree ? root.tree[fid] : null;
            if (!n)
                break;
            parts.push(n.title ?? n.label ?? segs[i]);
        }
        return parts.join(" › ");
    }

    function rowsFor(query: string): var {
        if (root.mode === "keybindings") {
            const q = query.trim().toLowerCase();
            return root.bindings.filter(b => q === "" || b.display.toLowerCase().includes(q)).map(b => ({
                        type: "binding",
                        label: b.display,
                        icon: "keyboard",
                        dispatcher: b.dispatcher,
                        arg: b.arg
                    }));
        }

        const needle = query.trim().toLowerCase();

        if (needle === "") {
            const node = root.nodeAt(root.route);
            if (node?.self?.provider && !(node.children?.length))
                return root.rowsForNode(node.self, "", true);
            const rows = [];
            for (const c of (node?.children ?? []))
                rows.push(...root.rowsForNode(c, ""));
            return rows;
        }

        // Interactive reminder composer: "@remind <minutes> [message]"
        const rm = query.trim().match(/^@remind(?:\s+(\d+(?:\.\d+)?))?(?:\s+(.+))?$/);
        if (rm) {
            const minutes = rm[1];
            const msg = (rm[2] ?? "").replace(/["`$\\]/g, "").trim();
            const base = {
                type: "item",
                icon: "alarm",
                checked: false,
                disabled: false,
                id: "trigger.reminder.compose"
            };
            if (!minutes) {
                return [Object.assign({}, base, {
                        label: Tr.tr("Set a reminder"),
                        desc: Tr.tr("Keep typing: @remind <minutes> <message>"),
                        disabled: true
                    })];
            }
            const dot = minutes.indexOf(".");
            const mins = dot === -1 ? parseInt(minutes, 10) : parseInt(minutes.slice(0, dot), 10);
            const secs = dot === -1 ? 0 : parseInt(minutes.slice(dot + 1), 10);
            if (secs > 59) {
                return [Object.assign({}, base, {
                        label: Tr.tr("Seconds must be below 60"),
                        desc: Tr.tr("The .%1 part is seconds, write %2.%3 instead").arg(minutes.slice(dot + 1)).arg(mins + 1).arg(secs - 60),
                        disabled: true
                    })];
            }
            const totalSeconds = mins * 60 + secs;
            if (totalSeconds === 0) {
                return [Object.assign({}, base, {
                        label: Tr.tr("Duration must be above zero"),
                        desc: "@remind <minutes> <message>",
                        disabled: true
                    })];
            }
            const duration = mins > 0 && secs > 0 ? `${mins}m ${secs}s` : mins > 0 ? `${mins}m` : `${secs}s`;
            return [Object.assign({}, base, {
                    label: msg !== "" ? Tr.tr("%1 in %2").arg(msg).arg(duration) : Tr.tr("%1 reminder").arg(duration),
                    desc: Tr.tr("Enter to set"),
                    action: `menu-reminder ${minutes}${msg !== "" ? ` ${MenuModel.shellQuote(msg)}` : ""}`
                })];
        }

        const terms = needle.split(/\s+/).filter(t => t !== "");
        const fid = root.route.split("/").join(".");
        const results = [];
        let order = 0;

        function isDirect(id: string): bool {
            if (fid === "")
                return !id.includes(".");
            return id.startsWith(`${fid}.`) && !id.slice(fid.length + 1).includes(".");
        }

        function visit(n: var): void {
            if (!root.condPasses(n.when))
                return;
            const nt = root.nameText(n);
            const descWords = (n.desc ?? "").toLowerCase().split(/\s+/).filter(w => w !== "");
            if (!terms.every(t => nt.includes(t) || descWords.includes(t)))
                return;
            const isSection = !!n.provider || root.childrenOf(n.id).length > 0;
            const s = root.baseScore(n, needle) + (isSection ? -2 : 0);
            const depth = String(n.id).split(".").length - 1;
            const path = root.parentPathFor(n.id);
            let row;
            if (n.internal) {
                row = {
                    type: "internal",
                    label: n.label ?? "",
                    desc: path,
                    icon: n.icon ?? "",
                    internal: n.internal,
                    checked: root.isChecked(n),
                    toggle: !!n.toggle,
                    id: n.id
                };
            } else if (isSection) {
                row = {
                    type: "submenu",
                    label: n.label ?? "",
                    desc: path,
                    icon: n.icon ?? "",
                    id: n.id
                };
            } else {
                row = {
                    type: "item",
                    label: n.label ?? "",
                    desc: path,
                    icon: n.icon ?? "",
                    action: n.action ?? "",
                    checked: root.isChecked(n),
                    toggle: !!n.toggle,
                    disabled: root.isDisabled(n),
                    id: n.id
                };
            }
            results.push({
                row,
                direct: isDirect(n.id),
                key: s * 1000 + depth * 25 + order
            });
            order += 1;
        }

        function walk(id: string): void {
            for (const n of root.childrenOf(id)) {
                visit(n);
                walk(n.id);
            }
        }
        walk(fid);

        const appsNode = fid === "" && root.tree ? root.tree["apps"] : null;
        if (appsNode && appsNode.enabled !== false && appsNode.provider === "apps" && root.condPasses(appsNode.when)) {
            let i = 0;
            for (const e of Apps.search(needle)) {
                const label = String(e.name ?? "").toLowerCase();
                let s = 80;
                if (label === needle || label.split(/\s+/).includes(needle))
                    s = 0;
                else if (label.startsWith(needle))
                    s = 10;
                else if (label.includes(needle))
                    s = 30;
                else
                    continue;
                results.push({
                    row: {
                        type: "app",
                        entry: e,
                        icon: e.icon,
                        label: e.name ?? "",
                        desc: e.comment ?? e.genericName ?? ""
                    },
                    direct: false,
                    key: (s - 5) * 1000 + 900 * 25 + i
                });
                i += 1;
            }
        }

        results.sort((a, b) => a.key - b.key);
        const here = results.filter(r => r.direct);
        const deeper = results.filter(r => !r.direct);
        const rowsHere = here.map(r => r.row);
        const rowsDeeper = deeper.map(r => r.row);
        if (rowsHere.length > 0 && rowsDeeper.length > 0)
            return [...rowsHere,
                {
                    type: "separator"
                },
                ...rowsDeeper];
        return rowsHere.concat(rowsDeeper);
    }

    function openRoute(path: string): void {
        root.navStack = [];
        root.route = path ? path.split("/").join(".") : "";
        root.mode = "menu";
        root.viewChanged();
    }

    function back(): bool {
        if (root.mode === "keybindings") {
            root.mode = "menu";
        } else if (root.navStack.length > 0) {
            const next = root.navStack.slice();
            root.route = next.pop() ?? "";
            root.navStack = next;
        } else if (root.route !== "") {
            const idx = root.route.lastIndexOf(".");
            root.route = idx > 0 ? root.route.slice(0, idx) : "";
        } else {
            return false;
        }
        root.viewChanged();
        return true;
    }

    function enter(row: var): void {
        switch (row?.type) {
        case "submenu":
            if (row.id !== root.route)
                root.navStack = root.navStack.concat([root.route]);
            root.route = row.id;
            root.viewChanged();
            break;
        case "internal":
            root.runInternal(row.internal);
            break;
        case "item":
            if (!row.disabled) {
                root.runAction(row.action);
                root.scheduleCondRefresh();
            }
            break;
        case "app":
            Apps.launch(row.entry);
            break;
        case "scheme":
            Quickshell.execDetached(["caelestia", "scheme", "set", "-n", row.schemeName, "-f", row.flavour]);
            break;
        case "wallpaper":
            Wallpapers.setWallpaper(row.path);
            break;
        case "binding":
            root.dispatchBinding(row);
            break;
        }
    }

    function runAction(action: string): void {
        if (!action)
            return;
        const term = MenuModel.shellQuote(root.terminalEnv());
        const shellDir = MenuModel.shellQuote(Quickshell.shellDir);
        const pathExport = `export PATH=${MenuModel.shellQuote(`${root.userBinDir}:${root.bundledBinDir}`)}:"$PATH"`;
        Quickshell.execDetached(["bash", "-c", `${pathExport}; export CAELESTIA_TERMINAL=${term}; export CAELESTIA_SHELL_DIR=${shellDir}; ${action}`]);
    }

    function runInternal(name: string): void {
        switch (name) {
        case "keybindings":
            root.mode = "keybindings";
            root.loadBindings();
            root.viewChanged();
            break;
        case "speedtest-network":
            root.overlayRequested("speedtest");
            break;
        case "speedtest-disk":
            root.overlayRequested("disktest");
            break;
        case "wifiqr":
            root.overlayRequested("wifiqr");
            break;
        case "about":
            root.runAction("menu-about");
            break;
        case "settings":
            WindowFactory.create();
            break;
        case "toggle-idle":
            RuntimeState.inhibitIdle = !RuntimeState.inhibitIdle;
            root.condRevision += 1;
            break;
        case "toggle-dnd":
            PersistentState.doNotDisturb = !PersistentState.doNotDisturb;
            root.condRevision += 1;
            break;
        case "mode-light":
            Colours.setMode("light");
            break;
        case "mode-dark":
            Colours.setMode("dark");
            break;
        case "wallpaper-random":
            Quickshell.execDetached(["caelestia", "wallpaper", "-r"]);
            break;
        case "lock":
            Quickshell.execDetached(["loginctl", "lock-session"]);
            break;
        case "suspend":
            SessionManager.suspend();
            break;
        case "hibernate":
            SessionManager.hibernate();
            break;
        case "logout":
            SessionManager.logout();
            break;
        case "reboot":
            SessionManager.reboot();
            break;
        case "shutdown":
            SessionManager.poweroff();
            break;
        }
    }

    function dispatchBinding(row: var): void {
        const d = row.dispatcher ?? "";
        const arg = row.arg ?? "";
        if (!d)
            return;
        if (d === "exec" && arg && !arg.includes(" ")) {
            Quickshell.execDetached(["bash", "-c", arg]);
            return;
        }
        const pathExport = `export PATH=${MenuModel.shellQuote(`${root.userBinDir}:${root.bundledBinDir}`)}:"$PATH"`;
        Quickshell.execDetached(["bash", "-c", `${pathExport}; exec menu-keybindings --dispatch "$1" "$2"`, "menu-dispatch", d, arg]);
    }

    function loadBindings(): void {
        const pathExport = `export PATH=${MenuModel.shellQuote(`${root.userBinDir}:${root.bundledBinDir}`)}:"$PATH"`;
        bindingProc.command = ["bash", "-c", `${pathExport}; exec menu-keybindings --records`];
        bindingProc.running = true;
    }

    function evalConds(force = false): void {
        const set = new Set();
        for (const n of root.rootChildren()) {
            if (n.when)
                set.add(n.when);
            if (n.checked)
                set.add(n.checked);
            if (n.disabled)
                set.add(n.disabled);
        }

        const conds = [...set];
        if (conds.length === 0)
            return;

        if (condProc.running) {
            root._condsQueued = true;
            return;
        }
        if (!force && Date.now() - root._lastCondRun < 5000)
            return;
        root._condsQueued = false;

        const pathExport = `export PATH=${MenuModel.shellQuote(`${root.userBinDir}:${root.bundledBinDir}`)}:"$PATH"`;
        const script = `${pathExport}\n${conds.map((c, i) => `if ${c} >/dev/null 2>&1; then printf '%s\\t%s\\n' "${i}" true; else printf '%s\\t%s\\n' "${i}" false; fi`).join("\n")}`;
        condProc.collected = "";
        condProc.command = ["bash", "-c", script];
        condProc.condList = conds;
        condProc.running = true;
    }

    Timer {
        id: rootResetTimer

        interval: 500
        onTriggered: root.doRootReset()
    }

    Timer {
        id: condRefreshTimer

        interval: 300
        onTriggered: root.evalConds(true)
    }

    FileView {
        id: bundledMenuFile

        path: `${root.bundledMenuDir}/menu.jsonc`
        watchChanges: true
        printErrors: false

        onLoaded: {
            try {
                root.defaultTree = MenuModel.parseJsonc(text());
                root.error = "";
                root.rebuildTree();
            } catch (e) {
                root.error = e.message ?? String(e);
                console.warn("MenuService: failed to parse bundled menu.jsonc:", e);
            }
        }

        onLoadFailed: err => {
            if (!root.userTree) {
                root.error = Tr.tr("Could not read menu.jsonc (%1)").arg(err);
                console.warn("MenuService:", root.error);
            }
        }

        onFileChanged: reload()
    }

    FileView {
        id: userMenuFile

        path: `${root.userMenuDir}/menu.jsonc`
        watchChanges: true
        printErrors: false

        onLoaded: {
            try {
                root.userTree = MenuModel.parseJsonc(text());
                root.error = "";
                root.rebuildTree();
            } catch (e) {
                root.error = e.message ?? String(e);
                console.warn("MenuService: failed to parse user menu.jsonc:", e);
            }
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.userTree = null;
                root.rebuildTree();
            }
        }

        onFileChanged: reload()
    }

    Process {
        id: condProc

        property var condList: []
        property string collected: ""

        stdout: SplitParser {
            onRead: data => condProc.collected += data + "\n"
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                if (root._condsQueued)
                    root.evalConds(true);
                return;
            }
            const map = {};
            const lines = condProc.collected.split("\n");
            for (let i = 0; i < lines.length; i++) {
                const fields = lines[i].split("\t");
                if (fields.length < 2)
                    continue;
                map[condProc.condList[Number(fields[0])]] = fields[1].trim() === "true";
            }
            root.conds = map;
            root.condRevision += 1;
            root._lastCondRun = Date.now();
            condProc.collected = "";
            if (root._condsQueued)
                root.evalConds(true);
        }
    }

    Process {
        id: bindingProc

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split("\t");
                    if (parts.length < 3)
                        continue;
                    rows.push({
                        display: parts[0],
                        dispatcher: parts[1],
                        arg: parts.slice(2).join("\t")
                    });
                }
                root.bindings = rows;
                root.viewChanged();
            }
        }
    }
}
