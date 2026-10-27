pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.utils

Singleton {
    id: root

    property bool loaded
    property var overrides: ({})
    property string conflictWarning

    readonly property list<var> catalog: [
        // --- Window manager: windows ---
        {
            id: "closeWindow",
            label: () => Tr.tr("Close window"),
            description: () => Tr.tr("Close the active window"),
            defaultBind: "SUPER + C",
            dispatch: "hl.dsp.window.close()",
            category: "windows"
        },
        {
            id: "toggleFloat",
            label: () => Tr.tr("Toggle floating"),
            description: () => Tr.tr("Toggle floating mode for the active window"),
            defaultBind: "SUPER + V",
            dispatch: "hl.dsp.window.float({ action = \"toggle\" })",
            category: "windows"
        },
        {
            id: "togglePseudo",
            label: () => Tr.tr("Toggle pseudo"),
            description: () => Tr.tr("Toggle dwindle pseudo-tiling"),
            defaultBind: "SUPER + P",
            dispatch: "hl.dsp.window.pseudo()",
            category: "windows"
        },
        {
            id: "toggleSplit",
            label: () => Tr.tr("Toggle split"),
            description: () => Tr.tr("Toggle dwindle split direction"),
            defaultBind: "SUPER + J",
            dispatch: "hl.dsp.layout(\"togglesplit\")",
            category: "windows"
        },
        {
            id: "focusLeft",
            label: () => Tr.tr("Focus left"),
            description: () => Tr.tr("Move focus to the window on the left"),
            defaultBind: "SUPER + left",
            dispatch: "hl.dsp.focus({ direction = \"left\" })",
            category: "windows"
        },
        {
            id: "focusRight",
            label: () => Tr.tr("Focus right"),
            description: () => Tr.tr("Move focus to the window on the right"),
            defaultBind: "SUPER + right",
            dispatch: "hl.dsp.focus({ direction = \"right\" })",
            category: "windows"
        },
        {
            id: "focusUp",
            label: () => Tr.tr("Focus up"),
            description: () => Tr.tr("Move focus to the window above"),
            defaultBind: "SUPER + up",
            dispatch: "hl.dsp.focus({ direction = \"up\" })",
            category: "windows"
        },
        {
            id: "focusDown",
            label: () => Tr.tr("Focus down"),
            description: () => Tr.tr("Move focus to the window below"),
            defaultBind: "SUPER + down",
            dispatch: "hl.dsp.focus({ direction = \"down\" })",
            category: "windows"
        },
        {
            id: "windowDrag",
            label: () => Tr.tr("Move window (drag)"),
            description: () => Tr.tr("Drag the active window with the mouse"),
            defaultBind: "SUPER + mouse:272",
            dispatch: "hl.dsp.window.drag()",
            category: "windows",
            flags: {
                mouse: true
            }
        },
        {
            id: "windowResize",
            label: () => Tr.tr("Resize window (drag)"),
            description: () => Tr.tr("Resize the active window with the mouse"),
            defaultBind: "SUPER + mouse:273",
            dispatch: "hl.dsp.window.resize()",
            category: "windows",
            flags: {
                mouse: true
            }
        },
        // --- Window manager: workspaces ---
        {
            id: "workspace1",
            label: () => Tr.tr("Workspace %1").arg(1),
            description: () => Tr.tr("Switch to workspace %1").arg(1),
            defaultBind: "SUPER + 1",
            dispatch: "hl.dsp.focus({ workspace = 1 })",
            category: "workspaces"
        },
        {
            id: "workspace2",
            label: () => Tr.tr("Workspace %1").arg(2),
            description: () => Tr.tr("Switch to workspace %1").arg(2),
            defaultBind: "SUPER + 2",
            dispatch: "hl.dsp.focus({ workspace = 2 })",
            category: "workspaces"
        },
        {
            id: "workspace3",
            label: () => Tr.tr("Workspace %1").arg(3),
            description: () => Tr.tr("Switch to workspace %1").arg(3),
            defaultBind: "SUPER + 3",
            dispatch: "hl.dsp.focus({ workspace = 3 })",
            category: "workspaces"
        },
        {
            id: "workspace4",
            label: () => Tr.tr("Workspace %1").arg(4),
            description: () => Tr.tr("Switch to workspace %1").arg(4),
            defaultBind: "SUPER + 4",
            dispatch: "hl.dsp.focus({ workspace = 4 })",
            category: "workspaces"
        },
        {
            id: "workspace5",
            label: () => Tr.tr("Workspace %1").arg(5),
            description: () => Tr.tr("Switch to workspace %1").arg(5),
            defaultBind: "SUPER + 5",
            dispatch: "hl.dsp.focus({ workspace = 5 })",
            category: "workspaces"
        },
        {
            id: "workspace6",
            label: () => Tr.tr("Workspace %1").arg(6),
            description: () => Tr.tr("Switch to workspace %1").arg(6),
            defaultBind: "SUPER + 6",
            dispatch: "hl.dsp.focus({ workspace = 6 })",
            category: "workspaces"
        },
        {
            id: "workspace7",
            label: () => Tr.tr("Workspace %1").arg(7),
            description: () => Tr.tr("Switch to workspace %1").arg(7),
            defaultBind: "SUPER + 7",
            dispatch: "hl.dsp.focus({ workspace = 7 })",
            category: "workspaces"
        },
        {
            id: "workspace8",
            label: () => Tr.tr("Workspace %1").arg(8),
            description: () => Tr.tr("Switch to workspace %1").arg(8),
            defaultBind: "SUPER + 8",
            dispatch: "hl.dsp.focus({ workspace = 8 })",
            category: "workspaces"
        },
        {
            id: "workspace9",
            label: () => Tr.tr("Workspace %1").arg(9),
            description: () => Tr.tr("Switch to workspace %1").arg(9),
            defaultBind: "SUPER + 9",
            dispatch: "hl.dsp.focus({ workspace = 9 })",
            category: "workspaces"
        },
        {
            id: "workspace10",
            label: () => Tr.tr("Workspace %1").arg(10),
            description: () => Tr.tr("Switch to workspace %1").arg(10),
            defaultBind: "SUPER + 0",
            dispatch: "hl.dsp.focus({ workspace = 10 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace1",
            label: () => Tr.tr("Move to workspace %1").arg(1),
            description: () => Tr.tr("Move the active window to workspace %1").arg(1),
            defaultBind: "SUPER + SHIFT + 1",
            dispatch: "hl.dsp.window.move({ workspace = 1 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace2",
            label: () => Tr.tr("Move to workspace %1").arg(2),
            description: () => Tr.tr("Move the active window to workspace %1").arg(2),
            defaultBind: "SUPER + SHIFT + 2",
            dispatch: "hl.dsp.window.move({ workspace = 2 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace3",
            label: () => Tr.tr("Move to workspace %1").arg(3),
            description: () => Tr.tr("Move the active window to workspace %1").arg(3),
            defaultBind: "SUPER + SHIFT + 3",
            dispatch: "hl.dsp.window.move({ workspace = 3 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace4",
            label: () => Tr.tr("Move to workspace %1").arg(4),
            description: () => Tr.tr("Move the active window to workspace %1").arg(4),
            defaultBind: "SUPER + SHIFT + 4",
            dispatch: "hl.dsp.window.move({ workspace = 4 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace5",
            label: () => Tr.tr("Move to workspace %1").arg(5),
            description: () => Tr.tr("Move the active window to workspace %1").arg(5),
            defaultBind: "SUPER + SHIFT + 5",
            dispatch: "hl.dsp.window.move({ workspace = 5 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace6",
            label: () => Tr.tr("Move to workspace %1").arg(6),
            description: () => Tr.tr("Move the active window to workspace %1").arg(6),
            defaultBind: "SUPER + SHIFT + 6",
            dispatch: "hl.dsp.window.move({ workspace = 6 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace7",
            label: () => Tr.tr("Move to workspace %1").arg(7),
            description: () => Tr.tr("Move the active window to workspace %1").arg(7),
            defaultBind: "SUPER + SHIFT + 7",
            dispatch: "hl.dsp.window.move({ workspace = 7 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace8",
            label: () => Tr.tr("Move to workspace %1").arg(8),
            description: () => Tr.tr("Move the active window to workspace %1").arg(8),
            defaultBind: "SUPER + SHIFT + 8",
            dispatch: "hl.dsp.window.move({ workspace = 8 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace9",
            label: () => Tr.tr("Move to workspace %1").arg(9),
            description: () => Tr.tr("Move the active window to workspace %1").arg(9),
            defaultBind: "SUPER + SHIFT + 9",
            dispatch: "hl.dsp.window.move({ workspace = 9 })",
            category: "workspaces"
        },
        {
            id: "moveToWorkspace10",
            label: () => Tr.tr("Move to workspace %1").arg(10),
            description: () => Tr.tr("Move the active window to workspace %1").arg(10),
            defaultBind: "SUPER + SHIFT + 0",
            dispatch: "hl.dsp.window.move({ workspace = 10 })",
            category: "workspaces"
        },
        {
            id: "toggleSpecial",
            label: () => Tr.tr("Toggle scratchpad"),
            description: () => Tr.tr("Show or hide the special workspace"),
            defaultBind: "SUPER + S",
            dispatch: "hl.dsp.workspace.toggle_special(\"magic\")",
            category: "workspaces"
        },
        {
            id: "moveToSpecial",
            label: () => Tr.tr("Move to scratchpad"),
            description: () => Tr.tr("Move the active window to the special workspace"),
            defaultBind: "SUPER + SHIFT + S",
            dispatch: "hl.dsp.window.move({ workspace = \"special:magic\" })",
            category: "workspaces"
        },
        {
            id: "workspaceNext",
            label: () => Tr.tr("Next workspace"),
            description: () => Tr.tr("Switch to the next desktop (respects activity boundaries unless cross-activity is enabled)"),
            defaultBind: "SUPER + mouse_down",
            global: "caelestia:workspaceNext",
            category: "workspaces"
        },
        {
            id: "workspacePrev",
            label: () => Tr.tr("Previous workspace"),
            description: () => Tr.tr("Switch to the previous desktop (respects activity boundaries unless cross-activity is enabled)"),
            defaultBind: "SUPER + mouse_up",
            global: "caelestia:workspacePrev",
            category: "workspaces"
        },
        {
            id: "activityNext",
            label: () => Tr.tr("Next activity"),
            description: () => Tr.tr("Jump to the first desktop of the next activity"),
            defaultBind: "SUPER + CTRL + Right",
            global: "caelestia:activityNext",
            category: "activities"
        },
        {
            id: "activityPrev",
            label: () => Tr.tr("Previous activity"),
            description: () => Tr.tr("Jump to the first desktop of the previous activity"),
            defaultBind: "SUPER + CTRL + Left",
            global: "caelestia:activityPrev",
            category: "activities"
        },
        {
            id: "activityOverview",
            label: () => Tr.tr("Activities overview"),
            description: () => Tr.tr("Show a preview of all activities and desktops"),
            defaultBind: "SUPER + Tab",
            global: "caelestia:activityOverview",
            category: "activities"
        },
        // --- Window manager: apps ---
        {
            id: "openTerminal",
            label: () => Tr.tr("Terminal"),
            description: () => Tr.tr("Open the terminal"),
            defaultBind: "SUPER + Q",
            dispatch: "hl.dsp.exec_cmd(\"kitty\")",
            category: "apps"
        },
        {
            id: "openFiles",
            label: () => Tr.tr("File manager"),
            description: () => Tr.tr("Open the file manager"),
            defaultBind: "SUPER + E",
            // Resolved at apply-time from GlobalConfig.general.apps.explorer
            dispatch: "hl.dsp.exec_cmd(\"thunar\")",
            category: "apps"
        },
        {
            id: "openMenu",
            label: () => Tr.tr("App menu"),
            description: () => Tr.tr("Open the application launcher menu"),
            defaultBind: "SUPER + R",
            dispatch: "hl.dsp.exec_cmd(\"hyprlauncher\")",
            category: "apps"
        },
        {
            id: "exitHyprland",
            label: () => Tr.tr("Exit Hyprland"),
            description: () => Tr.tr("Exit the compositor session"),
            defaultBind: "SUPER + M",
            dispatch: "hl.dsp.exec_cmd(\"command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit\")",
            category: "apps"
        },
        // --- Caelestia shell ---
        {
            id: "launcher",
            label: () => Tr.tr("Launcher"),
            description: () => Tr.tr("Toggle the app launcher"),
            defaultBind: "SUPER + Space",
            global: "caelestia:launcher",
            category: "shell"
        },
        {
            id: "nexus",
            label: () => Tr.tr("Settings (Nexus)"),
            description: () => Tr.tr("Open Caelestia settings"),
            defaultBind: "SUPER + COMMA",
            global: "caelestia:nexus",
            category: "shell"
        },
        {
            id: "dashboard",
            label: () => Tr.tr("Dashboard"),
            description: () => Tr.tr("Toggle the dashboard"),
            defaultBind: "SUPER + D",
            global: "caelestia:dashboard",
            category: "shell"
        },
        {
            id: "session",
            label: () => Tr.tr("Session menu"),
            description: () => Tr.tr("Power / session menu"),
            defaultBind: "CTRL + ALT + Delete",
            global: "caelestia:session",
            category: "shell"
        },
        {
            id: "sidebar",
            label: () => Tr.tr("Sidebar"),
            description: () => Tr.tr("Toggle the sidebar"),
            defaultBind: "SUPER + N",
            global: "caelestia:sidebar",
            category: "shell"
        },
        {
            id: "utilities",
            label: () => Tr.tr("Utilities"),
            description: () => Tr.tr("Toggle utilities panel"),
            defaultBind: "SUPER + U",
            global: "caelestia:utilities",
            category: "shell"
        },
        {
            id: "showall",
            label: () => Tr.tr("Show panels"),
            description: () => Tr.tr("Toggle launcher, dashboard and OSD"),
            defaultBind: "SUPER + K",
            global: "caelestia:showall",
            category: "shell"
        },
        {
            id: "lock",
            label: () => Tr.tr("Lock screen"),
            description: () => Tr.tr("Lock the session"),
            defaultBind: "SUPER + L",
            global: "caelestia:lock",
            category: "shell",
            flags: {
                locked: true
            }
        },
        {
            id: "clearNotifs",
            label: () => Tr.tr("Clear notifications"),
            description: () => Tr.tr("Dismiss all notifications"),
            defaultBind: "CTRL + ALT + C",
            global: "caelestia:clearNotifs",
            category: "notifications",
            flags: {
                locked: true
            }
        },
        {
            id: "toggleDnd",
            label: () => Tr.tr("Do not disturb"),
            description: () => Tr.tr("Toggle do not disturb"),
            defaultBind: "SUPER + SHIFT + N",
            global: "caelestia:toggleDnd",
            category: "notifications"
        },
        {
            id: "mediaToggle",
            label: () => Tr.tr("Play / pause"),
            description: () => Tr.tr("Toggle media playback"),
            defaultBind: "CTRL + SUPER + Space",
            global: "caelestia:mediaToggle",
            category: "media"
        },
        {
            id: "mediaNext",
            label: () => Tr.tr("Next track"),
            description: () => Tr.tr("Skip to next track"),
            defaultBind: "CTRL + SUPER + Equal",
            global: "caelestia:mediaNext",
            category: "media"
        },
        {
            id: "mediaPrev",
            label: () => Tr.tr("Previous track"),
            description: () => Tr.tr("Go to previous track"),
            defaultBind: "CTRL + SUPER + Minus",
            global: "caelestia:mediaPrev",
            category: "media"
        },
        {
            id: "mediaStop",
            label: () => Tr.tr("Stop media"),
            description: () => Tr.tr("Stop media playback"),
            defaultBind: "CTRL + SUPER + Backspace",
            global: "caelestia:mediaStop",
            category: "media"
        },
        {
            id: "brightnessUp",
            label: () => Tr.tr("Brightness up"),
            description: () => Tr.tr("Increase screen brightness"),
            defaultBind: "XF86MonBrightnessUp",
            global: "caelestia:brightnessUp",
            category: "system",
            flags: {
                locked: true,
                repeating: true
            }
        },
        {
            id: "brightnessDown",
            label: () => Tr.tr("Brightness down"),
            description: () => Tr.tr("Decrease screen brightness"),
            defaultBind: "XF86MonBrightnessDown",
            global: "caelestia:brightnessDown",
            category: "system",
            flags: {
                locked: true,
                repeating: true
            }
        },
        {
            id: "screenshot",
            label: () => Tr.tr("Screenshot region"),
            description: () => Tr.tr("Capture a screen region"),
            defaultBind: "Print",
            global: "caelestia:screenshot",
            category: "capture"
        },
        {
            id: "screenshotFreeze",
            label: () => Tr.tr("Screenshot region (freeze)"),
            description: () => Tr.tr("Capture a region with a frozen screen"),
            defaultBind: "SHIFT + Print",
            global: "caelestia:screenshotFreeze",
            category: "capture"
        },
        {
            id: "screenshotClip",
            label: () => Tr.tr("Screenshot to clipboard"),
            description: () => Tr.tr("Capture a region to the clipboard"),
            defaultBind: "SUPER + Print",
            global: "caelestia:screenshotClip",
            category: "capture"
        },
        {
            id: "screenshotFreezeClip",
            label: () => Tr.tr("Screenshot freeze + clipboard"),
            description: () => Tr.tr("Frozen region capture to the clipboard"),
            defaultBind: "SUPER + SHIFT + Print",
            global: "caelestia:screenshotFreezeClip",
            category: "capture"
        },
        {
            id: "clipboard",
            label: () => Tr.tr("Clipboard history"),
            description: () => Tr.tr("Open clipboard history and paste into the focused window"),
            defaultBind: "SUPER + SHIFT + V",
            global: "caelestia:clipboard",
            category: "shell"
        }
    ]

    readonly property var categoryLabels: ({
            windows: () => Tr.tr("Windows"),
            workspaces: () => Tr.tr("Workspaces"),
            activities: () => Tr.tr("Activities"),
            apps: () => Tr.tr("Applications"),
            shell: () => Tr.tr("Shell"),
            notifications: () => Tr.tr("Notifications"),
            media: () => Tr.tr("Media"),
            system: () => Tr.tr("System"),
            capture: () => Tr.tr("Screenshots")
        })

    function normalizeBind(bind: string): string {
        return (bind || "").replace(/\s+/g, "").toLowerCase();
    }

    function bindFor(actionId: string): string {
        if (actionId in root.overrides)
            return root.overrides[actionId] ?? "";
        const action = root.catalog.find(a => a.id === actionId);
        return action?.defaultBind ?? "";
    }

    function isDefault(actionId: string): bool {
        if (!(actionId in root.overrides))
            return true;
        const action = root.catalog.find(a => a.id === actionId);
        return root.normalizeBind(root.overrides[actionId] ?? "") === root.normalizeBind(action?.defaultBind ?? "");
    }

    function findConflict(actionId: string, bind: string): var {
        const norm = root.normalizeBind(bind);
        if (!norm)
            return null;
        for (const action of root.catalog) {
            if (action.id === actionId)
                continue;
            if (root.normalizeBind(root.bindFor(action.id)) === norm)
                return action;
        }
        return null;
    }

    function setBind(actionId: string, bind: string, replaceConflict: bool): bool {
        root.conflictWarning = "";
        const trimmed = (bind || "").trim();

        if (trimmed) {
            const conflict = root.findConflict(actionId, trimmed);
            if (conflict) {
                if (!replaceConflict) {
                    root.conflictWarning = Tr.tr("Already used by “%1”").arg(conflict.label());
                    return false;
                }
                root.overrides[conflict.id] = "";
            }
        }

        const action = root.catalog.find(a => a.id === actionId);
        if (!action)
            return false;

        if (!trimmed || root.normalizeBind(trimmed) === root.normalizeBind(action.defaultBind))
            delete root.overrides[actionId];
        else
            root.overrides[actionId] = trimmed;

        // Trigger property change for UI
        root.overrides = Object.assign({}, root.overrides);
        root.persist();
        root.apply();
        return true;
    }

    function resetBind(actionId: string): void {
        delete root.overrides[actionId];
        root.overrides = Object.assign({}, root.overrides);
        root.conflictWarning = "";
        root.persist();
        root.apply();
    }

    function resetAll(): void {
        root.overrides = {};
        root.conflictWarning = "";
        root.persist();
        root.apply();
    }

    function persist(): void {
        storage.setText(JSON.stringify({
                binds: root.overrides
            }, null, 4) + "\n");
    }

    function flagsLua(flags: var): string {
        if (!flags)
            return "";
        const parts = [];
        if (flags.locked)
            parts.push("locked = true");
        if (flags.release)
            parts.push("release = true");
        if (flags.repeating)
            parts.push("repeating = true");
        if (flags.mouse)
            parts.push("mouse = true");
        if (parts.length === 0)
            return "";
        return `, { ${parts.join(", ")} }`;
    }

    function escapeLuaString(s: string): string {
        return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    }

    function dispatcherLua(action: var): string {
        if (action.global)
            return `hl.dsp.global("${root.escapeLuaString(action.global)}")`;
        if (action.id === "openFiles") {
            const bin = GlobalConfig.general.apps.explorer[0] || "thunar";
            return `hl.dsp.exec_cmd("${root.escapeLuaString(bin)}")`;
        }
        if (action.dispatch)
            return action.dispatch;
        return "hl.dsp.no_op()";
    }

    readonly property string grabSubmap: "caelestia-keybind-grab"

    function generateLua(): string {
        let out = "-- Auto-generated by Caelestia Keybinds. Do not edit.\n";
        out += "-- Source: ~/.config/caelestia/keybinds.json\n\n";

        // Grab submap: while recording, compositor shortcuts are suppressed so
        // keys reach the settings UI (Plasma-style). Needs ≥1 bind to register.
        out += `hl.define_submap("${root.grabSubmap}", function()\n`;
        out += `    hl.bind("Escape", hl.dsp.submap("reset"), { non_consuming = true })\n`;
        out += `end)\n\n`;

        for (const action of root.catalog) {
            const bind = root.bindFor(action.id);
            if (!bind) {
                out += `-- ${action.id}: unbound\n`;
                continue;
            }
            out += `hl.bind("${root.escapeLuaString(bind)}", ${root.dispatcherLua(action)}${root.flagsLua(action.flags)})\n`;
        }
        return out;
    }

    function apply(): void {
        const lua = root.generateLua();
        luaFile.setText(lua);
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    function setGrabActive(active: bool): void {
        const target = active ? root.grabSubmap : "reset";
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.submap("${target}")`]);
    }

    function keyEventToBind(event: var): string {
        const key = event.key;
        const modOnly = [Qt.Key_Control, Qt.Key_Shift, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_AltGr, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Hyper_L, Qt.Key_Hyper_R];
        if (modOnly.includes(key))
            return "";

        const mods = [];
        // Ignore the modifier bit that matches the key itself when relevant
        if (event.modifiers & Qt.MetaModifier)
            mods.push("SUPER");
        if (event.modifiers & Qt.ControlModifier)
            mods.push("CTRL");
        if (event.modifiers & Qt.AltModifier)
            mods.push("ALT");
        if (event.modifiers & Qt.ShiftModifier)
            mods.push("SHIFT");

        const name = root.qtKeyToHypr(key, event.text || "");
        if (!name)
            return "";

        return [...mods, name].join(" + ");
    }

    function mouseEventToBind(button: int): string {
        // Hyprland BTN_* codes: left 272, right 273, middle 274, back 275, forward 276
        const map = {
            [Qt.LeftButton]: "mouse:272",
            [Qt.RightButton]: "mouse:273",
            [Qt.MiddleButton]: "mouse:274",
            [Qt.BackButton]: "mouse:275",
            [Qt.ForwardButton]: "mouse:276"
        };
        return map[button] ?? "";
    }

    function qtKeyToHypr(key: int, text: string): string {
        const special = {
            [Qt.Key_Escape]: "Escape",
            [Qt.Key_Tab]: "Tab",
            [Qt.Key_Backtab]: "Tab",
            [Qt.Key_Backspace]: "Backspace",
            [Qt.Key_Return]: "Return",
            [Qt.Key_Enter]: "Return",
            [Qt.Key_Insert]: "Insert",
            [Qt.Key_Delete]: "Delete",
            [Qt.Key_Pause]: "Pause",
            [Qt.Key_Print]: "Print",
            [Qt.Key_SysReq]: "Sys_Req",
            [Qt.Key_Home]: "Home",
            [Qt.Key_End]: "End",
            [Qt.Key_Left]: "Left",
            [Qt.Key_Up]: "Up",
            [Qt.Key_Right]: "Right",
            [Qt.Key_Down]: "Down",
            [Qt.Key_PageUp]: "Page_Up",
            [Qt.Key_PageDown]: "Page_Down",
            [Qt.Key_CapsLock]: "Caps_Lock",
            [Qt.Key_NumLock]: "Num_Lock",
            [Qt.Key_ScrollLock]: "Scroll_Lock",
            [Qt.Key_F1]: "F1",
            [Qt.Key_F2]: "F2",
            [Qt.Key_F3]: "F3",
            [Qt.Key_F4]: "F4",
            [Qt.Key_F5]: "F5",
            [Qt.Key_F6]: "F6",
            [Qt.Key_F7]: "F7",
            [Qt.Key_F8]: "F8",
            [Qt.Key_F9]: "F9",
            [Qt.Key_F10]: "F10",
            [Qt.Key_F11]: "F11",
            [Qt.Key_F12]: "F12",
            [Qt.Key_Space]: "Space",
            [Qt.Key_Minus]: "Minus",
            [Qt.Key_Equal]: "Equal",
            [Qt.Key_Plus]: "Equal",
            [Qt.Key_Comma]: "comma",
            [Qt.Key_Period]: "Period",
            [Qt.Key_Slash]: "Slash",
            [Qt.Key_Semicolon]: "Semicolon",
            [Qt.Key_Apostrophe]: "Apostrophe",
            [Qt.Key_BracketLeft]: "bracketleft",
            [Qt.Key_BracketRight]: "bracketright",
            [Qt.Key_Backslash]: "backslash",
            [Qt.Key_QuoteLeft]: "grave",
            [Qt.Key_VolumeMute]: "XF86AudioMute",
            [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
            [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume",
            [Qt.Key_MediaPlay]: "XF86AudioPlay",
            [Qt.Key_MediaStop]: "XF86AudioStop",
            [Qt.Key_MediaPrevious]: "XF86AudioPrev",
            [Qt.Key_MediaNext]: "XF86AudioNext",
            [Qt.Key_MonBrightnessUp]: "XF86MonBrightnessUp",
            [Qt.Key_MonBrightnessDown]: "XF86MonBrightnessDown"
        };

        if (special[key])
            return special[key];

        // Letters / digits
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(key);
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(key);

        if (text && text.length === 1 && text !== " ")
            return text.toUpperCase() === text.toLowerCase() ? text : text.toUpperCase();

        return "";
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.config}/keybinds.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.overrides = data.binds ?? {};
            } catch (e) {
                root.overrides = {};
            }
            root.loaded = true;
            root.apply();
        }
        onLoadFailed: err => {
            root.overrides = {};
            root.loaded = true;
            if (err === FileViewError.FileNotFound) {
                Qt.callLater(() => {
                    root.persist();
                    root.apply();
                });
            }
        }
    }

    FileView {
        id: luaFile

        printErrors: false
        path: `${Quickshell.env("HOME")}/.config/hypr/caelestia-binds.lua`
    }
}
