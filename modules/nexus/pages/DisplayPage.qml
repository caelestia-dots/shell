pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property var draftMonitors: []
    property var previousSnapshot: null
    property string selectedName: ""
    property bool hasChanges: false
    property bool canUndo: false
    property string statusBannerText: ""
    property bool statusBannerError: false

    // Drag state isolated from draftMonitors so monitor delegates are never recreated mid-drag
    property bool isDragging: false
    property int draggingIndex: -1
    property real dragLogicalX: 0
    property real dragLogicalY: 0
    property bool hasSnapX: false
    property real snapGuideLogicalX: 0
    property bool hasSnapY: false
    property real snapGuideLogicalY: 0
    property real frozenScale: 0.1
    property real frozenOriginX: 0
    property real frozenOriginY: 0

    readonly property int monitorCount: draftMonitors.length
    readonly property int selectedIndex: {
        if (draftMonitors.length === 0)
            return -1;
        const idx = draftMonitors.findIndex(m => m.name === selectedName);
        return idx >= 0 ? idx : 0;
    }
    readonly property var selectedMonitor: selectedIndex >= 0 ? draftMonitors[selectedIndex] : null
    readonly property int enabledCount: {
        let count = 0;
        for (let i = 0; i < draftMonitors.length; i++) {
            if (!draftMonitors[i].disabled)
                count++;
        }
        return count;
    }
    readonly property bool canDisableSelected: selectedMonitor ? (!selectedMonitor.disabled ? enabledCount > 1 : true) : false

    readonly property list<real> standardScales: [1, 1.25, 1.5, 1.75, 2]
    readonly property var selectedScaleChoices: {
        const list = [1, 1.25, 1.5, 1.75, 2];
        if (selectedMonitor) {
            const cur = Math.round(Number(selectedMonitor.scale || 1) * 100) / 100;
            if (!list.some(v => Math.abs(v - cur) < 0.015)) {
                list.push(cur);
                list.sort((a, b) => a - b);
            }
        }
        return list;
    }

    readonly property list<var> rotationOptions: [
        {
            value: 0,
            label: Tr.tr("0° (Normal)")
        },
        {
            value: 1,
            label: "90°"
        },
        {
            value: 2,
            label: "180°"
        },
        {
            value: 3,
            label: "270°"
        }
    ]

    readonly property list<var> presetOptions: [
        {
            id: "extend",
            icon: "vital_signs",
            title: Tr.tr("Extend right")
        },
        {
            id: "extend-up",
            icon: "keyboard_double_arrow_up",
            title: Tr.tr("Extend above")
        },
        {
            id: "mirror",
            icon: "cast",
            title: Tr.tr("Mirror")
        },
        {
            id: "external",
            icon: "desktop_windows",
            title: Tr.tr("External only")
        },
        {
            id: "internal",
            icon: "laptop_chromebook",
            title: Tr.tr("Built-in only")
        }
    ]

    readonly property var selectedResolutions: (selectedMonitor && selectedMonitor.resolutions) ? selectedMonitor.resolutions : []
    readonly property var selectedRates: {
        if (!selectedMonitor || !selectedMonitor.resolutions)
            return [];
        const entry = selectedMonitor.resolutions.find(r => r.res === selectedMonitor.res);
        if (entry && entry.rates)
            return entry.rates;
        return selectedMonitor.resolutions.length > 0 ? (selectedMonitor.resolutions[0].rates || []) : [];
    }
    readonly property var mirrorTargetMonitors: {
        if (!selectedMonitor)
            return [];
        return draftMonitors.filter(m => m.name !== selectedMonitor.name && !m.disabled && !m.mirrorOf);
    }

    function cloneMonitors(list: var): var {
        return JSON.parse(JSON.stringify(list || []));
    }

    function formatScaleLabel(s: real): string {
        return `${Math.round(s * 100)}%`;
    }

    function syncFromService(forceReset: bool): void {
        if (isDragging)
            return;
        const live = Displays.monitors;
        if (!Array.isArray(live))
            return;
        if (forceReset || !hasChanges || draftMonitors.length === 0) {
            draftMonitors = cloneMonitors(live);
            hasChanges = false;
        }
        if (!selectedName || !draftMonitors.some(m => m.name === selectedName))
            selectedName = draftMonitors.length > 0 ? draftMonitors[0].name : "";
    }

    function computeHasChanges(): bool {
        const live = Displays.monitors;
        if (!Array.isArray(live) || live.length !== draftMonitors.length)
            return true;
        for (let i = 0; i < draftMonitors.length; i++) {
            const a = draftMonitors[i];
            const b = live[i];
            if (!a || !b)
                return true;
            if (a.name !== b.name || Math.round(a.x) !== Math.round(b.x) || Math.round(a.y) !== Math.round(b.y) || Math.abs(Number(a.scale) - Number(b.scale)) > 0.005 || a.mode !== b.mode || (a.transform || 0) !== (b.transform || 0) || !!a.disabled !== !!b.disabled || (a.mirrorOf || "") !== (b.mirrorOf || ""))
                return true;
        }
        return false;
    }

    function commitDraft(nextList: var): void {
        draftMonitors = nextList;
        hasChanges = computeHasChanges();
    }

    function normalizePositions(list: var): void {
        const active = list.filter(m => !m.disabled && !m.mirrorOf);
        if (active.length === 0)
            return;
        let minX = active[0].x;
        let minY = active[0].y;
        for (let i = 1; i < active.length; i++) {
            if (active[i].x < minX)
                minX = active[i].x;
            if (active[i].y < minY)
                minY = active[i].y;
        }
        for (let i = 0; i < list.length; i++) {
            list[i].x = Math.round(list[i].x - minX);
            list[i].y = Math.round(list[i].y - minY);
        }
    }

    function computeSnappedPos(idx: int, rawX: real, rawY: real, canvasScale: real): var {
        const m = draftMonitors[idx];
        const sz = Displays.logicalSize(m);
        const lw = sz.w;
        const lh = sz.h;
        const snapDist = Math.max(120, Math.round(26 / Math.max(0.02, canvasScale)));

        let bestDx = 0;
        let bestAbsDx = snapDist + 1;
        let foundX = false;
        let guideX = 0;

        let bestDy = 0;
        let bestAbsDy = snapDist + 1;
        let foundY = false;
        let guideY = 0;

        for (let i = 0; i < draftMonitors.length; i++) {
            if (i === idx)
                continue;
            const o = draftMonitors[i];
            if (o.disabled || o.mirrorOf)
                continue;
            const os = Displays.logicalSize(o);
            const ox = o.x;
            const oy = o.y;
            const ow = os.w;
            const oh = os.h;

            const vNear = (rawY < oy + oh + snapDist) && (rawY + lh > oy - snapDist);
            const hNear = (rawX < ox + ow + snapDist) && (rawX + lw > ox - snapDist);

            const xTargets = [
                {
                    tx: ox + ow,
                    gx: ox + ow,
                    cond: vNear
                },
                {
                    tx: ox - lw,
                    gx: ox,
                    cond: vNear
                },
                {
                    tx: ox,
                    gx: ox,
                    cond: true
                },
                {
                    tx: ox + ow - lw,
                    gx: ox + ow,
                    cond: true
                },
                {
                    tx: ox + (ow - lw) / 2,
                    gx: ox + ow / 2,
                    cond: hNear
                }
            ];
            for (let k = 0; k < xTargets.length; k++) {
                if (!xTargets[k].cond)
                    continue;
                const d = xTargets[k].tx - rawX;
                const ad = Math.abs(d);
                if (ad < bestAbsDx) {
                    bestAbsDx = ad;
                    bestDx = d;
                    foundX = true;
                    guideX = xTargets[k].gx;
                }
            }

            const yTargets = [
                {
                    ty: oy + oh,
                    gy: oy + oh,
                    cond: hNear
                },
                {
                    ty: oy - lh,
                    gy: oy,
                    cond: hNear
                },
                {
                    ty: oy,
                    gy: oy,
                    cond: true
                },
                {
                    ty: oy + oh - lh,
                    gy: oy + oh,
                    cond: true
                },
                {
                    ty: oy + (oh - lh) / 2,
                    gy: oy + oh / 2,
                    cond: vNear
                }
            ];
            for (let k = 0; k < yTargets.length; k++) {
                if (!yTargets[k].cond)
                    continue;
                const d = yTargets[k].ty - rawY;
                const ad = Math.abs(d);
                if (ad < bestAbsDy) {
                    bestAbsDy = ad;
                    bestDy = d;
                    foundY = true;
                    guideY = yTargets[k].gy;
                }
            }
        }

        return {
            x: Math.round(rawX + (foundX ? bestDx : 0)),
            y: Math.round(rawY + (foundY ? bestDy : 0)),
            hasX: foundX,
            guideX: guideX,
            hasY: foundY,
            guideY: guideY
        };
    }

    function rectsOverlap(ax: real, ay: real, aw: real, ah: real, bx: real, by: real, bw: real, bh: real): bool {
        return (ax < bx + bw - 2) && (ax + aw > bx + 2) && (ay < by + bh - 2) && (ay + ah > by + 2);
    }

    function rectGap(ax: real, ay: real, aw: real, ah: real, bx: real, by: real, bw: real, bh: real): real {
        const dx = Math.max(0, bx - (ax + aw), ax - (bx + bw));
        const dy = Math.max(0, by - (ay + ah), ay - (by + bh));
        return Math.hypot(dx, dy);
    }

    function finalizeDrop(idx: int, dropX: real, dropY: real): void {
        const next = cloneMonitors(draftMonitors);
        const m = next[idx];
        if (!m)
            return;

        m.x = Math.round(dropX);
        m.y = Math.round(dropY);

        if (!m.disabled && !m.mirrorOf) {
            const ms = Displays.logicalSize(m);
            const others = [];
            for (let i = 0; i < next.length; i++) {
                if (i !== idx && !next[i].disabled && !next[i].mirrorOf) {
                    const os = Displays.logicalSize(next[i]);
                    others.push({
                        x: next[i].x,
                        y: next[i].y,
                        w: os.w,
                        h: os.h
                    });
                }
            }

            if (others.length > 0) {
                for (let pass = 0; pass < 4; pass++) {
                    let anyOverlap = false;
                    for (let i = 0; i < others.length; i++) {
                        const o = others[i];
                        if (!rectsOverlap(m.x, m.y, ms.w, ms.h, o.x, o.y, o.w, o.h))
                            continue;
                        anyOverlap = true;
                        const candidates = [
                            {
                                x: o.x - ms.w,
                                y: m.y
                            },
                            {
                                x: o.x + o.w,
                                y: m.y
                            },
                            {
                                x: m.x,
                                y: o.y - ms.h
                            },
                            {
                                x: m.x,
                                y: o.y + o.h
                            }
                        ];
                        let best = candidates[0];
                        let bestScore = Infinity;
                        for (let c = 0; c < candidates.length; c++) {
                            const cand = candidates[c];
                            const dist = Math.hypot(cand.x - m.x, cand.y - m.y);
                            let hits = 0;
                            for (let j = 0; j < others.length; j++) {
                                if (rectsOverlap(cand.x, cand.y, ms.w, ms.h, others[j].x, others[j].y, others[j].w, others[j].h))
                                    hits++;
                            }
                            const score = dist + hits * 100000;
                            if (score < bestScore) {
                                bestScore = score;
                                best = cand;
                            }
                        }
                        m.x = Math.round(best.x);
                        m.y = Math.round(best.y);
                    }
                    if (!anyOverlap)
                        break;
                }

                let minGap = Infinity;
                let nearest = others[0];
                for (let i = 0; i < others.length; i++) {
                    const g = rectGap(m.x, m.y, ms.w, ms.h, others[i].x, others[i].y, others[i].w, others[i].h);
                    if (g < minGap) {
                        minGap = g;
                        nearest = others[i];
                    }
                }
                if (minGap > 2) {
                    const mCx = m.x + ms.w / 2;
                    const mCy = m.y + ms.h / 2;
                    const oCx = nearest.x + nearest.w / 2;
                    const oCy = nearest.y + nearest.h / 2;
                    const dxNorm = (mCx - oCx) / Math.max(1, (ms.w + nearest.w) / 2);
                    const dyNorm = (mCy - oCy) / Math.max(1, (ms.h + nearest.h) / 2);

                    if (Math.abs(dxNorm) >= Math.abs(dyNorm)) {
                        m.x = dxNorm >= 0 ? (nearest.x + nearest.w) : (nearest.x - ms.w);
                        const minY = nearest.y - ms.h + Math.min(200, ms.h / 2);
                        const maxY = nearest.y + nearest.h - Math.min(200, ms.h / 2);
                        m.y = Math.round(Math.max(minY, Math.min(maxY, m.y)));
                    } else {
                        m.y = dyNorm >= 0 ? (nearest.y + nearest.h) : (nearest.y - ms.h);
                        const minX = nearest.x - ms.w + Math.min(200, ms.w / 2);
                        const maxX = nearest.x + nearest.w - Math.min(200, ms.w / 2);
                        m.x = Math.round(Math.max(minX, Math.min(maxX, m.x)));
                    }
                }
            }
        }

        normalizePositions(next);
        commitDraft(next);
    }

    function mutateSelectedWithSeamAdjust(mutator: var): void {
        const idx = selectedIndex;
        if (idx < 0)
            return;
        const next = cloneMonitors(draftMonitors);
        const m = next[idx];
        const oldSz = Displays.logicalSize(m);
        const oldRight = m.x + oldSz.w;
        const oldBottom = m.y + oldSz.h;

        mutator(m, next);

        const newSz = Displays.logicalSize(m);
        const dw = newSz.w - oldSz.w;
        const dh = newSz.h - oldSz.h;

        if (!m.disabled && !m.mirrorOf && (dw !== 0 || dh !== 0)) {
            for (let i = 0; i < next.length; i++) {
                if (i === idx || next[i].disabled || next[i].mirrorOf)
                    continue;
                const o = next[i];
                const os = Displays.logicalSize(o);
                const vOverlap = (o.y < oldBottom - 4) && (o.y + os.h > m.y + 4);
                const hOverlap = (o.x < oldRight - 4) && (o.x + os.w > m.x + 4);
                if (dw !== 0 && vOverlap && o.x >= oldRight - 6)
                    o.x = Math.round(o.x + dw);
                if (dh !== 0 && hOverlap && o.y >= oldBottom - 6)
                    o.y = Math.round(o.y + dh);
            }
        }

        normalizePositions(next);
        commitDraft(next);
    }

    function autoAlignRow(): void {
        const next = cloneMonitors(draftMonitors);
        const active = next.filter(m => !m.disabled && !m.mirrorOf);
        active.sort((a, b) => (a.x - b.x) || (a.index - b.index));
        let cursorX = 0;
        const maxH = active.reduce((acc, m) => Math.max(acc, Displays.logicalSize(m).h), 0);
        for (let i = 0; i < active.length; i++) {
            const sz = Displays.logicalSize(active[i]);
            active[i].x = cursorX;
            active[i].y = Math.round((maxH - sz.h) / 2);
            cursorX += sz.w;
        }
        normalizePositions(next);
        commitDraft(next);
    }

    function resetDraft(): void {
        draftMonitors = cloneMonitors(Displays.monitors);
        hasChanges = false;
        statusBannerText = "";
        statusBannerError = false;
    }

    function applyDraft(): void {
        if (draftMonitors.length === 0)
            return;
        previousSnapshot = cloneMonitors(Displays.monitors);
        const ok = Displays.applyLayout(draftMonitors, true, "custom");
        if (ok) {
            hasChanges = false;
            canUndo = previousSnapshot !== null;
            statusBannerError = false;
            statusBannerText = Tr.tr("Layout saved and applied");
            undoClearTimer.restart();
        }
    }

    function undoLastApply(): void {
        if (!previousSnapshot)
            return;
        undoClearTimer.stop();
        const ok = Displays.applyLayout(previousSnapshot, true, "custom");
        if (ok) {
            hasChanges = false;
            canUndo = false;
            statusBannerError = false;
            statusBannerText = Tr.tr("Previous layout restored");
        }
    }

    function applyPreset(presetId: string): void {
        previousSnapshot = cloneMonitors(Displays.monitors);
        const ok = Displays.applyPreset(presetId, Displays.externalScale);
        if (ok) {
            hasChanges = false;
            canUndo = previousSnapshot !== null;
            statusBannerError = false;
            statusBannerText = Tr.tr("Projection preset applied");
            undoClearTimer.restart();
        }
    }

    title: Tr.tr("Display")
    Component.onCompleted: {
        syncFromService(true);
        Displays.refresh();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Connections {
            function onMonitorsChanged(): void {
                root.syncFromService(!root.hasChanges);
            }

            function onApplyFinished(ok: bool, message: string): void {
                if (!ok) {
                    root.statusBannerError = true;
                    root.statusBannerText = message;
                }
            }

            target: Displays
        }

        Timer {
            id: undoClearTimer

            interval: 15000
            onTriggered: {
                root.canUndo = false;
                if (!root.statusBannerError)
                    root.statusBannerText = "";
            }
        }

        SectionHeader {
            first: true
            text: Tr.tr("Arrangement (drag displays to reposition)")
        }

        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: canvasCardCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: canvasCardCol

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledRect {
                    id: canvasArea

                    readonly property var bounds: {
                        const list = root.draftMonitors;
                        if (!list || list.length === 0)
                            return {
                                minX: 0,
                                minY: 0,
                                maxX: 1920,
                                maxY: 1080
                            };
                        let minX = Infinity;
                        let minY = Infinity;
                        let maxX = -Infinity;
                        let maxY = -Infinity;
                        for (let i = 0; i < list.length; i++) {
                            const m = list[i];
                            const sz = Displays.logicalSize(m);
                            const mx = m.x || 0;
                            const my = m.y || 0;
                            if (mx < minX)
                                minX = mx;
                            if (my < minY)
                                minY = my;
                            if (mx + sz.w > maxX)
                                maxX = mx + sz.w;
                            if (my + sz.h > maxY)
                                maxY = my + sz.h;
                        }
                        return {
                            minX: minX,
                            minY: minY,
                            maxX: maxX,
                            maxY: maxY
                        };
                    }
                    readonly property real fitPad: 28
                    readonly property real viewScale: {
                        const bw = Math.max(1200, bounds.maxX - bounds.minX);
                        const bh = Math.max(800, bounds.maxY - bounds.minY);
                        const availW = Math.max(100, width - fitPad * 2);
                        const availH = Math.max(100, height - fitPad * 2);
                        return Math.min(availW / bw, availH / bh, 0.16);
                    }
                    readonly property real viewOriginX: {
                        const bw = (bounds.maxX - bounds.minX) * viewScale;
                        return (width - bw) / 2 - bounds.minX * viewScale;
                    }
                    readonly property real viewOriginY: {
                        const bh = (bounds.maxY - bounds.minY) * viewScale;
                        return (height - bh) / 2 - bounds.minY * viewScale;
                    }
                    readonly property real activeScale: root.isDragging ? root.frozenScale : viewScale
                    readonly property real activeOriginX: root.isDragging ? root.frozenOriginX : viewOriginX
                    readonly property real activeOriginY: root.isDragging ? root.frozenOriginY : viewOriginY

                    Layout.fillWidth: true
                    implicitHeight: 290
                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainerLow
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant
                    clip: true

                    Canvas {
                        id: gridCanvas

                        property color dotColor: Colours.palette.m3outlineVariant

                        anchors.fill: parent
                        onDotColorChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.fillStyle = Qt.alpha(dotColor, 0.45);
                            const step = 20;
                            for (let gx = step; gx < width; gx += step) {
                                for (let gy = step; gy < height; gy += step)
                                    ctx.fillRect(gx, gy, 1.5, 1.5);
                            }
                        }
                    }

                    Rectangle {
                        visible: root.isDragging && root.hasSnapX
                        x: Math.round(canvasArea.activeOriginX + root.snapGuideLogicalX * canvasArea.activeScale)
                        y: 0
                        width: 1
                        height: parent.height
                        color: Colours.palette.m3primary
                        opacity: 0.7
                        z: 20
                    }

                    Rectangle {
                        visible: root.isDragging && root.hasSnapY
                        x: 0
                        y: Math.round(canvasArea.activeOriginY + root.snapGuideLogicalY * canvasArea.activeScale)
                        width: parent.width
                        height: 1
                        color: Colours.palette.m3primary
                        opacity: 0.7
                        z: 20
                    }

                    StyledText {
                        anchors.centerIn: parent
                        visible: root.monitorCount === 0
                        text: Tr.tr("Detecting displays...")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    Repeater {
                        model: root.monitorCount

                        Item {
                            id: monTile

                            required property int index

                            readonly property var mon: (index < root.draftMonitors.length) ? root.draftMonitors[index] : null
                            readonly property var sz: Displays.logicalSize(mon)
                            readonly property bool isSelected: mon ? (mon.name === root.selectedName) : false
                            readonly property bool isThisDragged: root.isDragging && root.draggingIndex === index
                            readonly property bool isDisabled: mon ? !!mon.disabled : false
                            readonly property bool isMirrored: mon ? !!(mon.mirrorOf && mon.mirrorOf.length > 0) : false
                            readonly property real targetX: isThisDragged ? (canvasArea.activeOriginX + root.dragLogicalX * canvasArea.activeScale) : (canvasArea.activeOriginX + (mon ? mon.x : 0) * canvasArea.activeScale)
                            readonly property real targetY: isThisDragged ? (canvasArea.activeOriginY + root.dragLogicalY * canvasArea.activeScale) : (canvasArea.activeOriginY + (mon ? mon.y : 0) * canvasArea.activeScale)
                            readonly property real targetW: Math.max(58, sz.w * canvasArea.activeScale)
                            readonly property real targetH: Math.max(46, sz.h * canvasArea.activeScale)

                            x: targetX
                            y: targetY
                            width: targetW
                            height: targetH
                            z: isThisDragged ? 30 : (isSelected ? 15 : 5)

                            Behavior on x {
                                enabled: !root.isDragging

                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }

                            Behavior on y {
                                enabled: !root.isDragging

                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }

                            Behavior on width {
                                enabled: !root.isDragging

                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }

                            Behavior on height {
                                enabled: !root.isDragging

                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }

                            StyledRect {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: Tokens.rounding.medium
                                opacity: monTile.isDisabled ? 0.48 : 1
                                color: {
                                    if (monTile.isSelected)
                                        return Colours.palette.m3primaryContainer;
                                    if (tileMouse.containsMouse)
                                        return Colours.tPalette.m3surfaceContainerHighest;
                                    return Colours.tPalette.m3surfaceContainerHigh;
                                }
                                border.width: monTile.isSelected ? 2 : 1.5
                                border.color: {
                                    if (monTile.isThisDragged || monTile.isSelected)
                                        return Colours.palette.m3primary;
                                    return Colours.palette.m3outline;
                                }

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        StyledRect {
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            radius: 9
                                            color: monTile.isSelected ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                                            StyledText {
                                                anchors.centerIn: parent
                                                text: String(monTile.mon ? monTile.mon.index : (monTile.index + 1))
                                                color: monTile.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }

                                        MaterialIcon {
                                            visible: monTile.width >= 88
                                            text: (monTile.mon && monTile.mon.isInternal) ? "laptop_chromebook" : "monitor"
                                            color: monTile.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                            fontStyle: Tokens.font.icon.small
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        StyledRect {
                                            visible: (monTile.isDisabled || monTile.isMirrored) && monTile.width >= 95
                                            implicitWidth: badgeTxt.implicitWidth + 8
                                            implicitHeight: 16
                                            radius: 8
                                            color: monTile.isDisabled ? Colours.palette.m3errorContainer : Colours.palette.m3tertiaryContainer

                                            StyledText {
                                                id: badgeTxt

                                                anchors.centerIn: parent
                                                text: monTile.isDisabled ? Tr.tr("Off") : Tr.tr("Mirror")
                                                color: monTile.isDisabled ? Colours.palette.m3onErrorContainer : Colours.palette.m3onTertiaryContainer
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Item {
                                        Layout.fillHeight: true
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: monTile.mon ? monTile.mon.shortLabel : ""
                                        color: monTile.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                        font.pixelSize: monTile.width >= 130 ? 12 : 10
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: monTile.height >= 72
                                        horizontalAlignment: Text.AlignHCenter
                                        text: monTile.mon ? `${monTile.mon.name} • ${root.formatScaleLabel(monTile.mon.scale)}` : ""
                                        color: monTile.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                        opacity: 0.85
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: monTile.height >= 96 && monTile.width >= 120
                                        horizontalAlignment: Text.AlignHCenter
                                        text: monTile.mon ? `${monTile.mon.width}×${monTile.mon.height} @ ${Math.round(monTile.mon.refreshRate)}Hz` : ""
                                        color: monTile.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }

                                    Item {
                                        Layout.fillHeight: true
                                    }
                                }
                            }

                            MouseArea {
                                id: tileMouse

                                property real startCanvasX: 0
                                property real startCanvasY: 0
                                property real startMonX: 0
                                property real startMonY: 0
                                property bool movedEnough: false

                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                onPressed: mouse => {
                                    if (!monTile.mon)
                                        return;
                                    root.selectedName = monTile.mon.name;
                                    const pt = mapToItem(canvasArea, mouse.x, mouse.y);
                                    startCanvasX = pt.x;
                                    startCanvasY = pt.y;
                                    startMonX = monTile.mon.x || 0;
                                    startMonY = monTile.mon.y || 0;
                                    movedEnough = false;

                                    if (!monTile.isDisabled && !monTile.isMirrored) {
                                        root.frozenScale = canvasArea.viewScale;
                                        root.frozenOriginX = canvasArea.viewOriginX;
                                        root.frozenOriginY = canvasArea.viewOriginY;
                                        root.dragLogicalX = startMonX;
                                        root.dragLogicalY = startMonY;
                                        root.draggingIndex = monTile.index;
                                        root.hasSnapX = false;
                                        root.hasSnapY = false;
                                        root.isDragging = true;
                                        root.flickable.interactive = false;
                                    }
                                }

                                onPositionChanged: mouse => {
                                    if (!pressed || !root.isDragging || root.draggingIndex !== monTile.index)
                                        return;
                                    const pt = mapToItem(canvasArea, mouse.x, mouse.y);
                                    const dxCanvas = pt.x - startCanvasX;
                                    const dyCanvas = pt.y - startCanvasY;
                                    if (!movedEnough && Math.hypot(dxCanvas, dyCanvas) < 4)
                                        return;
                                    movedEnough = true;

                                    const rawX = startMonX + dxCanvas / Math.max(0.02, root.frozenScale);
                                    const rawY = startMonY + dyCanvas / Math.max(0.02, root.frozenScale);
                                    const snapped = root.computeSnappedPos(monTile.index, rawX, rawY, root.frozenScale);

                                    root.dragLogicalX = snapped.x;
                                    root.dragLogicalY = snapped.y;
                                    root.hasSnapX = snapped.hasX;
                                    root.snapGuideLogicalX = snapped.guideX;
                                    root.hasSnapY = snapped.hasY;
                                    root.snapGuideLogicalY = snapped.guideY;
                                }

                                onReleased: {
                                    root.flickable.interactive = true;
                                    if (!root.isDragging || root.draggingIndex !== monTile.index)
                                        return;
                                    const finalX = root.dragLogicalX;
                                    const finalY = root.dragLogicalY;
                                    const didMove = movedEnough;
                                    root.isDragging = false;
                                    root.draggingIndex = -1;
                                    root.hasSnapX = false;
                                    root.hasSnapY = false;
                                    if (didMove)
                                        root.finalizeDrop(monTile.index, finalX, finalY);
                                }

                                onCanceled: {
                                    root.flickable.interactive = true;
                                    root.isDragging = false;
                                    root.draggingIndex = -1;
                                    root.hasSnapX = false;
                                    root.hasSnapY = false;
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Flow {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Repeater {
                            model: root.monitorCount

                            TextButton {
                                id: monPill

                                required property int index

                                readonly property var mon: (index < root.draftMonitors.length) ? root.draftMonitors[index] : null
                                readonly property bool isCur: mon ? (mon.name === root.selectedName) : false

                                type: isCur ? TextButton.Filled : TextButton.Tonal
                                isRound: true
                                text: mon ? `${mon.index}. ${mon.shortLabel}${mon.disabled ? ` (${Tr.tr("Off")})` : ""}` : ""
                                onClicked: {
                                    if (mon)
                                        root.selectedName = mon.name;
                                }
                            }
                        }
                    }

                    StyledRect {
                        visible: Displays.hasSavedProfile
                        implicitWidth: profRow.implicitWidth + 14
                        implicitHeight: 24
                        radius: 12
                        color: Colours.palette.m3secondaryContainer

                        RowLayout {
                            id: profRow

                            anchors.centerIn: parent
                            spacing: 4

                            MaterialIcon {
                                text: "bookmark_check"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3onSecondaryContainer
                            }

                            StyledText {
                                text: Tr.tr("Profile saved")
                                font: Tokens.font.label.small
                                color: Colours.palette.m3onSecondaryContainer
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                if (root.statusBannerText)
                                    return root.statusBannerText;
                                if (root.hasChanges)
                                    return Tr.tr("Unsaved changes — click Apply to commit");
                                if (root.selectedMonitor)
                                    return Tr.tr("%1: Position (%2, %3)").arg(root.selectedMonitor.name).arg(root.selectedMonitor.x).arg(root.selectedMonitor.y);
                                return Tr.tr("Ready");
                            }
                            color: {
                                if (root.statusBannerError)
                                    return Colours.palette.m3error;
                                if (root.hasChanges)
                                    return Colours.palette.m3primary;
                                return Colours.palette.m3onSurfaceVariant;
                            }
                            font: Tokens.font.label.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: root.selectedMonitor !== null
                            text: root.selectedMonitor ? (root.selectedMonitor.description || root.selectedMonitor.name) : ""
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    TextButton {
                        visible: root.canUndo && !root.hasChanges
                        type: TextButton.Tonal
                        isRound: true
                        text: Tr.tr("Undo")
                        onClicked: root.undoLastApply()
                    }

                    TextButton {
                        visible: root.monitorCount > 1 && !root.hasChanges
                        type: TextButton.Tonal
                        isRound: true
                        text: Tr.tr("Auto-align")
                        onClicked: root.autoAlignRow()
                    }

                    TextButton {
                        visible: root.hasChanges
                        type: TextButton.Text
                        isRound: true
                        text: Tr.tr("Discard")
                        onClicked: root.resetDraft()
                    }

                    IconTextButton {
                        type: TextButton.Filled
                        isRound: true
                        icon: "check"
                        text: Tr.tr("Apply")
                        disabled: !root.hasChanges
                        onClicked: root.applyDraft()
                    }
                }
            }
        }

        SectionHeader {
            visible: root.selectedMonitor !== null
            text: root.selectedMonitor ? Tr.tr("Display settings: %1 — %2").arg(root.selectedMonitor.name).arg(root.selectedMonitor.shortLabel) : Tr.tr("Display settings")
        }

        ToggleRow {
            visible: root.selectedMonitor !== null
            first: true
            text: Tr.tr("Enable display")
            subtext: !root.canDisableSelected ? Tr.tr("The last active display cannot be disabled") : (root.selectedMonitor && root.selectedMonitor.disabled ? Tr.tr("This output is currently turned off") : Tr.tr("Output active"))
            disabled: !root.canDisableSelected
            checked: root.selectedMonitor ? !root.selectedMonitor.disabled : true
            onToggled: {
                if (!root.selectedMonitor)
                    return;
                const wantDisabled = !checked;
                if (wantDisabled && root.enabledCount <= 1)
                    return;
                const next = root.cloneMonitors(root.draftMonitors);
                const m = next[root.selectedIndex];
                if (!m)
                    return;
                m.disabled = wantDisabled;
                if (wantDisabled) {
                    m.mirrorOf = "";
                    for (let i = 0; i < next.length; i++) {
                        if (next[i].mirrorOf === m.name)
                            next[i].mirrorOf = "";
                    }
                } else {
                    let maxR = 0;
                    let hasOthers = false;
                    for (let i = 0; i < next.length; i++) {
                        if (i !== root.selectedIndex && !next[i].disabled && !next[i].mirrorOf) {
                            hasOthers = true;
                            const os = Displays.logicalSize(next[i]);
                            if (next[i].x + os.w > maxR)
                                maxR = next[i].x + os.w;
                        }
                    }
                    if (hasOthers) {
                        m.x = maxR;
                        m.y = 0;
                    }
                }
                root.normalizePositions(next);
                root.commitDraft(next);
            }
        }

        ConnectedRect {
            visible: root.selectedMonitor !== null
            Layout.fillWidth: true
            implicitHeight: scaleRowCol.implicitHeight + Tokens.padding.medium * 2
            opacity: (root.selectedMonitor && (root.selectedMonitor.disabled || root.selectedMonitor.mirrorOf)) ? 0.5 : 1

            ColumnLayout {
                id: scaleRowCol

                anchors.fill: parent
                anchors.topMargin: Tokens.padding.medium
                anchors.bottomMargin: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Scale (HiDPI)")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            if (!root.selectedMonitor)
                                return "";
                            const sz = Displays.logicalSize(root.selectedMonitor);
                            return Tr.tr("Effective logical size: %1 × %2 px (%3)").arg(sz.w).arg(sz.h).arg(root.formatScaleLabel(root.selectedMonitor.scale));
                        }
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.selectedScaleChoices

                        TextButton {
                            required property real modelData

                            readonly property bool isCur: root.selectedMonitor ? (Math.abs(Number(root.selectedMonitor.scale) - modelData) < 0.015) : false

                            type: isCur ? TextButton.Filled : TextButton.Tonal
                            isRound: true
                            disabled: !root.selectedMonitor || root.selectedMonitor.disabled || !!root.selectedMonitor.mirrorOf
                            text: root.formatScaleLabel(modelData)
                            onClicked: {
                                root.mutateSelectedWithSeamAdjust(m => {
                                    m.scale = modelData;
                                });
                            }
                        }
                    }
                }
            }
        }

        SelectRow {
            id: resSelectRow

            visible: root.selectedMonitor !== null
            enabled: root.selectedMonitor ? !root.selectedMonitor.disabled : false
            opacity: enabled ? 1 : 0.5
            label: Tr.tr("Resolution")
            subtext: Tr.tr("Native resolution first, sorted descending")
            fallbackText: root.selectedMonitor ? `${root.selectedMonitor.width} × ${root.selectedMonitor.height}` : "—"
            menuItems: [...resMenuVariants.instances].sort((a, b) => a.sortIndex - b.sortIndex)
            active: menuItems.find(i => i.value === (root.selectedMonitor ? root.selectedMonitor.res : "")) ?? null
            onSelected: item => {
                if (!item || !root.selectedMonitor || root.selectedMonitor.disabled)
                    return;
                const chosenRes = String(item.value);
                const resObj = root.selectedResolutions.find(r => r.res === chosenRes);
                if (!resObj || !resObj.rates || resObj.rates.length === 0)
                    return;
                const bestRate = resObj.rates[0];
                root.mutateSelectedWithSeamAdjust(m => {
                    m.res = resObj.res;
                    m.width = resObj.width;
                    m.height = resObj.height;
                    m.refreshRate = bestRate.hz;
                    m.mode = bestRate.mode;
                });
            }

            Variants {
                id: resMenuVariants

                model: root.selectedResolutions

                MenuItem {
                    required property var modelData

                    readonly property int sortIndex: Number(modelData.sortIndex ?? 0)

                    text: modelData.label
                    value: modelData.res
                }
            }
        }

        SelectRow {
            id: rateSelectRow

            visible: root.selectedMonitor !== null
            enabled: root.selectedMonitor ? !root.selectedMonitor.disabled : false
            opacity: enabled ? 1 : 0.5
            label: Tr.tr("Refresh rate")
            subtext: Tr.tr("Available rates for the selected resolution")
            fallbackText: root.selectedMonitor ? `${Math.round(root.selectedMonitor.refreshRate)} Hz` : "—"
            menuItems: [...rateMenuVariants.instances].sort((a, b) => a.sortIndex - b.sortIndex)
            active: menuItems.find(i => i.value === (root.selectedMonitor ? root.selectedMonitor.mode : "")) ?? null
            onSelected: item => {
                if (!item || !root.selectedMonitor || root.selectedMonitor.disabled)
                    return;
                const chosenMode = String(item.value);
                const rateObj = root.selectedRates.find(rt => rt.mode === chosenMode);
                if (!rateObj)
                    return;
                const next = root.cloneMonitors(root.draftMonitors);
                const m = next[root.selectedIndex];
                if (!m)
                    return;
                m.mode = rateObj.mode;
                m.refreshRate = rateObj.hz;
                root.commitDraft(next);
            }

            Variants {
                id: rateMenuVariants

                model: root.selectedRates

                MenuItem {
                    required property var modelData

                    readonly property int sortIndex: Number(modelData.sortIndex ?? 0)

                    text: modelData.label
                    value: modelData.mode
                }
            }
        }

        ConnectedRect {
            visible: root.selectedMonitor !== null
            Layout.fillWidth: true
            implicitHeight: rotRowCol.implicitHeight + Tokens.padding.medium * 2
            opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.5 : 1

            ColumnLayout {
                id: rotRowCol

                anchors.fill: parent
                anchors.topMargin: Tokens.padding.medium
                anchors.bottomMargin: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Orientation")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.rotationOptions

                        TextButton {
                            required property var modelData

                            readonly property bool isCur: root.selectedMonitor ? ((root.selectedMonitor.transform || 0) === modelData.value) : false

                            type: isCur ? TextButton.Filled : TextButton.Tonal
                            isRound: true
                            disabled: !root.selectedMonitor || root.selectedMonitor.disabled
                            text: modelData.label
                            onClicked: {
                                root.mutateSelectedWithSeamAdjust(m => {
                                    m.transform = modelData.value;
                                });
                            }
                        }
                    }
                }
            }
        }

        SelectRow {
            id: mirrorSelectRow

            visible: root.selectedMonitor !== null
            last: true
            enabled: root.selectedMonitor ? !root.selectedMonitor.disabled : false
            opacity: enabled ? 1 : 0.5
            label: Tr.tr("Mirror display")
            subtext: Tr.tr("Duplicate the contents of another active display")
            fallbackText: (root.selectedMonitor && root.selectedMonitor.mirrorOf) ? Tr.tr("Mirroring %1").arg(root.selectedMonitor.mirrorOf) : Tr.tr("Off (Extended)")
            menuItems: [mirrorNoneItem, ...mirrorTargetVariants.instances]
            active: menuItems.find(i => i.value === (root.selectedMonitor ? (root.selectedMonitor.mirrorOf || "") : "")) ?? mirrorNoneItem
            onSelected: item => {
                if (!item || !root.selectedMonitor || root.selectedMonitor.disabled)
                    return;
                const targetName = String(item.value || "");
                const next = root.cloneMonitors(root.draftMonitors);
                const m = next[root.selectedIndex];
                if (!m)
                    return;
                m.mirrorOf = targetName;
                if (!targetName) {
                    let maxR = 0;
                    for (let i = 0; i < next.length; i++) {
                        if (i !== root.selectedIndex && !next[i].disabled && !next[i].mirrorOf) {
                            const os = Displays.logicalSize(next[i]);
                            if (next[i].x + os.w > maxR)
                                maxR = next[i].x + os.w;
                        }
                    }
                    m.x = maxR;
                    m.y = 0;
                }
                root.normalizePositions(next);
                root.commitDraft(next);
            }

            MenuItem {
                id: mirrorNoneItem

                text: Tr.tr("Off (Extended)")
                value: ""
            }

            Variants {
                id: mirrorTargetVariants

                model: root.mirrorTargetMonitors

                MenuItem {
                    required property var modelData

                    text: Tr.tr("Mirror %1 (%2)").arg(modelData.name).arg(modelData.shortLabel)
                    value: modelData.name
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Quick projection & profiles")
        }

        RowButton {
            first: true
            icon: "open_in_new"
            text: Tr.tr("Open projection popup")
            subtext: Tr.tr("Compact overlay for fast projector and monitor switching")
            onClicked: Displays.openPopupRequested()
        }

        RowButton {
            visible: Displays.hasSavedProfile
            icon: "bookmark_remove"
            text: Tr.tr("Forget saved profile for this setup")
            subtext: Tr.tr("Re-enables the automatic projection popup when connecting these displays")
            onClicked: Displays.forgetSavedProfile()
        }

        ConnectedRect {
            last: true
            Layout.fillWidth: true
            implicitHeight: presetFlowCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: presetFlowCol

                anchors.fill: parent
                anchors.topMargin: Tokens.padding.medium
                anchors.bottomMargin: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("One-click presets")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.presetOptions

                        IconTextButton {
                            required property var modelData

                            type: TextButton.Tonal
                            isRound: true
                            icon: modelData.icon
                            text: modelData.title
                            onClicked: root.applyPreset(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
