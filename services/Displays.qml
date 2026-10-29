pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Caelestia.I18n
import qs.utils

Singleton {
    id: root

    property list<var> monitors: []
    property bool loading: false
    property string lastError: ""
    // Per-output Adaptive Sync policy (0 never, 1 always, 2 automatic).
    // hyprctl only exposes whether VRR is currently asserted on the CRTC.
    property var vrrPolicies: ({})

    readonly property string luaPath: `${Quickshell.env("HOME")}/.config/hypr/caelestia-monitors.lua`
    readonly property list<real> scaleOptions: [1, 1.25, 1.5, 1.75, 2]
    // Plasma-style default when we have no saved policy for an output.
    readonly property int defaultVrrPolicy: 2

    function refresh(): void {
        if (fetchProc.running)
            return;
        root.loading = true;
        fetchProc.running = true;
    }

    function rememberVrr(name: string, vrr: int): void {
        if (!name)
            return;
        const next = Object.assign({}, root.vrrPolicies);
        next[name] = vrr;
        root.vrrPolicies = next;
    }

    function policyVrr(name: string, fallback: int): int {
        if (name && root.vrrPolicies[name] !== undefined)
            return Number(root.vrrPolicies[name]);
        return fallback;
    }

    function normalizeVrr(v: int): int {
        if (v === 1 || v === 2 || v === 3)
            return v === 3 ? 2 : v; // treat content-type (3) as automatic in UI
        return 0;
    }

    function ingestLuaPolicies(text: string): void {
        const blocks = String(text || "").split(/hl\.monitor\s*\(/);
        const next = Object.assign({}, root.vrrPolicies);
        for (let i = 1; i < blocks.length; i++) {
            const block = blocks[i];
            const nameMatch = block.match(/output\s*=\s*"([^"]+)"/);
            const vrrMatch = block.match(/vrr\s*=\s*(-?\d+)/);
            if (!nameMatch || !vrrMatch)
                continue;
            next[nameMatch[1]] = root.normalizeVrr(Number(vrrMatch[1]));
        }
        root.vrrPolicies = next;
    }

    function parseMode(modeStr: string): var {
        const m = String(modeStr || "").match(/^(\d+)x(\d+)@([\d.]+)/i);
        if (!m)
            return null;
        return {
            w: Number(m[1]),
            h: Number(m[2]),
            hz: Number(m[3])
        };
    }

    function modeForHypr(modeStr: string): string {
        const p = root.parseMode(modeStr);
        if (!p)
            return String(modeStr || "").replace(/Hz$/i, "").trim();
        const rounded = Math.round(p.hz);
        const hzStr = Math.abs(p.hz - rounded) < 0.051 ? String(rounded) : String(Math.round(p.hz * 100) / 100);
        return `${p.w}x${p.h}@${hzStr}`;
    }

    function formatModeLabel(modeStr: string): string {
        const p = root.parseMode(modeStr);
        if (!p)
            return modeStr;
        const rounded = Math.round(p.hz);
        const hz = Math.abs(p.hz - rounded) < 0.051 ? rounded : Math.round(p.hz * 100) / 100;
        return Tr.tr("%1×%2 · %3 Hz").arg(p.w).arg(p.h).arg(hz);
    }

    function dedupeModes(availableModes: list<string>): list<string> {
        const seen = ({});
        const out = [];
        for (let i = 0; i < availableModes.length; i++) {
            const key = root.modeForHypr(availableModes[i]);
            if (!key || seen[key])
                continue;
            seen[key] = true;
            out.push(availableModes[i]);
        }
        out.sort((a, b) => {
            const pa = root.parseMode(a);
            const pb = root.parseMode(b);
            if (!pa || !pb)
                return 0;
            if (pa.w !== pb.w)
                return pb.w - pa.w;
            if (pa.h !== pb.h)
                return pb.h - pa.h;
            return pb.hz - pa.hz;
        });
        return out;
    }

    function matchCurrentMode(width: int, height: int, refreshRate: real, availableModes: list<string>): string {
        let best = "";
        let bestDiff = Number.POSITIVE_INFINITY;
        for (let i = 0; i < availableModes.length; i++) {
            const mode = availableModes[i];
            const p = root.parseMode(mode);
            if (!p || p.w !== width || p.h !== height)
                continue;
            const d = Math.abs(p.hz - refreshRate);
            if (d < bestDiff) {
                bestDiff = d;
                best = mode;
            }
        }
        if (best.length > 0)
            return best;
        return `${width}x${height}@${refreshRate}`;
    }

    function maxAvailableHz(availableModes: list<string>): real {
        let max = 0;
        for (let i = 0; i < availableModes.length; i++) {
            const p = root.parseMode(availableModes[i]);
            if (p && p.hz > max)
                max = p.hz;
        }
        return max;
    }

    function vrrLabel(vrr: int): string {
        const v = root.normalizeVrr(vrr);
        if (v === 1)
            return Tr.tr("Always");
        if (v === 2)
            return Tr.tr("Automatic");
        return Tr.tr("Never");
    }

    function vrrHint(vrr: int): string {
        const v = root.normalizeVrr(vrr);
        if (v === 1)
            return Tr.tr("Adaptive Sync stays on, including the desktop");
        if (v === 2)
            return Tr.tr("Adaptive Sync only while a window is fullscreen");
        return Tr.tr("Fixed refresh rate; least flicker on flaky HDMI FreeSync");
    }

    function escapeLuaString(s: string): string {
        return String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    }

    function findMonitor(name: string): var {
        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === name)
                return root.monitors[i];
        }
        return null;
    }

    function patchMonitor(name: string, patch: var): var {
        const next = [];
        let updated = null;
        for (let i = 0; i < root.monitors.length; i++) {
            const m = root.monitors[i];
            if (m.name === name) {
                updated = Object.assign({}, m, patch);
                next.push(updated);
            } else {
                next.push(m);
            }
        }
        root.monitors = next;
        return updated;
    }

    function applyLive(mon: var): void {
        if (!mon?.name)
            return;
        const mode = root.modeForHypr(mon.mode);
        const scale = Number(mon.scale) || 1;
        const vrr = root.normalizeVrr(Number.isFinite(Number(mon.vrr)) ? Number(mon.vrr) : root.defaultVrrPolicy);
        const code = `hl.monitor({ output = "${root.escapeLuaString(mon.name)}", mode = "${root.escapeLuaString(mode)}", position = "auto", scale = ${scale}, bitdepth = 8, vrr = ${vrr} })`;
        Quickshell.execDetached(["hyprctl", "eval", code]);
    }

    function generateLua(): string {
        let out = "-- Auto-generated by Caelestia Displays. Do not edit.\n";
        out += "-- Managed from Nexus → Display. Per-output Adaptive Sync: 0 never, 1 always, 2 automatic.\n\n";
        for (let i = 0; i < root.monitors.length; i++) {
            const mon = root.monitors[i];
            if (mon.disabled)
                continue;
            const mode = root.modeForHypr(mon.mode);
            const scale = Number(mon.scale) || 1;
            const vrr = root.normalizeVrr(Number.isFinite(Number(mon.vrr)) ? Number(mon.vrr) : root.policyVrr(mon.name, root.defaultVrrPolicy));
            out += `hl.monitor({\n`;
            out += `    output   = "${root.escapeLuaString(mon.name)}",\n`;
            out += `    mode     = "${root.escapeLuaString(mode)}",\n`;
            out += `    position = "auto",\n`;
            out += `    scale    = ${scale},\n`;
            out += `    bitdepth = 8,\n`;
            out += `    vrr      = ${vrr},\n`;
            out += `})\n\n`;
        }
        if (root.monitors.length === 0) {
            out += `-- Fallback until hyprctl reports outputs\n`;
            out += `hl.monitor({\n`;
            out += `    output   = "",\n`;
            out += `    mode     = "preferred",\n`;
            out += `    position = "auto",\n`;
            out += `    scale    = "auto",\n`;
            out += `})\n`;
        }
        return out;
    }

    function removedMonitorBlocks(existingText: string, currentNames: list<string>): list<var> {
        // Blocks for outputs hyprctl no longer reports (hot-unplug) must
        // survive a persist(): their remembered policy only lives in this
        // generated file. Regenerating from scratch used to lose them.
        const blocks = [];
        const rx = /hl\.monitor\(\{[^}]*\}\)/g;
        let m;
        while ((m = rx.exec(String(existingText || ""))) !== null) {
            const nameMatch = m[0].match(/output\s*=\s*"([^"]+)"/);
            const name = nameMatch ? nameMatch[1] : "";
            if (name.length === 0 || currentNames.includes(name))
                continue;
            blocks.push({
                    name: name,
                    block: m[0]
                });
        }
        return blocks;
    }

    function persist(): void {
        let text = root.generateLua();
        const currentNames = [];
        for (let i = 0; i < root.monitors.length; i++)
            currentNames.push(String(root.monitors[i].name));
        // Re-append blocks for outputs that are currently unplugged so their
        // VRR policy is not forgotten; fresh data (re-attach) wins later.
        const keep = root.removedMonitorBlocks(luaFile.text() ?? "", currentNames);
        if (keep.length > 0) {
            if (!text.endsWith("\n"))
                text += "\n";
            text += "\n-- Hot-unplugged outputs: blocks kept so their remembered policy survives\n";
            for (let i = 0; i < keep.length; i++)
                text += keep[i].block + "\n\n";
        }
        luaFile.setText(text);
    }

    function setMode(name: string, modeStr: string): void {
        const mon = root.patchMonitor(name, {
                mode: modeStr
            });
        root.applyLive(mon);
        root.persist();
        Qt.callLater(() => root.refresh());
    }

    function setScale(name: string, scale: real): void {
        const mon = root.patchMonitor(name, {
                scale: scale
            });
        root.applyLive(mon);
        root.persist();
        Qt.callLater(() => root.refresh());
    }

    function setVrr(name: string, vrr: int): void {
        const policy = root.normalizeVrr(vrr);
        root.rememberVrr(name, policy);
        root.patchMonitor(name, {
                vrr: policy
            });
        // Persist first so hyprctl reload re-reads the authoritative Lua seed.
        // eval alone can leave DRM VRR_ENABLED stuck; reload commits Adaptive Sync.
        root.persist();
        Quickshell.execDetached(["hyprctl", "reload"]);
        postVrrRefresh.restart();
    }

    function ingestJson(raw: string): void {
        root.loading = false;
        root.lastError = "";
        try {
            const data = JSON.parse(raw || "[]");
            if (!Array.isArray(data)) {
                root.lastError = Tr.tr("Could not read monitor list");
                return;
            }
            const next = [];
            for (let i = 0; i < data.length; i++) {
                const m = data[i];
                if (!m || m.disabled)
                    continue;
                const modes = root.dedupeModes(Array.isArray(m.availableModes) ? m.availableModes.slice() : []);
                const mode = root.matchCurrentMode(m.width, m.height, m.refreshRate, modes);
                const name = m.name || "";
                const prev = root.findMonitor(name);
                // Never trust hyprctl's boolean as the policy; default to Automatic (Plasma-like).
                const fallback = prev && prev.vrr !== undefined ? root.normalizeVrr(Number(prev.vrr)) : root.defaultVrrPolicy;
                const vrr = root.normalizeVrr(root.policyVrr(name, fallback));
                if (name && root.vrrPolicies[name] === undefined)
                    root.rememberVrr(name, vrr);
                next.push({
                        name: name,
                        description: m.description || m.model || m.name || "",
                        make: m.make || "",
                        model: m.model || "",
                        width: m.width || 0,
                        height: m.height || 0,
                        refreshRate: m.refreshRate || 0,
                        scale: m.scale || 1,
                        vrr: vrr,
                        vrrActive: !!m.vrr,
                        mode: mode,
                        availableModes: modes,
                        maxHz: root.maxAvailableHz(modes),
                        disabled: !!m.disabled
                    });
            }
            root.monitors = next;
        } catch (e) {
            root.lastError = Tr.tr("Could not read monitor list");
            console.warn("[Displays] parse failed", e);
        }
    }

    Timer {
        id: postVrrRefresh

        interval: 700
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: fetchProc

        command: ["hyprctl", "monitors", "-j"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.ingestJson(text)
        }

        onExited: code => {
            root.loading = false;
            if (code !== 0 && root.monitors.length === 0)
                root.lastError = Tr.tr("Could not read monitor list");
        }
    }

    FileView {
        id: luaFile

        printErrors: false
        path: root.luaPath
        onLoaded: {
            root.ingestLuaPolicies(text());
            root.refresh();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.refresh();
        }
    }

    Connections {
        target: Hyprland

        // Hot-attach/removal must refresh the parsed list so the Nexus page
        // (and persist's merge) see the new/old output without a manual open.
        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name || "";
            if (n.endsWith("v2"))
                return;
            if (n === "monitoradded" || n === "monitorremoved")
                root.refresh();
        }
    }
}
