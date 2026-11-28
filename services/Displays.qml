pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.services
import qs.utils

Singleton {
    id: root

    property var monitors: []
    property string signature: ""
    property string projectionMode: "extend"
    property real externalScale: 1
    property bool hasSavedProfile: false
    property int savedProfileCount: 0
    property double lastApplyMs: 0
    property var profilesMap: ({})
    property bool profilesLoaded: false
    property string pendingHotplugEvent: ""
    property var pendingDisableCmds: []

    signal openPopupRequested
    signal unfamiliarMonitorAdded
    signal applyFinished(bool ok, string message)

    function isInternalName(name: string): bool {
        return name.startsWith("eDP") || name.startsWith("LVDS") || name.startsWith("DSI");
    }

    function fingerprintFor(mon: var): string {
        const desc = String(mon?.description ?? "").trim();
        return desc || String(mon?.name ?? "").trim();
    }

    function computeSignature(list: var): string {
        const fps = [];
        for (let i = 0; i < list.length; i++) {
            const fp = fingerprintFor(list[i]);
            if (fp)
                fps.push(fp);
        }
        fps.sort();
        return fps.join(" || ");
    }

    function shortLabelFor(mon: var): string {
        const name = String(mon?.name ?? "").trim();
        if (isInternalName(name))
            return Tr.tr("Built-in (%1)").arg(name);
        const model = String(mon?.model ?? "").trim();
        if (model && !model.toLowerCase().startsWith("0x"))
            return model;
        const desc = String(mon?.description ?? "").trim();
        if (desc) {
            const parts = desc.split(/\s+/);
            return parts.length >= 2 ? `${parts[0]} ${parts[1]}` : desc.slice(0, 20);
        }
        return name;
    }

    function formatScale(scale: real): string {
        let val = Math.round(Number(scale) * 100) / 100;
        if (!isFinite(val) || val <= 0)
            val = 1;
        if (Math.abs(val - Math.round(val)) < 1e-6)
            return String(Math.round(val));
        return val.toFixed(2).replace(/0+$/, "").replace(/\.$/, "");
    }

    function parseModeString(modeStr: string): var {
        const match = String(modeStr ?? "").trim().match(/^(\d+)x(\d+)@(\d+(?:\.\d+)?)Hz?$/);
        if (!match)
            return null;
        return {
            w: parseInt(match[1], 10),
            h: parseInt(match[2], 10),
            hz: parseFloat(match[3])
        };
    }

    function formatModeId(w: int, h: int, hz: real): string {
        if (Math.abs(hz - Math.round(hz)) < 0.005)
            return `${w}x${h}@${Math.round(hz)}`;
        return `${w}x${h}@${hz.toFixed(2)}`;
    }

    function luaEscape(str: string): string {
        return String(str ?? "").replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    }

    function logicalSize(mon: var): var {
        if (!mon)
            return {
                w: 1920,
                h: 1080
            };
        const rot = ((mon.transform || 0) % 2) === 1;
        const s = Math.max(0.5, Number(mon.scale) || 1);
        const pw = rot ? (mon.height || 1080) : (mon.width || 1920);
        const ph = rot ? (mon.width || 1920) : (mon.height || 1080);
        return {
            w: Math.max(100, Math.round(pw / s)),
            h: Math.max(100, Math.round(ph / s))
        };
    }

    function buildResolutions(rawMon: var, activeW: int, activeH: int, activeHz: real): var {
        const rawModes = rawMon?.availableModes ?? [];
        const resMap = {};
        let nativeKey = "";

        for (let i = 0; i < rawModes.length; i++) {
            const parsed = parseModeString(String(rawModes[i]));
            if (!parsed)
                continue;
            const key = `${parsed.w}x${parsed.h}`;
            if (!nativeKey)
                nativeKey = key;
            if (parsed.w < 800 || parsed.h < 600)
                continue;
            if (!resMap[key])
                resMap[key] = {
                    w: parsed.w,
                    h: parsed.h,
                    rates: {}
                };
            const rHz = Math.round(parsed.hz);
            if (!resMap[key].rates[rHz] || parsed.hz > resMap[key].rates[rHz])
                resMap[key].rates[rHz] = parsed.hz;
        }

        if (activeW > 0 && activeH > 0 && activeHz > 0) {
            const aKey = `${activeW}x${activeH}`;
            if (!resMap[aKey])
                resMap[aKey] = {
                    w: activeW,
                    h: activeH,
                    rates: {}
                };
            const rHz = Math.round(activeHz);
            if (!resMap[aKey].rates[rHz])
                resMap[aKey].rates[rHz] = Math.round(activeHz * 100) / 100;
        }

        const keys = Object.keys(resMap);
        if (keys.length === 0) {
            for (let i = 0; i < rawModes.length; i++) {
                const parsed = parseModeString(String(rawModes[i]));
                if (!parsed)
                    continue;
                const key = `${parsed.w}x${parsed.h}`;
                if (!resMap[key])
                    resMap[key] = {
                        w: parsed.w,
                        h: parsed.h,
                        rates: {}
                    };
                resMap[key].rates[Math.round(parsed.hz)] = parsed.hz;
            }
        }

        const allKeys = Object.keys(resMap);
        if (!nativeKey || !resMap[nativeKey]) {
            allKeys.sort((ka, kb) => (resMap[kb].w - resMap[ka].w) || (resMap[kb].h - resMap[ka].h));
            nativeKey = allKeys.length > 0 ? allKeys[0] : "";
        }

        const compareRes = (ka, kb) => {
            if (ka === nativeKey && kb !== nativeKey)
                return -1;
            if (kb === nativeKey && ka !== nativeKey)
                return 1;
            const a = resMap[ka];
            const b = resMap[kb];
            return (b.w - a.w) || (b.h - a.h);
        };

        const sortedKeys = Object.keys(resMap).sort(compareRes);

        const topKeys = sortedKeys.slice(0, 8);
        const activeKey = `${activeW}x${activeH}`;
        if (activeW > 0 && activeH > 0 && resMap[activeKey] && !topKeys.includes(activeKey)) {
            topKeys.push(activeKey);
            topKeys.sort(compareRes);
        }

        const result = [];
        for (let i = 0; i < topKeys.length; i++) {
            const entry = resMap[topKeys[i]];
            const isNative = topKeys[i] === nativeKey;
            const rateKeys = Object.keys(entry.rates).sort((a, b) => entry.rates[b] - entry.rates[a]).slice(0, 6);
            const rates = [];
            for (let j = 0; j < rateKeys.length; j++) {
                const rHz = parseInt(rateKeys[j], 10);
                const exactHz = entry.rates[rateKeys[j]];
                rates.push({
                    sortIndex: j,
                    mode: formatModeId(entry.w, entry.h, exactHz),
                    hz: Math.round(exactHz * 100) / 100,
                    label: `${rHz} Hz`
                });
            }
            result.push({
                sortIndex: i,
                res: topKeys[i],
                width: entry.w,
                height: entry.h,
                isNative: isNative,
                label: isNative ? Tr.tr("%1 × %2 (Native)").arg(entry.w).arg(entry.h) : `${entry.w} × ${entry.h}`,
                rates: rates
            });
        }
        return result;
    }

    function matchSavedEntry(mon: var, savedList: var): var {
        if (!Array.isArray(savedList))
            return null;
        const fp = fingerprintFor(mon);
        const name = String(mon?.name ?? "").trim();
        for (let i = 0; i < savedList.length; i++) {
            if (fp && savedList[i].description === fp)
                return savedList[i];
        }
        for (let i = 0; i < savedList.length; i++) {
            if (name && savedList[i].name === name)
                return savedList[i];
        }
        return null;
    }

    function saveProfilesToDisk(): void {
        const payload = JSON.stringify({
            profiles: root.profilesMap
        }, null, 2) + "\n";
        Qt.callLater(() => profileStorage.setText(payload));
    }

    function updateProfileMeta(): void {
        const keys = Object.keys(root.profilesMap || {});
        root.savedProfileCount = keys.length;
        root.hasSavedProfile = !!(root.signature && root.profilesMap && root.profilesMap[root.signature]);
    }

    function refresh(): void {
        if (queryProc.running)
            return;
        queryProc.running = true;
    }

    function processMonitorsJson(rawJson: string): void {
        let parsed;
        try {
            parsed = JSON.parse(rawJson);
        } catch (e) {
            return;
        }
        if (!Array.isArray(parsed))
            return;

        // Ignore Hyprland's temporary headless FALLBACK output
        parsed = parsed.filter(m => String(m?.name ?? "") !== "FALLBACK");

        const sig = computeSignature(parsed);
        root.signature = sig;
        const savedProfile = root.profilesMap ? root.profilesMap[sig] : null;
        const savedList = savedProfile && Array.isArray(savedProfile.monitors) ? savedProfile.monitors : [];

        const normalized = [];
        for (let i = 0; i < parsed.length; i++) {
            const m = parsed[i];
            const name = String(m.name ?? "");
            const disabled = !!m.disabled;
            let w = parseInt(m.width ?? 0, 10) || 0;
            let h = parseInt(m.height ?? 0, 10) || 0;
            let hz = Number(m.refreshRate ?? 0) || 0;
            let x = parseInt(m.x ?? 0, 10) || 0;
            let y = parseInt(m.y ?? 0, 10) || 0;
            let scale = Number(m.scale ?? 1) || 1;
            let transform = (parseInt(m.transform ?? 0, 10) || 0) % 4;
            let mirrorOf = String(m.mirrorOf ?? "");
            if (mirrorOf === "none")
                mirrorOf = "";

            const saved = matchSavedEntry(m, savedList);
            if ((w <= 0 || h <= 0) && saved) {
                w = parseInt(saved.width ?? 0, 10) || 0;
                h = parseInt(saved.height ?? 0, 10) || 0;
                hz = Number(saved.refreshRate ?? 60) || 60;
            }
            if (w <= 0 || h <= 0) {
                const rawModes = m.availableModes ?? [];
                for (let k = 0; k < rawModes.length; k++) {
                    const pm = parseModeString(String(rawModes[k]));
                    if (pm) {
                        w = pm.w;
                        h = pm.h;
                        hz = pm.hz;
                        break;
                    }
                }
            }
            if (w <= 0 || h <= 0) {
                w = 1920;
                h = 1080;
                hz = 60;
            }

            if (disabled && saved) {
                x = parseInt(saved.x ?? x, 10) || 0;
                y = parseInt(saved.y ?? y, 10) || 0;
                scale = Number(saved.scale ?? scale) || scale;
                transform = (parseInt(saved.transform ?? transform, 10) || 0) % 4;
            }

            const resolutions = buildResolutions(m, w, h, hz);
            const activeRes = `${w}x${h}`;
            let activeMode = formatModeId(w, h, hz);
            const resEntry = resolutions.find(r => r.res === activeRes);
            if (resEntry && resEntry.rates.length > 0) {
                let best = resEntry.rates[0];
                for (let r = 1; r < resEntry.rates.length; r++) {
                    if (Math.abs(resEntry.rates[r].hz - hz) < Math.abs(best.hz - hz))
                        best = resEntry.rates[r];
                }
                activeMode = best.mode;
            }

            normalized.push({
                index: i + 1,
                name: name,
                description: String(m.description ?? "").trim(),
                shortLabel: shortLabelFor(m),
                isInternal: isInternalName(name),
                width: w,
                height: h,
                refreshRate: Math.round(hz * 100) / 100,
                res: activeRes,
                mode: activeMode,
                x: x,
                y: y,
                scale: Math.round(scale * 100) / 100,
                transform: transform,
                disabled: disabled,
                mirrorOf: mirrorOf,
                resolutions: resolutions
            });
        }

        normalized.sort((a, b) => (a.isInternal === b.isInternal ? 0 : (a.isInternal ? -1 : 1)) || (a.x - b.x) || a.name.localeCompare(b.name));
        for (let i = 0; i < normalized.length; i++)
            normalized[i].index = i + 1;

        root.monitors = normalized;
        updateProfileMeta();
        detectCurrentPreset(normalized);

        if (root.pendingHotplugEvent) {
            const evKind = root.pendingHotplugEvent;
            root.pendingHotplugEvent = "";
            handlePostHotplug(evKind, normalized);
        }
    }

    function detectCurrentPreset(list: var): void {
        const internal = list.find(m => m.isInternal) ?? list[0];
        const externals = list.filter(m => m !== internal);
        const firstActiveExt = externals.find(m => !m.disabled);
        if (firstActiveExt)
            root.externalScale = firstActiveExt.scale;

        if (!internal || externals.length === 0)
            return;
        if (internal.disabled && externals.some(m => !m.disabled)) {
            root.projectionMode = "external";
        } else if (!internal.disabled && externals.every(m => m.disabled)) {
            root.projectionMode = "internal";
        } else if (externals.some(m => m.mirrorOf === internal.name)) {
            root.projectionMode = "mirror";
        } else if (firstActiveExt) {
            if (firstActiveExt.y + logicalSize(firstActiveExt).h <= internal.y + 4)
                root.projectionMode = "extend-up";
            else if (firstActiveExt.x + logicalSize(firstActiveExt).w <= internal.x + 4)
                root.projectionMode = "extend-left";
            else
                root.projectionMode = "extend";
        }
    }

    function handlePostHotplug(kind: string, currentList: var): void {
        // Emergency rescue: never leave 0 displays active after unplugging a dock/monitor
        const anyActive = currentList.some(m => !m.disabled);
        if (!anyActive && currentList.length > 0) {
            const target = currentList.find(m => m.isInternal) ?? currentList[0];
            const rescue = currentList.map(m => Object.assign({}, m, {
                    disabled: m.name !== target.name,
                    mirrorOf: "",
                    x: 0,
                    y: 0
                }));
            applyLayout(rescue, false, "internal");
            return;
        }

        // Restore saved profile for known monitor topologies (e.g. home/office dock)
        if (restoreSavedProfile())
            return;

        // Unknown external monitor connected: open quick projection popup
        if (kind === "added" && currentList.length > 1)
            root.unfamiliarMonitorAdded();
    }

    function layoutMatchesLive(desired: var): bool {
        if (!Array.isArray(desired) || !Array.isArray(root.monitors))
            return false;
        for (let i = 0; i < desired.length; i++) {
            const d = desired[i];
            const live = root.monitors.find(m => m.name === d.name);
            if (!live)
                return false;
            if (!!live.disabled !== !!d.disabled)
                return false;
            if (d.disabled)
                continue;
            if ((live.mirrorOf || "") !== (d.mirrorOf || ""))
                return false;
            if (live.width !== d.width || live.height !== d.height)
                return false;
            if (Math.abs(live.refreshRate - d.refreshRate) > 0.5)
                return false;
            if (Math.abs(live.scale - d.scale) > 0.02)
                return false;
            if ((live.transform || 0) !== (d.transform || 0))
                return false;
            if (!d.mirrorOf && (Math.round(live.x) !== Math.round(d.x) || Math.round(live.y) !== Math.round(d.y)))
                return false;
        }
        return true;
    }

    function restoreSavedProfile(): bool {
        if (!root.signature || !root.profilesMap || !root.profilesMap[root.signature])
            return false;
        const profile = root.profilesMap[root.signature];
        if (!profile || !Array.isArray(profile.monitors) || root.monitors.length === 0)
            return false;

        const mapped = [];
        for (let i = 0; i < root.monitors.length; i++) {
            const live = root.monitors[i];
            const saved = matchSavedEntry(live, profile.monitors);
            if (saved) {
                mapped.push(Object.assign({}, saved, {
                    name: live.name,
                    description: live.description
                }));
            } else {
                mapped.push(Object.assign({}, live));
            }
        }
        if (!mapped.some(m => !m.disabled))
            return false;

        if (layoutMatchesLive(mapped))
            return true;

        return applyLayout(mapped, false, profile.mode || "custom");
    }

    function forgetSavedProfile(): void {
        if (!root.signature || !root.profilesMap || !root.profilesMap[root.signature])
            return;
        const copy = Object.assign({}, root.profilesMap);
        delete copy[root.signature];
        root.profilesMap = copy;
        updateProfileMeta();
        saveProfilesToDisk();
    }

    function buildHyprCommand(mon: var): string {
        const name = String(mon.name ?? "");
        const disabled = !!mon.disabled;
        const mode = String(mon.mode || "preferred");
        const mirror = String(mon.mirrorOf || "");
        const pos = mirror ? "auto" : `${Math.round(mon.x || 0)}x${Math.round(mon.y || 0)}`;
        const scale = formatScale(Number(mon.scale || 1));
        const transform = (parseInt(mon.transform ?? 0, 10) || 0) % 4;

        if (Hypr.usingLua) {
            if (disabled)
                return `eval hl.monitor({ output = "${luaEscape(name)}", mirror = "", disabled = true })`;
            return `eval hl.monitor({ output = "${luaEscape(name)}", mode = "${luaEscape(mode)}", position = "${pos}", scale = "${scale}", transform = ${transform}, mirror = "${luaEscape(mirror)}", disabled = false })`;
        }

        if (disabled)
            return `keyword monitor ${name},disable`;
        let rule = `keyword monitor ${name},${mode},${pos},${scale}`;
        if (transform > 0)
            rule += `,transform,${transform}`;
        if (mirror)
            rule += `,mirror,${mirror}`;
        return rule;
    }

    function applyLayout(layoutMonitors: var, saveProfile = true, modeLabel = "custom"): bool {
        if (!Array.isArray(layoutMonitors) || layoutMonitors.length === 0) {
            root.applyFinished(false, Tr.tr("No displays to configure"));
            return false;
        }

        const sanitized = [];
        for (let i = 0; i < layoutMonitors.length; i++) {
            const item = layoutMonitors[i];
            if (!item || !item.name)
                continue;
            const live = root.monitors.find(m => m.name === item.name);
            sanitized.push({
                name: String(item.name),
                description: String(live?.description ?? item.description ?? "").trim(),
                width: parseInt(item.width ?? live?.width ?? 1920, 10) || 1920,
                height: parseInt(item.height ?? live?.height ?? 1080, 10) || 1080,
                refreshRate: Number(item.refreshRate ?? live?.refreshRate ?? 60) || 60,
                mode: String(item.mode || live?.mode || "preferred"),
                x: Math.round(Number(item.x ?? 0) || 0),
                y: Math.round(Number(item.y ?? 0) || 0),
                scale: Math.max(0.5, Math.min(3, Math.round((Number(item.scale ?? 1) || 1) * 100) / 100)),
                transform: (parseInt(item.transform ?? 0, 10) || 0) % 4,
                disabled: !!item.disabled,
                mirrorOf: String(item.mirrorOf ?? "") === "none" ? "" : String(item.mirrorOf ?? "")
            });
        }

        // Guard 1: At least one display must remain enabled
        const enabledMons = sanitized.filter(m => !m.disabled);
        if (enabledMons.length === 0) {
            root.applyFinished(false, Tr.tr("At least one display must remain enabled"));
            return false;
        }

        // Guard 2: Sanitize mirroring (prevent self-mirror, disabled targets, or cycles)
        const enabledNames = new Set(enabledMons.map(m => m.name));
        for (let i = 0; i < sanitized.length; i++) {
            const m = sanitized[i];
            if (m.disabled || !m.mirrorOf || m.mirrorOf === m.name || !enabledNames.has(m.mirrorOf))
                m.mirrorOf = "";
        }
        const mirrorMap = {};
        for (let i = 0; i < sanitized.length; i++)
            mirrorMap[sanitized[i].name] = sanitized[i].mirrorOf;
        for (let i = 0; i < sanitized.length; i++) {
            const t = sanitized[i].mirrorOf;
            if (t && mirrorMap[t])
                sanitized[i].mirrorOf = "";
        }

        // Normalize origin of active non-mirrored displays to (0, 0)
        const positioned = sanitized.filter(m => !m.disabled && !m.mirrorOf);
        if (positioned.length > 0) {
            let minX = positioned[0].x;
            let minY = positioned[0].y;
            for (let i = 1; i < positioned.length; i++) {
                if (positioned[i].x < minX)
                    minX = positioned[i].x;
                if (positioned[i].y < minY)
                    minY = positioned[i].y;
            }
            for (let i = 0; i < positioned.length; i++) {
                positioned[i].x = Math.round(positioned[i].x - minX);
                positioned[i].y = Math.round(positioned[i].y - minY);
            }
        }

        // Two-phase apply when actively disabling a currently enabled output alongside enabled targets:
        // Phase 1 enables targets AND temporarily parks newly-disabling outputs to the right so Hyprland
        // never sees transient overlapping monitors, then Phase 2 disables them after 450ms once clients bind.
        const enabledOrdered = sanitized.filter(m => !m.disabled && !m.mirrorOf).concat(sanitized.filter(m => !m.disabled && !!m.mirrorOf));
        const disabledOrdered = sanitized.filter(m => m.disabled);
        const newlyDisabling = disabledOrdered.filter(m => {
            const live = root.monitors.find(l => l.name === m.name);
            return live && !live.disabled;
        });

        const enableCmds = [];
        for (let i = 0; i < enabledOrdered.length; i++)
            enableCmds.push(buildHyprCommand(enabledOrdered[i]));

        const disableCmds = [];
        for (let i = 0; i < disabledOrdered.length; i++)
            disableCmds.push(buildHyprCommand(disabledOrdered[i]));

        root.lastApplyMs = Date.now();
        root.projectionMode = modeLabel;
        const firstExt = sanitized.find(m => !isInternalName(m.name) && !m.disabled);
        if (firstExt)
            root.externalScale = firstExt.scale;

        if (saveProfile && root.signature) {
            const nextProfiles = Object.assign({}, root.profilesMap);
            nextProfiles[root.signature] = {
                updatedAt: new Date().toISOString(),
                mode: modeLabel,
                monitors: sanitized
            };
            root.profilesMap = nextProfiles;
            updateProfileMeta();
            saveProfilesToDisk();
        }

        phaseTwoDisableTimer.stop();
        root.pendingDisableCmds = [];

        if (enableCmds.length > 0 && newlyDisabling.length > 0) {
            let parkX = 0;
            for (let i = 0; i < enabledOrdered.length; i++) {
                if (!enabledOrdered[i].mirrorOf)
                    parkX = Math.max(parkX, Math.round(enabledOrdered[i].x) + logicalSize(enabledOrdered[i]).w);
            }
            const phase1Cmds = enableCmds.slice();
            for (let i = 0; i < newlyDisabling.length; i++) {
                const live = root.monitors.find(l => l.name === newlyDisabling[i].name);
                const parked = Object.assign({}, newlyDisabling[i], {
                    disabled: false,
                    mirrorOf: "",
                    x: parkX,
                    y: 0,
                    scale: live ? live.scale : newlyDisabling[i].scale
                });
                parkX += logicalSize(parked).w;
                phase1Cmds.push(buildHyprCommand(parked));
            }
            Hypr.extras.batchMessage(phase1Cmds);
            root.pendingDisableCmds = disableCmds;
            phaseTwoDisableTimer.restart();
        } else {
            const allCmds = enableCmds.concat(disableCmds);
            if (allCmds.length > 0)
                Hypr.extras.batchMessage(allCmds);
            postApplyRefresh.restart();
        }
        root.applyFinished(true, Tr.tr("Display layout applied"));
        return true;
    }

    function applyPreset(mode: string, scale: real): bool {
        const list = root.monitors;
        if (!list || list.length === 0)
            return false;

        const internal = list.find(m => m.isInternal) ?? list[0];
        const externals = list.filter(m => m !== internal);
        const extScale = Math.max(0.5, Math.min(3, Number(scale) || root.externalScale || 1));

        let targetMode = mode;
        if (targetMode === "external" && externals.length === 0)
            targetMode = "extend";

        const cloneBase = (m, overrides) => Object.assign({}, m, {
                transform: 0,
                mirrorOf: "",
                disabled: false,
                x: 0,
                y: 0
            }, overrides);

        const entries = [];
        if (targetMode === "internal") {
            entries.push(cloneBase(internal, {
                disabled: false
            }));
            for (let i = 0; i < externals.length; i++)
                entries.push(cloneBase(externals[i], {
                    disabled: true
                }));
        } else if (targetMode === "external") {
            let cursorX = 0;
            for (let i = 0; i < externals.length; i++) {
                const e = cloneBase(externals[i], {
                    x: cursorX,
                    y: 0,
                    scale: extScale
                });
                cursorX += logicalSize(e).w;
                entries.push(e);
            }
            entries.push(cloneBase(internal, {
                disabled: true
            }));
        } else if (targetMode === "mirror") {
            entries.push(cloneBase(internal, {
                x: 0,
                y: 0
            }));
            for (let i = 0; i < externals.length; i++) {
                entries.push(cloneBase(externals[i], {
                    mode: "preferred",
                    scale: 1,
                    mirrorOf: internal.name
                }));
            }
        } else if (targetMode === "extend-up") {
            const intEntry = cloneBase(internal, {});
            const intW = logicalSize(intEntry).w;
            const extEntries = externals.map(ext => cloneBase(ext, {
                    scale: extScale
                }));
            const totalExtW = extEntries.reduce((sum, e) => sum + logicalSize(e).w, 0);
            const maxExtH = extEntries.reduce((mx, e) => Math.max(mx, logicalSize(e).h), 0);
            let cursorX = Math.round((intW - totalExtW) / 2);
            for (let i = 0; i < extEntries.length; i++) {
                const sz = logicalSize(extEntries[i]);
                extEntries[i].x = cursorX;
                extEntries[i].y = maxExtH - sz.h;
                cursorX += sz.w;
                entries.push(extEntries[i]);
            }
            intEntry.x = 0;
            intEntry.y = maxExtH;
            entries.push(intEntry);
        } else if (targetMode === "extend-left") {
            let cursorX = 0;
            for (let i = 0; i < externals.length; i++) {
                const e = cloneBase(externals[i], {
                    x: cursorX,
                    y: 0,
                    scale: extScale
                });
                cursorX += logicalSize(e).w;
                entries.push(e);
            }
            entries.push(cloneBase(internal, {
                x: cursorX,
                y: 0
            }));
        } else {
            const intEntry = cloneBase(internal, {
                x: 0,
                y: 0
            });
            let cursorX = logicalSize(intEntry).w;
            entries.push(intEntry);
            for (let i = 0; i < externals.length; i++) {
                const e = cloneBase(externals[i], {
                    x: cursorX,
                    y: 0,
                    scale: extScale
                });
                cursorX += logicalSize(e).w;
                entries.push(e);
            }
        }

        return applyLayout(entries, true, targetMode);
    }

    Component.onCompleted: refresh()

    Process {
        id: queryProc

        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.processMonitorsJson(text)
        }
    }

    Timer {
        id: postApplyRefresh

        interval: 350
        onTriggered: root.refresh()
    }

    Timer {
        id: phaseTwoDisableTimer

        interval: 450
        onTriggered: {
            if (Array.isArray(root.pendingDisableCmds) && root.pendingDisableCmds.length > 0) {
                root.lastApplyMs = Date.now();
                Hypr.extras.batchMessage(root.pendingDisableCmds);
                root.pendingDisableCmds = [];
            }
            postApplyRefresh.restart();
        }
    }

    Timer {
        id: hotplugDebounce

        interval: 1500
        onTriggered: root.refresh()
    }

    Connections {
        function onMonitorAdded(name: string): void {
            if (name === "FALLBACK")
                return;
            if (Date.now() - root.lastApplyMs < 4000)
                return;
            root.pendingHotplugEvent = "added";
            hotplugDebounce.restart();
        }

        function onMonitorRemoved(name: string): void {
            if (name === "FALLBACK" || root.isInternalName(name))
                return;
            if (Date.now() - root.lastApplyMs < 4000)
                return;
            root.pendingHotplugEvent = "removed";
            hotplugDebounce.restart();
        }

        function onConfigReloaded(): void {
            if (Date.now() - root.lastApplyMs < 2000)
                return;
            postApplyRefresh.restart();
        }

        target: Hypr
    }

    FileView {
        id: profileStorage

        path: `${Paths.state}/display-profiles.json`
        printErrors: false
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed.profiles === "object" && parsed.profiles !== null)
                    root.profilesMap = parsed.profiles;
            } catch (e) {
                root.profilesMap = ({});
            }
            root.profilesLoaded = true;
            root.updateProfileMeta();
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.profilesMap = ({});
                root.profilesLoaded = true;
                root.updateProfileMeta();
            }
        }
    }
}
