pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    // Long enough to see whether a new mode actually displays, short enough
    // that a black screen is not a disaster
    readonly property int confirmTimeout: 15

    property bool identifying: false
    property var lastApplied: []
    property var pendingRevert: []
    property bool confirming: false
    property int confirmSecondsLeft: 0

    function toggleIdentification(): void {
        identifying = !identifying;
        if (identifying)
            identifyTimer.restart();
        else
            identifyTimer.stop();
    }

    function stopIdentification(): void {
        identifying = false;
        identifyTimer.stop();
    }

    function sourceMonitors(): var {
        if ((Hyprctl.monitors.length ?? 0) > 0)
            return Hyprctl.monitors;
        return Hypr.monitors.values ?? [];
    }

    function enabledMonitors(): var {
        return root.sourceMonitors().filter(m => m && !(m.disabled ?? false));
    }

    // A display showing a copy of another one has no place of its own in the
    // desktop, so it is not part of the arrangement.
    function isMirroring(mon: var): bool {
        const target = String(mon?.mirrorOf ?? "none");
        return target !== "none" && target !== "";
    }

    // hyprctl reports the mirrored output by id, not by name
    function mirrorTargetName(mon: var): string {
        if (!root.isMirroring(mon))
            return "";
        const target = String(mon.mirrorOf);
        const byId = root.findMonitorById(parseInt(target));
        if (byId)
            return byId.name;
        const byName = root.findMonitorByName(target);
        return byName ? byName.name : "";
    }

    function arrangedMonitors(): var {
        return root.enabledMonitors().filter(m => !root.isMirroring(m));
    }

    function findMonitorByName(name: string): var {
        return root.sourceMonitors().find(m => m.name === name) ?? null;
    }

    function findMonitorById(id: int): var {
        return root.sourceMonitors().find(m => m.id == id) ?? null;
    }

    // ── Geometry ──────────────────────────────────────────────
    // hyprctl reports width/height as the untransformed mode size, so a rotated
    // output still says 1920x1080. Swap the axes before the numbers mean
    // anything on screen, then divide by the scale to get logical pixels.
    function logicalSize(mon: var): var {
        return root.logicalSizeOf(mon?.width ?? 0, mon?.height ?? 0, mon?.scale || 1, mon?.transform ?? 0);
    }

    function logicalSizeOf(modeWidth: real, modeHeight: real, scale: real, transform: int): var {
        const swap = (transform % 2) === 1;
        const s = scale || 1;
        return {
            w: Math.round((swap ? modeHeight : modeWidth) / s),
            h: Math.round((swap ? modeWidth : modeHeight) / s)
        };
    }

    // The mode string Hyprland expects, which is always untransformed.
    function modeResolution(mon: var): string {
        return `${mon?.width ?? 0}x${mon?.height ?? 0}`;
    }

    // ── Modes ─────────────────────────────────────────────────
    // availableModes is a flat list of "WxH@RHz" strings. Resolution and
    // refresh rate are not independent, so group them.
    function modesByResolution(mon: var): var {
        const out = ({});
        const modes = mon?.availableModes ?? [];
        for (let i = 0; i < modes.length; i++) {
            const parts = String(modes[i]).split("@");
            if (parts.length !== 2)
                continue;
            const rate = parseFloat(parts[1].replace("Hz", ""));
            if (isNaN(rate))
                continue;
            const rounded = Math.round(rate * 100) / 100;
            if (!out[parts[0]])
                out[parts[0]] = [];
            if (out[parts[0]].indexOf(rounded) === -1)
                out[parts[0]].push(rounded);
        }
        for (const res in out)
            out[res].sort((a, b) => b - a);
        // Drivers that report no modes still have whatever is active now
        if (mon && Object.keys(out).length === 0)
            out[root.modeResolution(mon)] = [Math.round((mon.refreshRate ?? 60) * 100) / 100];
        return out;
    }

    // 60.008 -> "60.01", 60 -> "60". Rounding to a whole number hid the
    // difference between the 59.94 and 60 modes many panels expose.
    function formatRate(rate: real): string {
        return String(Number((rate ?? 0).toFixed(2)));
    }

    function resolutionsFor(mon: var): var {
        const modes = root.modesByResolution(mon);
        return Object.keys(modes).sort((a, b) => {
            const first = a.split("x").map(Number);
            const second = b.split("x").map(Number);
            return second[0] * second[1] - first[0] * first[1];
        });
    }

    function refreshRatesFor(mon: var, resolution: string): var {
        return root.modesByResolution(mon)[resolution] ?? [];
    }

    // Nearest rate the panel actually supports at that resolution
    function bestRateFor(mon: var, resolution: string, preferred: real): real {
        const rates = root.refreshRatesFor(mon, resolution);
        if (rates.length === 0)
            return preferred > 0 ? preferred : (mon?.refreshRate ?? 60);
        let best = rates[0];
        let bestDiff = Infinity;
        for (let i = 0; i < rates.length; i++) {
            const diff = Math.abs(rates[i] - preferred);
            if (diff < bestDiff) {
                bestDiff = diff;
                best = rates[i];
            }
        }
        return best;
    }

    // ── Rect helpers ──────────────────────────────────────────
    function currentRects(): var {
        return root.arrangedMonitors().map(m => {
            const size = root.logicalSize(m);
            return {
                id: m.id,
                name: m.name,
                x: Math.round(m.x ?? 0),
                y: Math.round(m.y ?? 0),
                w: size.w,
                h: size.h
            };
        });
    }

    function rectsOverlap(a: var, b: var): bool {
        return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
    }

    function rectsTouch(a: var, b: var): bool {
        const horizontalTouch = a.x + a.w === b.x || b.x + b.w === a.x;
        const verticalTouch = a.y + a.h === b.y || b.y + b.h === a.y;
        const verticalOverlap = a.y < b.y + b.h && a.y + a.h > b.y;
        const horizontalOverlap = a.x < b.x + b.w && a.x + a.w > b.x;
        return (horizontalTouch && verticalOverlap) || (verticalTouch && horizontalOverlap);
    }

    // Every way `moving` can sit flush against `host` without a gap. The free
    // axis is offered aligned to the host's start/centre/end plus the position
    // the caller already wanted, clamped so the shorter of the two edges stays
    // fully in contact. Without that clamp a far drag lands on a 1px sliver.
    function attachCandidates(moving: var, host: var): var {
        const farY = host.y + host.h - moving.h;
        const farX = host.x + host.w - moving.w;
        const clampedY = Math.max(Math.min(host.y, farY), Math.min(Math.max(host.y, farY), moving.y));
        const clampedX = Math.max(Math.min(host.x, farX), Math.min(Math.max(host.x, farX), moving.x));
        const alignY = [host.y, Math.round(host.y + (host.h - moving.h) / 2), farY];
        const alignX = [host.x, Math.round(host.x + (host.w - moving.w) / 2), farX];
        const out = [];

        for (let i = 0; i <= alignY.length; i++) {
            const y = i < alignY.length ? alignY[i] : clampedY;
            const aligned = i < alignY.length;
            out.push({
                x: host.x - moving.w,
                y: y,
                dirX: -1,
                dirY: 0,
                aligned: aligned
            });
            out.push({
                x: host.x + host.w,
                y: y,
                dirX: 1,
                dirY: 0,
                aligned: aligned
            });
        }
        for (let i = 0; i <= alignX.length; i++) {
            const x = i < alignX.length ? alignX[i] : clampedX;
            const aligned = i < alignX.length;
            out.push({
                x: x,
                y: host.y - moving.h,
                dirX: 0,
                dirY: -1,
                aligned: aligned
            });
            out.push({
                x: x,
                y: host.y + host.h,
                dirX: 0,
                dirY: 1,
                aligned: aligned
            });
        }
        return out;
    }

    // ── Solver ────────────────────────────────────────────────
    // Move `mover` clear of `anchor`. A preferred direction from the drag keeps
    // the cascade going one way, which is what makes it terminate.
    function separate(mover: var, anchor: var, dirX: int, dirY: int): bool {
        if (!root.rectsOverlap(mover, anchor))
            return false;

        if (dirX > 0)
            mover.x = anchor.x + anchor.w;
        else if (dirX < 0)
            mover.x = anchor.x - mover.w;
        else if (dirY > 0)
            mover.y = anchor.y + anchor.h;
        else if (dirY < 0)
            mover.y = anchor.y - mover.h;
        else {
            const right = anchor.x + anchor.w - mover.x;
            const left = mover.x + mover.w - anchor.x;
            const down = anchor.y + anchor.h - mover.y;
            const up = mover.y + mover.h - anchor.y;
            const least = Math.min(right, left, down, up);
            if (least === right)
                mover.x = anchor.x + anchor.w;
            else if (least === left)
                mover.x = anchor.x - mover.w;
            else if (least === down)
                mover.y = anchor.y + anchor.h;
            else
                mover.y = anchor.y - mover.h;
        }
        return true;
    }

    function resolveOverlaps(rects: var, pinnedId: int, dirX: int, dirY: int): void {
        if (rects.length < 2)
            return;

        const pinned = rects.find(r => r.id === pinnedId) ?? rects[0];
        const priority = ({});
        for (let i = 0; i < rects.length; i++) {
            const r = rects[i];
            priority[r.id] = r.id === pinned.id ? -1 : Math.hypot((r.x + r.w / 2) - (pinned.x + pinned.w / 2), (r.y + r.h / 2) - (pinned.y + pinned.h / 2));
        }

        for (let pass = 0; pass < 128; pass++) {
            let moved = false;
            for (let i = 0; i < rects.length; i++) {
                for (let j = i + 1; j < rects.length; j++) {
                    const a = rects[i];
                    const b = rects[j];
                    if (!root.rectsOverlap(a, b))
                        continue;
                    const mover = priority[a.id] > priority[b.id] ? a : b;
                    const anchor = mover === a ? b : a;
                    if (root.separate(mover, anchor, dirX, dirY))
                        moved = true;
                }
            }
            if (!moved)
                return;
        }
    }

    function connectedSet(rects: var, rootId: int): var {
        const connected = new Set([rootId]);
        let grew = true;
        while (grew) {
            grew = false;
            for (let i = 0; i < rects.length; i++) {
                const r = rects[i];
                if (connected.has(r.id))
                    continue;
                for (let j = 0; j < rects.length; j++) {
                    const c = rects[j];
                    if (!connected.has(c.id))
                        continue;
                    if (root.rectsTouch(r, c)) {
                        connected.add(r.id);
                        grew = true;
                        break;
                    }
                }
            }
        }
        return connected;
    }

    // Pull anything stranded back onto the cluster. Always succeeds: the last
    // resort parks the orphan flush against the rightmost connected monitor.
    function ensureConnected(rects: var, pinnedId: int): void {
        if (rects.length < 2)
            return;

        let connected = root.connectedSet(rects, rects.find(r => r.id === pinnedId) ? pinnedId : rects[0].id);
        let guard = rects.length * 4;

        while (connected.size < rects.length && guard-- > 0) {
            let best = null;
            for (let i = 0; i < rects.length; i++) {
                const orphan = rects[i];
                if (connected.has(orphan.id))
                    continue;
                for (let j = 0; j < rects.length; j++) {
                    const host = rects[j];
                    if (!connected.has(host.id))
                        continue;
                    const candidates = root.attachCandidates(orphan, host);
                    for (let k = 0; k < candidates.length; k++) {
                        const candidate = candidates[k];
                        const probe = {
                            x: candidate.x,
                            y: candidate.y,
                            w: orphan.w,
                            h: orphan.h
                        };
                        let clash = false;
                        for (let l = 0; l < rects.length; l++) {
                            if (rects[l].id === orphan.id)
                                continue;
                            if (root.rectsOverlap(probe, rects[l])) {
                                clash = true;
                                break;
                            }
                        }
                        if (clash)
                            continue;
                        const distance = Math.hypot(candidate.x - orphan.x, candidate.y - orphan.y);
                        if (best === null || distance < best.distance)
                            best = {
                                orphan: orphan,
                                x: candidate.x,
                                y: candidate.y,
                                distance: distance
                            };
                    }
                }
            }

            if (best === null) {
                const orphan = rects.find(r => !connected.has(r.id));
                let anchor = null;
                for (let i = 0; i < rects.length; i++) {
                    const r = rects[i];
                    if (connected.has(r.id) && (anchor === null || r.x + r.w > anchor.x + anchor.w))
                        anchor = r;
                }
                if (!orphan || !anchor)
                    return;
                orphan.x = anchor.x + anchor.w;
                orphan.y = anchor.y;
            } else {
                best.orphan.x = best.x;
                best.orphan.y = best.y;
            }
            connected = root.connectedSet(rects, pinnedId);
        }
    }

    function normalizeOrigin(rects: var): void {
        if (rects.length === 0)
            return;
        let minX = Infinity;
        let minY = Infinity;
        for (let i = 0; i < rects.length; i++) {
            minX = Math.min(minX, rects[i].x);
            minY = Math.min(minY, rects[i].y);
        }
        if (minX === 0 && minY === 0)
            return;
        for (let i = 0; i < rects.length; i++) {
            rects[i].x -= minX;
            rects[i].y -= minY;
        }
    }

    // Always returns a usable layout: overlap-free, and connected in every case
    // reachable from the UI. Never bails out, so a drag always does something.
    function solveLayout(rects: var, pinnedId: int, dirX: int, dirY: int, normalize: bool): var {
        root.resolveOverlaps(rects, pinnedId, dirX, dirY);
        root.ensureConnected(rects, pinnedId);
        root.resolveOverlaps(rects, pinnedId, 0, 0);
        root.ensureConnected(rects, pinnedId);
        if (normalize)
            root.normalizeOrigin(rects);
        return rects;
    }

    // ── Validation ────────────────────────────────────────────
    function hasOverlaps(rects: var): bool {
        for (let i = 0; i < rects.length; i++)
            for (let j = i + 1; j < rects.length; j++)
                if (root.rectsOverlap(rects[i], rects[j]))
                    return true;
        return false;
    }

    function isContiguous(rects: var): bool {
        if (rects.length < 2)
            return true;
        return root.connectedSet(rects, rects[0].id).size === rects.length;
    }

    // Empty when Hyprland would take the layout as it stands.
    function layoutIssue(rects: var): string {
        if (!rects || rects.length === 0)
            return "";
        if (root.hasOverlaps(rects))
            return qsTr("Displays must not overlap");
        if (!root.isContiguous(rects))
            return qsTr("Every display must touch another");
        return "";
    }

    // ── Drag snapping ─────────────────────────────────────────
    // Nearest of `targets` to `value`, or NaN when none is within `threshold`.
    function nearestWithin(value: real, targets: var, threshold: real): real {
        let best = NaN;
        let bestDiff = threshold;
        for (let i = 0; i < targets.length; i++) {
            const diff = Math.abs(targets[i] - value);
            if (diff <= bestDiff) {
                bestDiff = diff;
                best = targets[i];
            }
        }
        return best;
    }

    function snapOr(value: real, targets: var, threshold: real): real {
        const snapped = root.nearestWithin(value, targets, threshold);
        return isNaN(snapped) ? value : snapped;
    }

    // Every distinct target within `threshold` of `value`.
    function allWithin(value: real, targets: var, threshold: real): var {
        const out = [];
        for (let i = 0; i < targets.length; i++)
            if (Math.abs(targets[i] - value) <= threshold && out.indexOf(targets[i]) === -1)
                out.push(targets[i]);
        return out;
    }

    // Magnetic, not forced: the display goes where the pointer puts it and only
    // jumps when an edge lands within `threshold` logical pixels of a
    // neighbour. Nothing else ever moves, so a drag cannot shuffle the layout
    // behind the user's back; a drop that leaves a gap stays where it was put
    // and Apply refuses it instead.
    function snapDrag(rects: var, movingId: int, desiredX: real, desiredY: real, threshold: real): var {
        const desired = {
            x: Math.round(desiredX),
            y: Math.round(desiredY)
        };
        const moving = rects.find(r => r.id === movingId);
        if (!moving)
            return desired;

        // Butting against an edge, then the three ways to line edges up
        const flushX = [];
        const flushY = [];
        const alignX = [];
        const alignY = [];

        for (let i = 0; i < rects.length; i++) {
            const host = rects[i];
            if (host.id === movingId)
                continue;
            flushX.push(host.x - moving.w, host.x + host.w);
            flushY.push(host.y - moving.h, host.y + host.h);
            alignX.push(host.x, host.x + host.w - moving.w, Math.round(host.x + (host.w - moving.w) / 2));
            alignY.push(host.y, host.y + host.h - moving.h, Math.round(host.y + (host.h - moving.h) / 2));
        }

        // Butting up on one axis pairs with lining up on the other, never with
        // butting up on both: that only ever meets at a corner, which Hyprland
        // counts as a detached display.
        const alignedX = root.snapOr(desired.x, alignX, threshold);
        const alignedY = root.snapOr(desired.y, alignY, threshold);
        const attachX = root.allWithin(desired.x, flushX, threshold);
        const attachY = root.allWithin(desired.y, flushY, threshold);
        const candidates = [];

        for (let i = 0; i < attachX.length; i++)
            candidates.push({
                x: attachX[i],
                y: alignedY
            });
        for (let i = 0; i < attachY.length; i++)
            candidates.push({
                x: alignedX,
                y: attachY[i]
            });
        candidates.push({
            x: alignedX,
            y: alignedY
        });
        candidates.push(desired);

        // Every candidate sits within `threshold` on each axis, so a landing
        // that leaves a layout Hyprland accepts is always worth more than the
        // raw drop point, and a snapped axis always worth more than a free one.
        // Otherwise the raw point wins every time it happens to be legal and
        // edges end up a pixel or two out.
        const bonus = threshold * 2;
        const penalty = threshold * 8;
        let best = null;

        for (let i = 0; i < candidates.length; i++) {
            const candidate = candidates[i];
            const trial = rects.map(r => r.id === movingId ? {
                    id: r.id,
                    x: candidate.x,
                    y: candidate.y,
                    w: r.w,
                    h: r.h
                } : r);
            const valid = !root.hasOverlaps(trial) && root.isContiguous(trial);
            const snaps = (candidate.x !== desired.x ? 1 : 0) + (candidate.y !== desired.y ? 1 : 0);
            const score = Math.hypot(candidate.x - desired.x, candidate.y - desired.y) - snaps * bonus + (valid ? 0 : penalty);
            if (best === null || score < best.score)
                best = {
                    x: candidate.x,
                    y: candidate.y,
                    score: score
                };
        }

        return {
            x: best.x,
            y: best.y
        };
    }

    // ── Applying ──────────────────────────────────────────────
    function luaString(value: string): string {
        return `"${value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"")}"`;
    }

    // A monitor that is off keeps reporting its mode, position and mode list,
    // so turning it back on can restore what it had instead of guessing.
    function specFor(mon: var, overrides: var): var {
        const o = overrides ?? ({});
        if (o.disabled ?? (mon.disabled ?? false))
            return {
                name: mon.name,
                disabled: true
            };

        const resolution = o.resolution ?? root.modeResolution(mon);
        const requested = o.refreshRate ?? (mon.refreshRate ?? 60);
        return {
            name: mon.name,
            disabled: false,
            mirror: o.mirror ?? root.mirrorTargetName(mon),
            resolution: resolution,
            refreshRate: root.bestRateFor(mon, resolution, requested),
            scale: o.scale ?? (mon.scale || 1),
            transform: o.transform ?? (mon.transform ?? 0),
            x: o.x ?? (mon.x ?? 0),
            y: o.y ?? (mon.y ?? 0)
        };
    }

    // Hyprland remembers `disabled` between commands, so every enabled monitor
    // has to say so explicitly or one turned off earlier silently stays off.
    function monitorCommand(spec: var): string {
        if (!Hypr.usingLua) {
            if (spec.disabled)
                return `keyword monitor ${spec.name},disable`;

            const mode = `${spec.resolution}@${spec.refreshRate.toFixed(3)}`;
            const position = `${Math.round(spec.x)}x${Math.round(spec.y)}`;
            let keyword = `keyword monitor ${spec.name},${mode},${position},${spec.scale}`;
            if (spec.transform !== 0)
                keyword += `,transform,${spec.transform}`;
            if (spec.mirror)
                keyword += `,mirror,${spec.mirror}`;
            return keyword;
        }

        if (spec.disabled)
            return `eval hl.monitor({ output = ${root.luaString(spec.name)}, disabled = true })`;

        const mode = `${spec.resolution}@${spec.refreshRate.toFixed(3)}`;
        const position = `${Math.round(spec.x)}x${Math.round(spec.y)}`;
        // `mirror` is as sticky as `disabled`, so it always has to be stated
        let lua = `hl.monitor({ output = ${root.luaString(spec.name)}, disabled = false, mirror = ${root.luaString(spec.mirror || "none")}, mode = ${root.luaString(mode)}, position = ${root.luaString(position)}, scale = ${spec.scale}`;
        if (spec.transform !== 0)
            lua += `, transform = ${spec.transform}`;
        lua += " })";
        return `eval ${lua}`;
    }

    // One batch for the whole layout. Applying monitors one at a time makes
    // Hyprland see transient overlaps and shuffle them itself.
    function sendSpecs(specs: var): void {
        if (!specs || specs.length === 0)
            return;
        Hypr.extras.batchMessage(specs.map(root.monitorCommand));
        root.lastApplied = specs;
        Hyprctl.update();
        verifyTimer.restart();
    }

    // Every enabled monitor, exactly as it stands. Taken before a change so
    // there is something to go back to.
    function snapshotSpecs(): var {
        return root.sourceMonitors().filter(m => m).map(m => root.specFor(m, ({})));
    }

    // A mode, scale or rotation that the hardware cannot show leaves a black
    // screen and no way to undo it, so every change has to be confirmed and
    // goes back on its own if it is not. Changes made while already waiting
    // keep the original snapshot: reverting should undo the whole run.
    function apply(specs: var): void {
        if (!specs || specs.length === 0)
            return;

        if (!root.confirming) {
            root.pendingRevert = root.snapshotSpecs();
            root.confirming = true;
            root.confirmSecondsLeft = root.confirmTimeout;
            confirmTimer.restart();
        }

        root.sendSpecs(specs);
    }

    function keepChanges(): void {
        confirmTimer.stop();
        root.confirming = false;
        root.pendingRevert = [];
        root.confirmSecondsLeft = 0;
    }

    function revertChanges(): void {
        const specs = root.pendingRevert;
        confirmTimer.stop();
        root.confirming = false;
        root.pendingRevert = [];
        root.confirmSecondsLeft = 0;
        root.sendSpecs(specs);
    }

    // Hyprland anchors the desktop at 0,0, so slide the whole arrangement back
    // there first. Without it a layout drifts further out with every edit.
    function applyArrangement(rects: var): void {
        root.normalizeOrigin(rects);

        const specs = [];
        for (let i = 0; i < rects.length; i++) {
            const rect = rects[i];
            const mon = root.findMonitorByName(rect.name);
            if (!mon)
                continue;
            if (Math.round(mon.x ?? 0) === Math.round(rect.x) && Math.round(mon.y ?? 0) === Math.round(rect.y))
                continue;
            specs.push(root.specFor(mon, {
                x: rect.x,
                y: rect.y
            }));
        }
        root.apply(specs);
    }

    // Changing mode, scale or rotation resizes the monitor, which can shove
    // neighbours or leave a hole. Re-solve the whole layout around it.
    function applyMonitorChange(monitorName: string, overrides: var): void {
        const mon = root.findMonitorByName(monitorName);
        if (!mon)
            return;

        const spec = root.specFor(mon, overrides);
        const parts = spec.resolution.split("x").map(Number);
        const size = root.logicalSizeOf(parts[0], parts[1], spec.scale, spec.transform);

        const rects = root.currentRects();
        const target = rects.find(r => r.name === monitorName);
        if (target) {
            target.w = size.w;
            target.h = size.h;
            root.solveLayout(rects, target.id, 0, 0, true);
        }

        const specs = [];
        for (let i = 0; i < rects.length; i++) {
            const rect = rects[i];
            const other = root.findMonitorByName(rect.name);
            if (!other)
                continue;
            if (rect.name === monitorName) {
                spec.x = rect.x;
                spec.y = rect.y;
                specs.push(spec);
            } else if (Math.round(other.x ?? 0) !== Math.round(rect.x) || Math.round(other.y ?? 0) !== Math.round(rect.y)) {
                specs.push(root.specFor(other, {
                    x: rect.x,
                    y: rect.y
                }));
            }
        }
        if (specs.length === 0)
            specs.push(spec);
        root.apply(specs);
    }

    function setPosition(monitorName: string, x: real, y: real): void {
        const mon = root.findMonitorByName(monitorName);
        if (!mon)
            return;
        const spec = root.specFor(mon, {
            x: x,
            y: y
        });
        root.apply([spec]);
    }

    // Explicit placement from the dashboard buttons. The direction is known, so
    // the solver can push whatever is in the way out along it.
    function arrange(monitorName: string, pos: string, relativeToId: int): void {
        const target = root.findMonitorById(relativeToId);
        const moving = root.findMonitorByName(monitorName);
        if (!target || !moving || target.id === moving.id)
            return;

        const rects = root.currentRects();
        const anchor = rects.find(r => r.id === target.id);
        const mover = rects.find(r => r.id === moving.id);
        if (!anchor || !mover)
            return;

        let dirX = 0;
        let dirY = 0;
        if (pos === "left") {
            mover.x = anchor.x - mover.w;
            mover.y = anchor.y;
            dirX = -1;
        } else if (pos === "right") {
            mover.x = anchor.x + anchor.w;
            mover.y = anchor.y;
            dirX = 1;
        } else if (pos === "top") {
            mover.x = anchor.x;
            mover.y = anchor.y - mover.h;
            dirY = -1;
        } else if (pos === "bottom") {
            mover.x = anchor.x;
            mover.y = anchor.y + anchor.h;
            dirY = 1;
        }

        root.applyArrangement(root.solveLayout(rects, mover.id, dirX, dirY, true));
    }

    // Turning a display off, or making it mirror another, takes it out of the
    // arrangement and leaves a hole. A hole is dead space the pointer cannot
    // cross, stranding the displays either side of it, so it gets closed.
    // Closing it moves the others, so the whole arrangement is remembered first
    // and put back when the display comes back.
    function setPresence(monitorName: string, present: bool, overrides: var): void {
        const mon = root.findMonitorByName(monitorName);
        if (!mon)
            return;

        const specs = [];
        let rects;

        if (present) {
            const size = root.logicalSize(mon);
            const saved = persist.savedPositions[monitorName];
            rects = root.currentRects();
            rects.push({
                id: mon.id,
                name: mon.name,
                x: Math.round(saved?.x ?? mon.x ?? 0),
                y: Math.round(saved?.y ?? mon.y ?? 0),
                w: size.w,
                h: size.h
            });

            // Put every display back where it was before this one was turned
            // off, so a disable/enable round trip is a no-op
            for (let i = 0; i < rects.length; i++) {
                const remembered = persist.savedPositions[rects[i].name];
                if (remembered) {
                    rects[i].x = remembered.x;
                    rects[i].y = remembered.y;
                }
            }

            specs.push(root.specFor(mon, overrides));
        } else {
            const positions = ({});
            const current = root.currentRects();
            for (let i = 0; i < current.length; i++)
                positions[current[i].name] = {
                    x: current[i].x,
                    y: current[i].y
                };
            persist.savedPositions = positions;

            rects = current.filter(r => r.name !== monitorName);
            specs.push(root.specFor(mon, overrides));
        }

        if (rects.length > 0)
            root.solveLayout(rects, present ? mon.id : rects[0].id, 0, 0, true);

        for (let i = 0; i < rects.length; i++) {
            const rect = rects[i];
            const other = root.findMonitorByName(rect.name);
            if (!other)
                continue;
            if (rect.name === monitorName) {
                specs[0].x = rect.x;
                specs[0].y = rect.y;
            } else if (Math.round(other.x ?? 0) !== rect.x || Math.round(other.y ?? 0) !== rect.y) {
                specs.push(root.specFor(other, {
                    x: rect.x,
                    y: rect.y
                }));
            }
        }

        root.apply(specs);
    }

    function setEnabled(monitorName: string, enabled: bool): void {
        const mon = root.findMonitorByName(monitorName);
        if (!mon || !(mon.disabled ?? false) === enabled)
            return;
        // Turning off the only display leaves nothing to turn it back on with
        if (!enabled && root.enabledMonitors().length <= 1)
            return;

        root.setPresence(monitorName, enabled, {
            disabled: !enabled,
            mirror: ""
        });
    }

    // An empty target extends instead of mirroring. A display cannot mirror
    // itself, and mirroring the last one with a place of its own would leave
    // the desktop with no arrangement at all.
    function setMirror(monitorName: string, targetName: string): void {
        const mon = root.findMonitorByName(monitorName);
        if (!mon || monitorName === targetName)
            return;
        if (targetName && root.arrangedMonitors().length <= 1)
            return;
        if (targetName && !root.findMonitorByName(targetName))
            return;

        root.setPresence(monitorName, !targetName, {
            disabled: false,
            mirror: targetName
        });
    }

    function rotate(monitorName: string, angle: int): void {
        const transform = angle === 90 ? 1 : angle === 180 ? 2 : angle === 270 ? 3 : 0;
        root.applyMonitorChange(monitorName, {
            transform: transform
        });
    }

    function setScale(monitorName: string, scale: real): void {
        root.applyMonitorChange(monitorName, {
            scale: Math.max(0.5, Math.min(3.0, scale))
        });
    }

    function setMode(monitorName: string, resolution: string, refreshRate: real): void {
        root.applyMonitorChange(monitorName, {
            resolution: resolution,
            refreshRate: refreshRate
        });
    }

    function setRefreshRate(monitorName: string, refreshRate: real): void {
        root.applyMonitorChange(monitorName, {
            refreshRate: Math.max(1, refreshRate)
        });
    }

    // Keeps the closest rate the new resolution supports instead of blindly
    // reusing the old one, which Hyprland would silently round anyway.
    function setResolution(monitorName: string, resolution: string): void {
        const mon = root.findMonitorByName(monitorName);
        if (!mon)
            return;
        root.applyMonitorChange(monitorName, {
            resolution: resolution,
            refreshRate: root.bestRateFor(mon, resolution, mon.refreshRate ?? 60)
        });
    }

    // Hyprland occasionally lands somewhere else when several outputs move at
    // once. Re-send only what actually drifted, and only once.
    Timer {
        id: verifyTimer

        interval: 700
        onTriggered: {
            const specs = root.lastApplied;
            root.lastApplied = [];
            if (specs.length === 0)
                return;

            const drift = specs.filter(spec => {
                const mon = root.findMonitorByName(spec.name);
                return mon && (Math.round(mon.x ?? 0) !== Math.round(spec.x) || Math.round(mon.y ?? 0) !== Math.round(spec.y));
            });
            if (drift.length === 0)
                return;

            Hypr.extras.batchMessage(drift.map(root.monitorCommand));
            Hyprctl.update();
        }
    }

    // Kept across reloads so turning a display back on still restores the
    // arrangement it was turned off from
    PersistentProperties {
        id: persist

        property var savedPositions: ({})

        reloadableId: "monitorArrangement"
    }

    Timer {
        id: confirmTimer

        interval: 1000
        repeat: true
        onTriggered: {
            root.confirmSecondsLeft--;
            if (root.confirmSecondsLeft <= 0)
                root.revertChanges();
        }
    }

    // Auto-dismiss identify overlay after 5 seconds
    Timer {
        id: identifyTimer

        interval: 5000
        onTriggered: root.identifying = false
    }
}
