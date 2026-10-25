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

        const placed = [];
        for (const entry of entries) {
            const base = baseRect(entry);

            const fit = resolve(entry, base, placed);
            const settled = apply(entry, fit.maxWidth, fit.shiftX, fit.shiftY);
            placed.push({
                key: entry.key,
                rect: resolvedRect(entry, base, fit.maxWidth, fit.shiftX, fit.shiftY)
            });
        }
    }

    function resolve(entry, base: rect, placed: list<var>) {
        let maxWidth = Infinity;
        let shiftX = 0;
        let shiftY = 0;

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
                        shiftX = wanted;
                        changed = true;
                        continue;
                    }
                }

                const dy = shiftForY(entry, rect, shiftY, blocker);
                if (dy !== null) {
                    const wanted = clampShiftY(entry, dy);
                    if (clears(entry, base, maxWidth, shiftX, wanted, blocker)) {
                        shiftY = wanted;
                        changed = true;
                        continue;
                    }
                }

                const cap = capFor(entry, blocker, shiftX);
                if (cap < maxWidth) {
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
        const noRoom = maxWidth !== Infinity && maxWidth < root.minWidth;
        const width = noRoom || maxWidth === Infinity ? 0 : Math.floor(maxWidth);
        let changed = false;

        if (entry.appliedMaxWidth !== width) {
            entry.appliedMaxWidth = width;
            panel.layoutMaxWidth = width;
            changed = true;
        }

        if (entry.hidden) {
            entry.hidden = false;
            panel.layoutHidden = false;
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

    function fmtRect(r) {
        return `${Math.round(r.x)},${Math.round(r.y)} ${Math.round(r.width)}x${Math.round(r.height)}`;
    }

    function num(value) {
        return value === Infinity ? "inf" : Math.round(value);
    }

    Timer {
        id: layoutUpdateTimer

        interval: 0
        repeat: false
        onTriggered: root.recalculate()
    }
}
