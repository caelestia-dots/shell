pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Caelestia.Config
import qs.services
import qs.modules.launcher.services

Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.activities.enabled
    property bool overviewOpen: false
    property Item overviewDragLayer: null
    property int overviewDropTargetWs: -1
    property var overviewCards: []
    property string rulesPath: `${Quickshell.env("HOME")}/.config/hypr/caelestia-activity-rules.lua`

    readonly property var mappedActivities: {
        const list = [];
        let next = 1;
        const values = GlobalConfig.activities.activities.values;
        for (let i = 0; i < values.length; i++) {
            const a = values[i];
            const count = Math.max(1, a.workspaceCount || 1);
            const ids = [];
            for (let w = 0; w < count; w++)
                ids.push(next + w);
            list.push({
                id: a.id || `activity-${i}`,
                name: a.name || a.id || `Activity ${i + 1}`,
                icon: a.icon || "home",
                workspaceCount: count,
                startWs: next,
                endWs: next + count - 1,
                workspaceIds: ids,
                index: i
            });
            next += count;
        }
        return list;
    }

    readonly property int totalWorkspaces: {
        const acts = root.mappedActivities;
        if (acts.length === 0)
            return 0;
        return acts[acts.length - 1].endWs;
    }

    readonly property int activeWsId: Hyprland.focusedWorkspace?.id ?? 1

    readonly property var currentActivity: {
        const ws = root.activeWsId;
        return root.mappedActivities.find(a => ws >= a.startWs && ws <= a.endWs) ?? root.mappedActivities[0] ?? null;
    }

    readonly property int currentActivityIndex: root.currentActivity?.index ?? 0

    readonly property string principalId: "principal"
    property string lastStyleActivityId: ""
    property string lastAppliedStyleKey: ""
    // Bumped when any activity look field changes so UI bindings refresh
    property int styleRevision: 0
    // Serial style apply: wallpaper then scheme set must not race (wallpaper
    // --no-smart keeps the previous mode and can overwrite a concurrent setMode).
    property int styleApplyGen: 0
    property int pendingLightApps: -1
    property int pendingTransparency: -1
    property string pendingVerifyMode: ""
    readonly property string styleCli: Quickshell.shellPath("scripts/apply-activity-style.py")

    function bumpStyleRevision(): void {
        root.styleRevision++;
    }

    function activityById(id: string): var {
        return root.mappedActivities.find(a => a.id === id) ?? null;
    }

    function activityEntry(id: string): var {
        const values = GlobalConfig.activities.activities.values;
        for (let i = 0; i < values.length; i++) {
            if ((values[i].id || "") === id)
                return values[i];
        }
        return null;
    }

    function principalEntry(): var {
        return root.activityEntry(root.principalId);
    }

    function pickStr(primary: string, fallback: string, lastResort: string): string {
        if (primary)
            return primary;
        if (fallback)
            return fallback;
        return lastResort || "";
    }

    function pickTri(primary: int, fallback: int, lastResort: int): int {
        if (primary >= 0)
            return primary;
        if (fallback >= 0)
            return fallback;
        return lastResort;
    }

    function resolveStyle(activityId: string): var {
        const principal = root.principalEntry();
        const targetId = activityId || root.principalId;
        const entry = root.activityEntry(targetId);
        const p = principal || {};
        const a = entry || {};
        const wallFallback = Wallpapers.actualCurrent || Wallpapers.fallback || "";
        const modeFallback = Colours.currentLight ? "light" : "dark";
        return {
            wallpaper: root.pickStr(a.wallpaper || "", p.wallpaper || "", wallFallback),
            scheme: root.pickStr(a.scheme || "", p.scheme || "", Colours.scheme || "dynamic"),
            flavour: root.pickStr(a.flavour || "", p.flavour || "", Colours.flavour || "default"),
            variant: root.pickStr(a.variant || "", p.variant || "", Colours.variant || ""),
            mode: root.pickStr(a.mode || "", p.mode || "", modeFallback),
            transparency: root.pickTri(a.transparency ?? -1, p.transparency ?? -1, GlobalConfig.appearance.transparency.enabled ? 1 : 0),
            lightApps: root.pickTri(a.lightApps ?? -1, p.lightApps ?? -1, Colours.lightApps ? 1 : 0)
        };
    }

    function ensurePrincipalStyle(): void {
        const p = root.principalEntry();
        if (!p)
            return;
        if (!(p.wallpaper || ""))
            p.wallpaper = Wallpapers.actualCurrent || Wallpapers.fallback || "";
        if (!(p.scheme || ""))
            p.scheme = Colours.scheme || "dynamic";
        if (!(p.flavour || ""))
            p.flavour = Colours.flavour || "default";
        if (!(p.variant || "") && (Colours.variant || ""))
            p.variant = Colours.variant;
        if (!(p.mode || ""))
            p.mode = Colours.currentLight ? "light" : "dark";
        if ((p.transparency ?? -1) < 0)
            p.transparency = GlobalConfig.appearance.transparency.enabled ? 1 : 0;
        if ((p.lightApps ?? -1) < 0)
            p.lightApps = Colours.lightApps ? 1 : 0;
    }

    function styleKey(style: var): string {
        return [style.wallpaper, style.scheme, style.flavour, style.variant, style.mode, style.transparency, style.lightApps].join("\x1f");
    }

    function finishPendingStyleExtras(): void {
        if (root.pendingLightApps >= 0) {
            const want = root.pendingLightApps > 0;
            // Scheme already applied with the activity mode — do not re-set mode.
            // Always run setLightApps when enabling so prefer-light / Qt skip apply
            // even if the flag was already true from a previous activity.
            if (want !== Colours.lightApps || !Colours.lightAppsLoaded)
                Colours.setLightApps(want, false);
            else if (want)
                Colours.applyAppTheme();
            root.pendingLightApps = -1;
        }
        if (root.pendingTransparency >= 0) {
            const wantTr = root.pendingTransparency > 0;
            if (wantTr !== GlobalConfig.appearance.transparency.enabled)
                GlobalConfig.appearance.transparency.enabled = wantTr;
            root.pendingTransparency = -1;
        }
    }

    function onStyleApplyFinished(gen: int): void {
        // Ignore stale exits from a cancelled Process (gen property may already
        // have been bumped for the replacement run).
        if (gen !== root.styleApplyGen || styleApplyProc.running)
            return;
        root.finishPendingStyleExtras();
        styleVerifyTimer.restart();
    }

    function applyStyleForActivity(activityId: string): void {
        root.ensurePrincipalStyle();
        const id = root.enabled ? (activityId || root.currentActivity?.id || root.principalId) : root.principalId;
        const style = root.resolveStyle(id);
        const key = root.styleKey(style);
        if (key === root.lastAppliedStyleKey)
            return;
        root.lastAppliedStyleKey = key;
        root.lastStyleActivityId = id;

        const wallpaperChanged = !!(style.wallpaper && style.wallpaper !== Wallpapers.actualCurrent);
        const schemeNow = `${Colours.scheme} ${Colours.flavour}`;
        const schemeWant = `${style.scheme} ${style.flavour}`;
        const modeMismatch = !!(style.mode && (style.mode === "light") !== Colours.currentLight);
        const variantMismatch = !!(style.variant && style.variant !== Colours.variant);
        const schemeMismatch = !!(style.scheme && schemeWant !== schemeNow);
        // Wallpaper file change must regenerate dynamic colours with the activity mode.
        const needScheme = wallpaperChanged || schemeMismatch || variantMismatch || modeMismatch;

        root.pendingLightApps = style.lightApps;
        root.pendingTransparency = style.transparency;
        root.pendingVerifyMode = style.mode || "";

        if (!wallpaperChanged && !needScheme) {
            root.finishPendingStyleExtras();
            return;
        }

        root.styleApplyGen++;
        const gen = root.styleApplyGen;
        // Single Python process: wallpaper files (no colour apply) + one scheme apply.
        const cmd = ["python3", root.styleCli];
        if (wallpaperChanged) {
            Wallpapers.actualCurrent = style.wallpaper;
            cmd.push("--wallpaper", style.wallpaper);
        }
        if (needScheme || wallpaperChanged) {
            if (style.scheme)
                cmd.push("--name", style.scheme);
            if (style.flavour)
                cmd.push("--flavour", style.flavour);
            if (style.mode)
                cmd.push("--mode", style.mode);
            if (style.variant)
                cmd.push("--variant", style.variant);
        }

        if (styleApplyProc.running)
            styleApplyProc.running = false;
        styleApplyProc.gen = gen;
        styleApplyProc.command = cmd;
        styleApplyProc.running = true;
    }

    function applyCurrentStyleSoon(): void {
        styleApplyTimer.restart();
    }

    function styleTargetId(): string {
        return root.enabled ? (root.currentActivity?.id || root.principalId) : root.principalId;
    }

    function shouldApplyFor(activityId: string): bool {
        return (activityId || "") === root.styleTargetId();
    }

    // Re-resolve and apply the focused activity's look (covers Principal edits
    // that activities inherit without switching workspace).
    function refreshLiveStyle(): void {
        root.bumpStyleRevision();
        root.lastAppliedStyleKey = "";
        root.applyStyleForActivity(root.styleTargetId());
    }

    function setActivityWallpaper(activityId: string, path: string): void {
        const entry = root.activityEntry(activityId);
        if (!entry || !path)
            return;
        entry.wallpaper = path;
        root.refreshLiveStyle();
    }

    function setActivityScheme(activityId: string, name: string, flavour: string): void {
        const entry = root.activityEntry(activityId);
        if (!entry || !name)
            return;
        entry.scheme = name;
        entry.flavour = flavour || "default";
        root.refreshLiveStyle();
    }

    function setActivityVariant(activityId: string, variant: string): void {
        const entry = root.activityEntry(activityId);
        if (!entry)
            return;
        entry.variant = variant || "";
        root.refreshLiveStyle();
    }

    function setActivityMode(activityId: string, mode: string): void {
        const entry = root.activityEntry(activityId);
        if (!entry)
            return;
        entry.mode = mode === "light" ? "light" : "dark";
        root.refreshLiveStyle();
    }

    function setActivityLightApps(activityId: string, enabled: bool): void {
        const entry = root.activityEntry(activityId);
        if (!entry)
            return;
        entry.lightApps = enabled ? 1 : 0;
        root.refreshLiveStyle();
    }

    function setActivityTransparency(activityId: string, enabled: bool): void {
        const entry = root.activityEntry(activityId);
        if (!entry)
            return;
        entry.transparency = enabled ? 1 : 0;
        root.refreshLiveStyle();
    }

    function clearActivityStyle(activityId: string): void {
        if (!activityId || activityId === root.principalId)
            return;
        const entry = root.activityEntry(activityId);
        if (!entry)
            return;
        entry.wallpaper = "";
        entry.scheme = "";
        entry.flavour = "";
        entry.variant = "";
        entry.mode = "";
        entry.transparency = -1;
        entry.lightApps = -1;
        root.refreshLiveStyle();
    }

    function activityHasStyleOverride(activityId: string): bool {
        if (!activityId || activityId === root.principalId)
            return false;
        const a = root.activityEntry(activityId);
        if (!a)
            return false;
        return !!(a.wallpaper || a.scheme || a.flavour || a.variant || a.mode || (a.transparency ?? -1) >= 0 || (a.lightApps ?? -1) >= 0);
    }

    function workspaceForRule(rule: var): int {
        const act = root.activityById(rule.activityId);
        if (!act)
            return 1;
        const idx = Math.max(0, Math.min(act.workspaceCount - 1, rule.workspaceIndex || 0));
        return act.workspaceIds[idx];
    }

    function classMatches(cls: string, match: string): bool {
        const m = (match || "").trim();
        if (!m || !cls)
            return false;
        if (m.startsWith("^")) {
            try {
                return new RegExp(m).test(cls);
            } catch (e) {
                return false;
            }
        }
        return cls.toLowerCase() === m.toLowerCase();
    }

    function ruleForWindowClass(cls: string): var {
        const rules = GlobalConfig.activities.appRules.values;
        for (let i = 0; i < rules.length; i++) {
            const rule = rules[i];
            if (root.classMatches(cls, rule.classMatch || ""))
                return rule;
        }
        return null;
    }

    function isWindowPinned(toplevel: var): bool {
        const cls = toplevel?.lastIpcObject?.class ?? "";
        return !!root.ruleForWindowClass(cls);
    }

    function moveWindowToWorkspace(toplevel: var, ws: int): void {
        if (!toplevel || !ws)
            return;
        if (root.isWindowPinned(toplevel))
            return;
        const cur = toplevel.workspace?.id ?? -1;
        if (cur === ws)
            return;
        const addr = toplevel.address;
        if (!addr)
            return;
        Hyprland.dispatch(`hl.dsp.window.move({ window = "address:0x${addr}", workspace = "${ws}", follow = false })`);
    }

    function moveOpenWindowsForRule(rule: var): void {
        if (!root.enabled || !rule)
            return;
        const match = (rule.classMatch || "").trim();
        if (!match)
            return;
        const ws = root.workspaceForRule(rule);
        const tops = Hyprland.toplevels.values;
        for (let i = 0; i < tops.length; i++) {
            const t = tops[i];
            const cls = t.lastIpcObject?.class ?? "";
            if (!root.classMatches(cls, match))
                continue;
            root.moveWindowToWorkspace(t, ws);
        }
    }

    function enforceOpenWindows(): void {
        if (!root.enabled)
            return;
        const rules = GlobalConfig.activities.appRules.values;
        for (let i = 0; i < rules.length; i++)
            root.moveOpenWindowsForRule(rules[i]);
    }

    function focusActivityByOffset(offset: int): void {
        if (!root.enabled || root.mappedActivities.length === 0)
            return;
        const n = root.mappedActivities.length;
        let idx = root.currentActivityIndex + offset;
        idx = ((idx % n) + n) % n;
        root.focusActivity(root.mappedActivities[idx].id);
    }

    function focusWorkspace(ws: int): void {
        // Hyprland-lua expects dsp expressions; classic syntax still works for non-lua
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${ws} })`);
    }

    function focusActivity(activityId: string): void {
        const act = root.activityById(activityId);
        if (!act)
            return;
        root.focusWorkspace(act.startWs);
    }

    function focusWorkspaceInActivity(activityId: string, workspaceIndex: int): void {
        const act = root.activityById(activityId);
        if (!act)
            return;
        const idx = Math.max(0, Math.min(act.workspaceCount - 1, workspaceIndex));
        root.focusWorkspace(act.workspaceIds[idx]);
    }

    function focusNextInActivity(delta: int): void {
        if (!root.enabled || !root.currentActivity)
            return;
        const act = root.currentActivity;
        const local = root.activeWsId - act.startWs;
        const next = local + delta;
        if (next >= 0 && next < act.workspaceCount) {
            root.focusWorkspace(act.workspaceIds[next]);
            return;
        }
        // At activity edge: stay put unless cross-activity workspace cycling is enabled
        if (!GlobalConfig.activities.crossActivityWorkspaces)
            return;
        const acts = root.mappedActivities;
        const idx = root.currentActivityIndex;
        if (delta > 0) {
            if (idx + 1 < acts.length)
                root.focusWorkspace(acts[idx + 1].workspaceIds[0]);
        } else if (idx > 0) {
            const prev = acts[idx - 1];
            root.focusWorkspace(prev.workspaceIds[prev.workspaceCount - 1]);
        }
    }

    function focusWorkspaceByOffset(delta: int): void {
        if (root.enabled)
            root.focusNextInActivity(delta);
        else
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "e${delta > 0 ? "+" : "-"}${Math.abs(delta)}" })`);
    }

    function toggleOverview(): void {
        if (!root.enabled)
            return;
        root.overviewOpen = !root.overviewOpen;
    }

    function closeOverview(): void {
        root.overviewOpen = false;
    }

    function selectWorkspace(ws: int): void {
        root.focusWorkspace(ws);
        root.closeOverview();
    }

    function registerOverviewCard(card: var): void {
        if (!card || root.overviewCards.includes(card))
            return;
        root.overviewCards = [...root.overviewCards, card];
    }

    function unregisterOverviewCard(card: var): void {
        root.overviewCards = root.overviewCards.filter(c => c !== card);
    }

    function hitTestOverviewWorkspace(globalPos: point): int {
        const cards = root.overviewCards;
        for (let i = 0; i < cards.length; i++) {
            const card = cards[i];
            if (!card)
                continue;
            try {
                if (card.containsDragPoint && card.containsDragPoint(globalPos))
                    return card.wsId;
            } catch (e) {}
        }
        return -1;
    }

    function finishWindowDrag(toplevel: var): void {
        const target = root.overviewDropTargetWs;
        root.overviewDropTargetWs = -1;
        if (!toplevel || target < 1)
            return;
        if (root.isWindowPinned(toplevel))
            return;
        root.moveWindowToWorkspace(toplevel, target);
        // Defer focus so Hyprland can apply the move first
        Qt.callLater(() => root.selectWorkspace(target));
    }

    onOverviewOpenChanged: {
        if (!root.overviewOpen) {
            root.overviewDropTargetWs = -1;
            root.overviewCards = [];
        }
    }

    function escapeLuaString(s: string): string {
        return (s || "").replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    }

    function escapeLuaPattern(s: string): string {
        // Treat classMatch as literal class unless user starts with ^
        const raw = s || "";
        if (raw.startsWith("^"))
            return root.escapeLuaString(raw);
        const escaped = raw.replace(/([%^$()%.\[\]*+\-?])/g, "%%%1");
        return root.escapeLuaString(`^${escaped}$`);
    }

    function generateRulesLua(): string {
        let out = "-- Auto-generated by Caelestia Activities. Do not edit.\n\n";

        const total = Math.max(1, root.totalWorkspaces);
        for (let i = 1; i <= total; i++)
            out += `hl.workspace_rule({ workspace = "${i}", persistent = true })\n`;

        out += "\n";

        const rules = GlobalConfig.activities.appRules.values;
        for (let i = 0; i < rules.length; i++) {
            const rule = rules[i];
            const cls = (rule.classMatch || "").trim();
            if (!cls)
                continue;
            const ws = root.workspaceForRule(rule);
            const name = `caelestia-activity-${i}-${root.escapeLuaString(cls).replace(/[^a-zA-Z0-9_-]/g, "_")}`;
            out += `hl.window_rule({\n`;
            out += `    name = "${name}",\n`;
            out += `    match = { class = "${root.escapeLuaPattern(cls)}" },\n`;
            out += `    workspace = "${ws}",\n`;
            out += `})\n`;
        }

        return out;
    }

    function applyRules(): void {
        if (!root.enabled) {
            rulesFile.setText("-- Auto-generated by Caelestia Activities (disabled).\n");
            Quickshell.execDetached(["hyprctl", "reload"]);
            return;
        }
        rulesFile.setText(root.generateRulesLua());
        Quickshell.execDetached(["hyprctl", "reload"]);
        enforceTimer.restart();
    }

    function syncSoon(): void {
        syncTimer.restart();
    }

    function ensurePrincipal(): void {
        const list = GlobalConfig.activities.activities;
        const values = list.values;
        for (let i = 0; i < values.length; i++) {
            if ((values[i].id || "") === "principal")
                return;
        }
        list.insert(0, {
            id: "principal",
            name: "Home",
            icon: "home",
            workspaceCount: 2
        });
    }

    Timer {
        id: syncTimer

        interval: 300
        onTriggered: root.applyRules()
    }

    Timer {
        id: enforceTimer

        interval: 250
        onTriggered: root.enforceOpenWindows()
    }

    Timer {
        id: styleApplyTimer

        interval: 40
        onTriggered: root.applyStyleForActivity(root.styleTargetId())
    }

    Timer {
        id: styleVerifyTimer

        interval: 200
        onTriggered: {
            const want = root.pendingVerifyMode;
            if (!want)
                return;
            const wantLight = want === "light";
            if (wantLight === Colours.currentLight)
                return;
            // scheme.json lost a race or FileView lagged — force another apply
            root.lastAppliedStyleKey = "";
            root.applyStyleForActivity(root.styleTargetId());
        }
    }

    Process {
        id: styleApplyProc

        property int gen: 0
        stdout: StdioCollector {
            onStreamFinished: root.onStyleApplyFinished(styleApplyProc.gen)
        }
    }

    Connections {
        target: GlobalConfig.activities

        function onEnabledChanged(): void {
            root.syncSoon();
            root.lastAppliedStyleKey = "";
            root.applyCurrentStyleSoon();
        }
    }

    Connections {
        target: root

        function onActiveWsIdChanged(): void {
            const id = root.styleTargetId();
            if (id === root.lastStyleActivityId)
                return;
            root.applyCurrentStyleSoon();
        }
    }

    Connections {
        target: GlobalConfig.activities.activities

        function onCountChanged(): void {
            root.ensurePrincipal();
            root.syncSoon();
        }
    }

    Connections {
        target: GlobalConfig.activities.appRules

        function onCountChanged(): void {
            root.syncSoon();
        }
    }

    FileView {
        id: rulesFile

        printErrors: false
        path: root.rulesPath
    }

    Component.onCompleted: Qt.callLater(() => {
        root.ensurePrincipal();
        root.applyRules();
        root.ensurePrincipalStyle();
        root.applyCurrentStyleSoon();
    })
}
