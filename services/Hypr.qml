pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Caelestia.I18n
import Caelestia.Services
import qs.components.misc

Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors
    readonly property bool usingLua: Hyprland.usingLua

    readonly property HyprlandToplevel activeToplevel: {
        const t = Hyprland.activeToplevel;
        return t?.workspace?.name.startsWith("special:") || Hyprland.focusedWorkspace?.toplevels.values.length > 0 ? t : null;
    }
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    readonly property HyprKeyboard keyboard: extras.devices.keyboards.find(kb => kb.main) ?? null
    readonly property bool capsLock: keyboard?.capsLock ?? false
    readonly property bool numLock: keyboard?.numLock ?? false
    readonly property string defaultKbLayout: keyboard?.layout.split(",")[0] ?? "??"
    readonly property string kbLayoutFull: keyboard?.activeKeymap ?? Tr.trCtx("Unknown", "keyboard layout")
    readonly property string kbLayout: kbMap.get(kbLayoutFull) ?? "??"
    readonly property var kbMap: new Map()

    readonly property alias extras: extras
    readonly property alias options: extras.options
    readonly property alias devices: extras.devices

    property string lastSpecialWorkspace: ""

    signal configReloaded

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function focusWorkspace(ws: var): void {
        dispatch(usingLua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
    }

    property var pendingFocusToplevel: null

    readonly property Timer focusDefer: Timer {
        interval: 80
        repeat: false
        onTriggered: {
            const t = root.pendingFocusToplevel;
            root.pendingFocusToplevel = null;
            if (t)
                root.focusToplevelNow(t);
        }
    }

    function focusToplevel(toplevel: var, defer: bool): void {
        if (!toplevel)
            return;
        if (defer) {
            root.pendingFocusToplevel = toplevel;
            focusDefer.restart();
            return;
        }
        root.focusToplevelNow(toplevel);
    }

    function focusToplevelNow(toplevel: var): void {
        if (!toplevel)
            return;
        const raw = String(toplevel.address ?? "");
        if (!raw)
            return;
        const addr = raw.startsWith("0x") ? raw : `0x${raw}`;
        const wsId = toplevel.workspace?.id ?? toplevel.lastIpcObject?.workspace?.id;
        if (wsId != null && wsId !== root.activeWsId)
            root.focusWorkspace(wsId);
        dispatch(usingLua ? `hl.dsp.focus({ window = "address:${addr}" })` : `focuswindow address:${addr}`);
    }

    function normalizeAppToken(value: string): string {
        return String(value || "").trim().toLowerCase().replace(/\.desktop$/, "");
    }

    function collectAppTokens(hints: var): list<string> {
        const tokens = [];
        const push = v => {
            const t = root.normalizeAppToken(v);
            if (t && !tokens.includes(t))
                tokens.push(t);
        };

        const desktopEntry = hints?.desktopEntry ?? "";
        push(desktopEntry);
        if (desktopEntry) {
            const entry = DesktopEntries.byId(desktopEntry) || DesktopEntries.byId(`${desktopEntry}.desktop`);
            push(entry?.id);
            push(entry?.startupClass);
            push(entry?.name);
        }

        const appName = hints?.appName ?? "";
        push(appName);
        if (appName) {
            const entry = DesktopEntries.heuristicLookup(appName);
            push(entry?.id);
            push(entry?.startupClass);
            push(entry?.name);
        }

        const appIcon = hints?.appIcon ?? "";
        push(appIcon);
        if (appIcon) {
            const entry = DesktopEntries.heuristicLookup(appIcon);
            push(entry?.id);
            push(entry?.startupClass);
            push(entry?.name);
        }

        return tokens;
    }

    function scoreToplevelForApp(toplevel: var, tokens: list<string>): int {
        const ipc = toplevel?.lastIpcObject;
        const cls = root.normalizeAppToken(ipc?.class);
        const initial = root.normalizeAppToken(ipc?.initialClass);
        if (!cls && !initial)
            return -1;

        let best = -1;
        for (const token of tokens) {
            if (!token)
                continue;
            if (cls === token || initial === token)
                best = Math.max(best, 100);
            else if (cls.endsWith(`.${token}`) || initial.endsWith(`.${token}`))
                best = Math.max(best, 80);
            else if ((token.length >= 3 && (cls.includes(token) || initial.includes(token))) || (cls.length >= 3 && token.includes(cls)) || (initial.length >= 3 && token.includes(initial)))
                best = Math.max(best, 40);
        }

        // Prefer visible windows, but still allow focusing minimized/hidden ones.
        if (best >= 0 && ipc && !ipc.mapped)
            best = Math.max(1, best - 25);

        return best;
    }

    function findAppToplevel(hints: var): var {
        const tokens = root.collectAppTokens(hints);
        if (tokens.length === 0)
            return null;

        let best = null;
        let bestScore = -1;
        for (const t of toplevels.values) {
            const score = root.scoreToplevelForApp(t, tokens);
            if (score > bestScore) {
                bestScore = score;
                best = t;
            }
        }

        return bestScore >= 0 ? best : null;
    }

    function focusApp(hints: var, defer: bool): bool {
        const best = root.findAppToplevel(hints);
        if (!best)
            return false;
        root.focusToplevel(best, defer);
        return true;
    }

    function toggleSpecial(name: string): void {
        dispatch(usingLua ? `hl.dsp.workspace.toggle_special("${name}")` : `togglespecialworkspace ${name}`);
    }

    function cycleSpecialWorkspace(direction: string): void {
        const openSpecials = workspaces.values.filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0);

        if (openSpecials.length === 0)
            return;

        const activeSpecial = focusedMonitor.lastIpcObject.specialWorkspace.name ?? "";

        if (!activeSpecial) {
            if (lastSpecialWorkspace) {
                const workspace = workspaces.values.find(w => w.name === lastSpecialWorkspace);
                if (workspace && workspace.lastIpcObject.windows > 0) {
                    focusWorkspace(lastSpecialWorkspace);
                    return;
                }
            }
            focusWorkspace(openSpecials[0].name);
            return;
        }

        const currentIndex = openSpecials.findIndex(w => w.name === activeSpecial);
        let nextIndex = 0;

        if (currentIndex !== -1) {
            if (direction === "next")
                nextIndex = (currentIndex + 1) % openSpecials.length;
            else
                nextIndex = (currentIndex - 1 + openSpecials.length) % openSpecials.length;
        }

        focusWorkspace(openSpecials[nextIndex].name);
    }

    function monitorNames(): list<string> {
        return monitors.values.map(e => e.name);
    }

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return Hyprland.monitorFor(screen);
    }

    function trimWsName(name: string): string {
        return name.startsWith("special:") ? name.slice("special:".length) : name;
    }

    function toplevelsForWs(ws: int, ignoredTags = []): list<HyprlandToplevel> {
        // Sort left→right, then top→bottom so bar/overview icons match layout
        return toplevels.values.filter(t => t.workspace && t.workspace.id === ws && !isToplevelIgnored(t, ignoredTags)).slice().sort((a, b) => {
            const aa = a?.lastIpcObject?.at;
            const bb = b?.lastIpcObject?.at;
            if (!aa || !bb)
                return !aa - !bb;
            return (aa[0] - bb[0]) || (aa[1] - bb[1]);
        });
    }

    function isToplevelIgnored(toplevel: HyprlandToplevel, ignoredTags = []): bool {
        const ipc = toplevel?.lastIpcObject;
        if (!ipc?.class || !ipc.mapped)
            return true;

        return ipc.tags?.some(tag => ignoredTags.includes(tag.replace(/\*$/, ""))) ?? false;
    }

    function reloadDynamicConfs(): void {
        if (usingLua) {
            extras.batchMessage(['eval hl.bind("Caps_Lock", hl.dsp.global("caelestia:refreshDevices"), { locked = true, non_consuming = true, ignore_mods = true, release = true })', 'eval hl.bind("Num_Lock", hl.dsp.global("caelestia:refreshDevices"), { locked = true, non_consuming = true, ignore_mods = true, release = true })', 'eval hl.bind("code:66", hl.dsp.global("caelestia:refreshDevices"), { locked = true, non_consuming = true, ignore_mods = true, release = true })']);
        } else {
            extras.batchMessage(["keyword bindlni ,Caps_Lock,global,caelestia:refreshDevices", "keyword bindlni ,Num_Lock,global,caelestia:refreshDevices", "keyword bindlni ,code:66,global,caelestia:refreshDevices"]);
        }
    }

    onUsingLuaChanged: reloadDynamicConfs()
    Component.onCompleted: reloadDynamicConfs()

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (n === "configreloaded") {
                root.configReloaded();
                root.reloadDynamicConfs();
            } else if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                Hyprland.refreshToplevels();
            }
        }

        target: Hyprland
    }

    Connections {
        function onLastIpcObjectChanged(): void {
            const specialName = root.focusedMonitor.lastIpcObject.specialWorkspace.name;

            if (specialName && specialName.startsWith("special:")) {
                root.lastSpecialWorkspace = specialName;
            }
        }

        target: root.focusedMonitor
    }

    FileView {
        id: kbLayoutFile

        path: Quickshell.env("CAELESTIA_XKB_RULES_PATH") || "/usr/share/X11/xkb/rules/base.lst"
        onLoaded: {
            const layoutMatch = text().match(/! layout\n([\s\S]*?)\n\n/);
            if (layoutMatch) {
                const lines = layoutMatch[1].split("\n");
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("!"))
                        continue;

                    const match = line.match(/^\s*([a-z]{2,})\s+([a-zA-Z() ]+)$/);
                    if (match)
                        root.kbMap.set(match[2], match[1]);
                }
            }

            const variantMatch = text().match(/! variant\n([\s\S]*?)\n\n/);
            if (variantMatch) {
                const lines = variantMatch[1].split("\n");
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("!"))
                        continue;

                    const match = line.match(/^\s*([a-zA-Z0-9_-]+)\s+([a-z]{2,}): (.+)$/);
                    if (match)
                        root.kbMap.set(match[3], match[2]);
                }
            }
        }
    }

    IpcHandler {
        function refreshDevices(): void {
            extras.refreshDevices();
        }

        function cycleSpecialWorkspace(direction: string): void {
            root.cycleSpecialWorkspace(direction);
        }

        function listSpecialWorkspaces(): string {
            return root.workspaces.values.filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0).map(w => w.name).join("\n");
        }

        target: "hypr"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "refreshDevices"
        description: "Reload devices"
        onPressed: extras.refreshDevices()
        onReleased: extras.refreshDevices()
    }

    HyprExtras {
        id: extras

        usingLua: Hyprland.usingLua
    }
}
