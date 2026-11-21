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
    property string projectionMode: "extend"
    property real externalScale: 1
    property string internalMonitorName: ""
    property string internalMonitorMode: "preferred"
    property real internalMonitorScale: 1
    property double lastMonitorApplyMs: 0
    property var knownExternalNames: []

    signal configReloaded
    signal monitorAdded(string name)
    signal monitorRemoved(string name)

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function focusWorkspace(ws: var): void {
        dispatch(usingLua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
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
        return toplevels.values.filter(t => t.workspace && t.workspace.id === ws && !isToplevelIgnored(t, ignoredTags));
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

    function applyMonitorLayout(mode: string, scale: real): void {
        const allMons = monitors.values;
        const internal = allMons.find(m => m.name.startsWith("eDP") || m.name.startsWith("LVDS")) ?? allMons[0];
        if (internal) {
            internalMonitorName = internal.name;
            const ipc = internal.lastIpcObject;
            if (ipc && ipc.width && ipc.height && ipc.refreshRate)
                internalMonitorMode = `${ipc.width}x${ipc.height}@${Math.round(ipc.refreshRate)}`;
            if (internal.scale)
                internalMonitorScale = internal.scale;
        }

        const intName = internalMonitorName || "eDP-1";
        const intMode = internalMonitorMode || "preferred";
        const intScale = internalMonitorScale || 1;
        const extMons = allMons.map(m => m.name).filter(n => n !== intName);
        if (extMons.length > 0)
            knownExternalNames = extMons;

        const targetExts = extMons.length > 0 ? extMons : knownExternalNames;
        if (mode === "external" && targetExts.length === 0)
            mode = "extend";

        projectionMode = mode;
        externalScale = scale;
        lastMonitorApplyMs = Date.now();

        const cmds = [];
        const addInt = enabled => {
            if (usingLua) {
                if (enabled)
                    cmds.push(`eval hl.monitor({ output = "${intName}", mode = "${intMode}", position = "0x0", scale = ${intScale}, disabled = false })`);
                else
                    cmds.push(`eval hl.monitor({ output = "${intName}", disabled = true })`);
            } else {
                if (enabled)
                    cmds.push(`keyword monitor ${intName},${intMode},0x0,${intScale}`);
                else
                    cmds.push(`keyword monitor ${intName},disable`);
            }
        };

        const addExt = target => {
            if (usingLua) {
                if (mode === "extend")
                    cmds.push(`eval hl.monitor({ output = "${target}", mode = "preferred", position = "auto-right", scale = ${scale}, disabled = false })`);
                else if (mode === "extend-up")
                    cmds.push(`eval hl.monitor({ output = "${target}", mode = "preferred", position = "auto-center-up", scale = ${scale}, disabled = false })`);
                else if (mode === "extend-left")
                    cmds.push(`eval hl.monitor({ output = "${target}", mode = "preferred", position = "auto-left", scale = ${scale}, disabled = false })`);
                else if (mode === "mirror")
                    cmds.push(`eval hl.monitor({ output = "${target}", mode = "preferred", position = "auto", scale = 1, mirror = "${intName}", disabled = false })`);
                else if (mode === "external")
                    cmds.push(`eval hl.monitor({ output = "${target}", mode = "preferred", position = "0x0", scale = ${scale}, disabled = false })`);
                else if (mode === "internal")
                    cmds.push(`eval hl.monitor({ output = "${target}", disabled = true })`);
            } else {
                if (mode === "extend")
                    cmds.push(`keyword monitor ${target},preferred,auto-right,${scale}`);
                else if (mode === "extend-up")
                    cmds.push(`keyword monitor ${target},preferred,auto-center-up,${scale}`);
                else if (mode === "extend-left")
                    cmds.push(`keyword monitor ${target},preferred,auto-left,${scale}`);
                else if (mode === "mirror")
                    cmds.push(`keyword monitor ${target},preferred,auto,1,mirror,${intName}`);
                else if (mode === "external")
                    cmds.push(`keyword monitor ${target},preferred,0x0,${scale}`);
                else if (mode === "internal")
                    cmds.push(`keyword monitor ${target},disable`);
            }
        };

        if (mode === "external") {
            for (const ext of targetExts)
                addExt(ext);
            addInt(false);
        } else {
            addInt(true);
            for (const ext of targetExts)
                addExt(ext);
        }

        if (cmds.length > 0)
            extras.batchMessage(cmds);
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
                if (n === "monitoradded") {
                    root.monitorAdded(event.data);
                } else if (n === "monitorremoved") {
                    root.monitorRemoved(event.data);
                    if (root.projectionMode === "external")
                        root.applyMonitorLayout("extend", root.externalScale);
                }
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
