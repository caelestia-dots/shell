pragma Singleton

import QtQuick

// Resolves overlaps between the shell's drawers.
//
// Every panel registered here is anchored, usually to the same screen edge, so
// writing x/y/width/height on them is either rejected by Qt or undone by the next
// layout pass. Panels opt in instead by exposing four overrides which they fold
// into their own anchors and implicit size:
//
//   readonly property real naturalWidth: <the width the panel wants>
//   property real layoutMaxWidth: 0   // cap on naturalWidth
//   property real layoutShiftX: 0      // px added to the horizontal anchor margin
//   property real layoutShiftY: 0      // px added to the vertical anchor margin
//   property bool layoutHidden: false  // set when there is no room left at all
//
//   implicitWidth: layoutMaxWidth > 0 ? Math.min(naturalWidth, layoutMaxWidth) : naturalWidth
//   anchors.rightMargin: <original> + layoutShiftX
//   visible: <original> && !layoutHidden
//
// A panel has to apply every shift it can be given, or the manager will keep
// nudging a panel that never moves: `baseRect` backs the last shift out of the
// position it reads, so a shift that is not applied is not merely ignored, it
// corrupts the geometry the next pass measures from and the panel oscillates
// between nudged and not. A shift on an axis registered as "none" is never
// generated, so a panel only needs the anchors for the edges it registers.
//
// `layoutMaxWidth` only helps when a panel is wider than the space available.
// Drawers sitting flush against the same edge cannot be separated by shrinking
// one of them, so those get nudged along their anchor instead. Both are monotone
// in the panel's natural size, so a pass never has to read an item back to know
// where it ended up.
//
// Below `minWidth` of room the cap runs out of meaning, and `0` is already the
// "uncapped" sentinel, so such a panel is hidden through `layoutHidden` instead
// of being drawn over the panel that took the space.
Item {
    id: root

    // Higher value wins a contested spot. Higher priority panels are measured
    // first and never adjusted.
    readonly property int priorityLow: 0
    readonly property int priorityMedium: 50
    readonly property int priorityHigh: 100

    // Gap kept between two panels that would otherwise touch.
    property int spacing: 4

    // Narrower than this a panel is a sliver rather than a panel, so a cap this
    // small hides it instead of squeezing it. A 4px strip of notification card
    // reads as a rendering glitch, not as a layout result.
    property int minWidth: 64

    // Flip to trace every pass. Off by default: the debounce timer fires on each
    // frame of a drawer animation, so an always-on trace floods the journal.
    // Silenced with QT_LOGGING_RULES="caelestia.layoutmanager.debug=false".
    property bool debug: false

    property int passCount: 0

    property var registry: ({})

    // Registry keys are global to this singleton while the panels they point at are
    // per screen, so callers must scope their keys with panelKey().
    function panelKey(screenName: string, panelId: string): string {
        return `${screenName}/${panelId}`;
    }

    // `hEdge` and `vEdge` name the screen edges the panel is anchored to, which
    // decide which way it may be nudged: "left"/"right"/"top"/"bottom", or "none"
    // for a freely positioned panel. "none" panels act as blockers only.
    function registerPanel(key: string, panel: Item, priority: int, hEdge: string, vEdge: string) {
        if (key in registry)
            resetPanel(registry[key]);
        registry[key] = {
            key: key,
            panel: panel,
            priority: priority,
            hEdge: hEdge,
            vEdge: vEdge,
            appliedX: 0,
            appliedY: 0,
            appliedMaxWidth: 0,
            hidden: false,
            history: []
        };

        requestLayoutUpdate();
    }

    function unregisterPanel(key: string) {
        if (!(key in registry))
            return;
        if (debug)
            trace(`unregister ${key}`);
        resetPanel(registry[key]);
        delete registry[key];
    }

    function setPanelPriority(key: string, priority: int) {
        if (!(key in registry))
            return;
        registry[key].priority = priority;
        requestLayoutUpdate();
    }

    function requestLayoutUpdate() {
        layoutUpdateTimer.restart();
    }

    function recalculate() {
        passCount++;
        const entries = [];
        const skipped = [];
        for (const key in registry) {
            if (isRenderable(registry[key]))
                entries.push(registry[key]);
            else
                skipped.push(registry[key]);
        }
        entries.sort((a, b) => b.priority - a.priority);

        if (debug)
            trace(`pass ${passCount} · ${Object.keys(registry).length} registered · ${entries.length} placed · ${skipped.length} skipped · spacing=${root.spacing}`);

        const placed = [];
        for (const entry of entries) {
            const base = baseRect(entry);

            if (debug)
                trace(`  place ${entry.key}  prio=${entry.priority}  edges=${entry.hEdge}/${entry.vEdge}  natural=${num(entry.panel.naturalWidth)}  base=${fmtRect(base)}`);

            // Recomputed from zero every pass: a shift is only ever justified by a
            // blocker present in this pass, so it unwinds on its own once the
            // blocker goes away.
            const fit = resolve(entry, base, placed);
            const settled = apply(entry, fit.maxWidth, fit.shiftX, fit.shiftY);
            if (debug) {
                if (oscillating(entry, settled))
                    trace(`    WARN ${entry.key} oscillating: ${entry.history.join(" → ")}`);
                else
                    trace(`  done  ${entry.key}  maxWidth=${num(settled.maxWidth)} shiftX=${num(settled.shiftX)} shiftY=${num(settled.shiftY)}  ${settled.hidden ? "hidden, no room" : settled.changed ? "changed" : "unchanged"}`);
            }

            // A panel with no room is not drawn, so it reserves nothing for the
            // panels placed after it either.
            if (!settled.hidden)
                placed.push({
                    key: entry.key,
                    rect: resolvedRect(entry, base, fit.maxWidth, fit.shiftX, fit.shiftY)
                });
        }

        if (debug) {
            for (const entry of skipped)
                trace(`  skip  ${entry.key}  ${skipReason(entry.panel)}`);
            trace(`pass ${passCount} done`);
        }
    }

    // Nudges and caps for one panel against everything already placed this pass,
    // least disruptive first: slide along the horizontal anchor, then the vertical
    // one, and only then shrink.
    //
    // A nudge is accepted only once it has been checked to actually clear the
    // blocker. A panel pinned to the far edge of the screen has nowhere to slide
    // to when the blocker sits towards the middle, and taking the clamped nudge
    // anyway would leave the panel overlapping while the pass still counted it as
    // placed. Falling through to the cap is what makes a lower priority panel give
    // way instead of being shoved into its neighbour.
    function resolve(entry, base: rect, placed: list<var>) {
        let maxWidth = Infinity;
        let shiftX = 0;
        let shiftY = 0;

        // A sweep only ever tightens the result, so the number of blockers bounds
        // the work; a sweep that changes nothing settles the panel.
        for (let sweep = 0; sweep <= placed.length; sweep++) {
            let changed = false;

            for (const other of placed) {
                const blocker = other.rect;
                const rect = resolvedRect(entry, base, maxWidth, shiftX, shiftY);
                if (!overlaps(rect, blocker, root.spacing))
                    continue;

                // Nudging horizontally is preferred: the shell already stacks its
                // drawers vertically, so a vertical shove is the disruptive one.
                const dx = shiftForX(entry, rect, shiftX, blocker);
                if (dx !== null) {
                    const wanted = clampShiftX(entry, dx);
                    if (clears(entry, base, maxWidth, wanted, shiftY, blocker)) {
                        if (debug)
                            trace(`    vs ${other.key}  shiftX ${num(shiftX)} → ${num(wanted)}${wanted === dx ? "" : `  (clamped from ${num(dx)})`}`);
                        shiftX = wanted;
                        changed = true;
                        continue;
                    }
                }

                const dy = shiftForY(entry, rect, shiftY, blocker);
                if (dy !== null) {
                    const wanted = clampShiftY(entry, dy);
                    if (clears(entry, base, maxWidth, shiftX, wanted, blocker)) {
                        if (debug)
                            trace(`    vs ${other.key}  shiftY ${num(shiftY)} → ${num(wanted)}${wanted === dy ? "" : `  (clamped from ${num(dy)})`}`);
                        shiftY = wanted;
                        changed = true;
                        continue;
                    }
                }

                const cap = capFor(entry, blocker, shiftX);
                if (cap < maxWidth) {
                    if (debug)
                        trace(`    vs ${other.key}  cap ${num(maxWidth)} → ${num(cap)}  (no room to move)`);
                    maxWidth = cap;
                    changed = true;
                }
            }

            if (!changed)
                break;
        }

        return {
            maxWidth,
            shiftX,
            shiftY
        };
    }

    // Whether the panel clears `other` at the given shift and width cap. A nudge
    // that gets clamped back onto the geometry the panel already has still fails
    // this test, so the cap gets its turn.
    function clears(entry, base: rect, maxWidth: real, shiftX: real, shiftY: real, other: rect): bool {
        return !overlaps(resolvedRect(entry, base, maxWidth, shiftX, shiftY), other, root.spacing);
    }

    function apply(entry, maxWidth: real, shiftX: real, shiftY: real) {
        const panel = entry.panel;
        // Less room than a panel can usefully occupy is no room: the cap would
        // round to the same value it uses to mean "uncapped", and a sliver drawn
        // over the panel that took the space is worse than no panel at all. The
        // width is left uncapped underneath, which is what lets a later pass
        // measure the panel and bring it back once the blocker is gone.
        const noRoom = maxWidth !== Infinity && maxWidth < root.minWidth;
        const width = noRoom || maxWidth === Infinity ? 0 : Math.floor(maxWidth);
        let changed = false;

        if (entry.appliedMaxWidth !== width) {
            entry.appliedMaxWidth = width;
            panel.layoutMaxWidth = width;
            changed = true;
        }
        if (entry.hidden !== noRoom) {
            entry.hidden = noRoom;
            panel.layoutHidden = noRoom;
            changed = true;
        }
        if (entry.appliedX !== shiftX) {
            entry.appliedX = shiftX;
            panel.layoutShiftX = shiftX;
            changed = true;
        }
        if (entry.appliedY !== shiftY) {
            entry.appliedY = shiftY;
            panel.layoutShiftY = shiftY;
            changed = true;
        }

        return {
            changed,
            hidden: noRoom,
            maxWidth: width,
            shiftX,
            shiftY
        };
    }

    function resetPanel(entry) {
        const panel = entry.panel;
        if (entry.appliedMaxWidth !== 0) {
            entry.appliedMaxWidth = 0;
            panel.layoutMaxWidth = 0;
        }
        if (entry.hidden) {
            entry.hidden = false;
            panel.layoutHidden = false;
        }
        if (entry.appliedX !== 0) {
            entry.appliedX = 0;
            panel.layoutShiftX = 0;
        }
        if (entry.appliedY !== 0) {
            entry.appliedY = 0;
            panel.layoutShiftY = 0;
        }
    }

    // A panel this manager hid is still laid out, so it stays in the pass: that is
    // what lets a later pass find room for it again. Dropping it here would strand
    // it, since nothing would ever write `layoutHidden` back to false.
    function isRenderable(entry: var): bool {
        const panel = entry.panel;
        return panel !== null && (panel.visible || entry.hidden) && panel.Window !== null && panel.width > 0 && panel.height > 0;
    }

    // The panel's unshifted, uncapped geometry. Previous pass's shift and cap are
    // backed out so a pass is a pure function of the panel's natural size, its
    // unshifted position and the blockers present, which is what makes repeated
    // passes converge and lets stale adjustments unwind.
    function baseRect(entry): rect {
        const topLeft = entry.panel.mapToItem(null, 0, 0);
        return Qt.rect(topLeft.x - entry.appliedX, topLeft.y - entry.appliedY, resolvedWidth(entry, Infinity), entry.panel.height);
    }

    // Where the panel sits for a given shift and width cap. A shift is a plain
    // signed position delta, so this stays correct no matter how deeply the panel
    // is nested or what margins its ancestors carry.
    function resolvedRect(entry, base: rect, maxWidth: real, shiftX: real, shiftY: real): rect {
        return Qt.rect(base.x + shiftX, base.y + shiftY, resolvedWidth(entry, maxWidth), base.height);
    }

    function resolvedWidth(entry, maxWidth: real): real {
        const natural = entry.panel.naturalWidth;
        if (maxWidth === Infinity)
            return natural;
        return Math.min(natural, Math.max(0, maxWidth));
    }

    // New horizontal shift clearing `other`, or null when the panel has no
    // horizontal anchor to slide along. A right anchored panel can only move left,
    // a left anchored panel only right, which is what keeps the sign of the result
    // pointing away from the screen edge.
    function shiftForX(entry, rect, shiftX: real, other: rect): real {
        if (!overlapsVertically(rect, other, root.spacing))
            return null;

        if (entry.hEdge === "right")
            return shiftX + rect.x - (other.x + other.width + root.spacing);
        if (entry.hEdge === "left")
            return shiftX + (rect.x + rect.width) - (other.x - root.spacing);
        return null;
    }

    // New vertical shift clearing `other`, or null when the panel has no vertical
    // anchor to slide along.
    function shiftForY(entry, rect, shiftY: real, other: rect): real {
        if (!overlapsHorizontally(rect, other, root.spacing))
            return null;

        if (entry.vEdge === "bottom")
            return shiftY + (rect.y + rect.height) - (other.y - root.spacing);
        if (entry.vEdge === "top")
            return shiftY + rect.y - (other.y + other.height + root.spacing);
        return null;
    }

    // Widest the panel may be while still clearing `other`, measured from the
    // screen edge it is pinned to. Only ever a cap, never a padding. An already
    // applied shift moves that edge, so the free space is measured from where the
    // panel actually sits rather than from the untouched screen edge.
    function capFor(entry, other: rect, shiftX: real): real {
        const windowWidth = entry.panel.Window.width;
        if (entry.hEdge === "right")
            return windowWidth + shiftX - (other.x + other.width + root.spacing);
        if (entry.hEdge === "left")
            return other.x - root.spacing - shiftX;
        return Infinity;
    }

    // Keep the nudged panel on screen: a right anchored panel may only travel left
    // and a left anchored one only right, and never off either edge.
    function clampShiftX(entry, shift: real): real {
        const room = Math.max(0, entry.panel.Window.width - baseRect(entry).width);
        if (entry.hEdge === "right")
            return clamp(shift, -room, 0);
        if (entry.hEdge === "left")
            return clamp(shift, 0, room);
        return shift;
    }

    function clampShiftY(entry, shift: real): real {
        const room = Math.max(0, entry.panel.Window.height - baseRect(entry).height);
        if (entry.vEdge === "bottom")
            return clamp(shift, -room, 0);
        if (entry.vEdge === "top")
            return clamp(shift, 0, room);
        return shift;
    }

    function clamp(value: real, low: real, high: real): real {
        return Math.max(low, Math.min(value, high));
    }

    function overlaps(a: rect, b: rect, gap: real): bool {
        return overlapsHorizontally(a, b, gap) && overlapsVertically(a, b, gap);
    }

    function overlapsHorizontally(a: rect, b: rect, gap: real): bool {
        return !(a.x + a.width + gap <= b.x || b.x + b.width + gap <= a.x);
    }

    function overlapsVertically(a: rect, b: rect, gap: real): bool {
        return !(a.y + a.height + gap <= b.y || b.y + b.height + gap <= a.y);
    }

    // On-demand dump, for when a pass trace is too much noise: shows what is
    // registered and what it is currently sitting at.
    function dumpState() {
        const keys = Object.keys(registry);
        console.log(logCat, `[layout] ${keys.length} registered · ${root.passCount} passes · spacing=${root.spacing}`);
        for (const key of keys) {
            const e = registry[key];
            console.log(logCat, `[layout]   ${key}  prio=${e.priority}  edges=${e.hEdge}/${e.vEdge}  natural=${num(e.panel.naturalWidth)}  applied=max ${num(e.appliedMaxWidth)} x ${num(e.appliedX)} y ${num(e.appliedY)}${e.hidden ? " hidden" : ""}  ${skipReason(e.panel)}`);
        }
    }

    // Why a panel was left out of the pass. The usual answer is a drawer that is
    // still fully collapsed, which is correct: an off-screen panel has no
    // geometry worth reserving space for. `hidden` is not a reason: a panel this
    // manager hid is measured anyway, so that it can be brought back.
    function skipReason(panel) {
        if (panel === null)
            return "panel is null";
        if (!panel.visible)
            return "visible=false";
        if (panel.Window === null)
            return "not in a window yet";
        if (panel.width <= 0 || panel.height <= 0)
            return `collapsed ${Math.round(panel.width)}x${Math.round(panel.height)}`;
        return "renderable";
    }

    // An A-B-A-B pattern across passes means two panels are trading a spot rather
    // than settling, which no amount of further passing will fix. A history that
    // never changes is the opposite: the panel is already settled.
    function oscillating(entry, settled) {
        const signature = `${settled.maxWidth}/${settled.shiftX}/${settled.shiftY}`;
        entry.history.push(signature);
        if (entry.history.length > 4)
            entry.history.shift();
        const n = entry.history.length;
        return n >= 3 && entry.history[n - 1] === entry.history[n - 3] && entry.history[n - 1] !== entry.history[n - 2];
    }

    function fmtRect(r) {
        return `${Math.round(r.x)},${Math.round(r.y)} ${Math.round(r.width)}x${Math.round(r.height)}`;
    }

    function num(value) {
        return value === Infinity ? "inf" : Math.round(value);
    }

    function trace(message) {
        console.log(logCat, `[layout] ${message}`);
    }

    LoggingCategory {
        id: logCat

        name: "caelestia.layoutmanager"
        defaultLogLevel: LoggingCategory.Debug
    }

    Timer {
        id: layoutUpdateTimer

        interval: 0
        repeat: false
        onTriggered: root.recalculate()
    }
}
