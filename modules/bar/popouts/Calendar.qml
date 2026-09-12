pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

CustomMouseArea {
    id: root

    required property PopoutState popouts

    property int activeGridIndex: 0
    property date grid1Date: new Date()
    property date grid2Date: new Date()

    readonly property date currentActiveDate: root.activeGridIndex === 0 ? root.grid1Date : root.grid2Date
    readonly property MonthGrid currentActiveGrid: root.activeGridIndex === 0 ? grid : grid2

    property date viewDate: new Date()
    property date selectedDate: new Date()
    property date rangeEndDate: new Date()
    readonly property bool isRangeSelected: !root.isSameDay(root.selectedDate, root.rangeEndDate)
    property real selectionDrawProgress: 1.0
    property int prevRangeDays: 0

    readonly property int nonAnimCurrMonth: root.viewDate.getMonth()
    readonly property int nonAnimCurrYear: root.viewDate.getFullYear()

    readonly property list<int> nonSunnyShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]
    property int currentShape: MaterialShape.Sunny

    readonly property date today: new Date()

    property bool isAdding: false
    property string editingId: ""
    readonly property bool isFormOpen: root.isAdding || root.editingId !== ""
    property string formStartDate: ""
    property string formEndDate: ""
    // Implicit-cancel draft stash (day-click / wheel-navigate preserve typed input)
    property string draftMode: ""
    property string draftEditingId: ""
    property string draftTitle: ""
    property string draftTime: ""
    property string draftDesc: ""
    property string draftStartDate: ""
    property string draftEndDate: ""

    property int scrollDirection: 1
    property real scrollProgress: 0
    property bool isTransitioning: false

    property real headerAnimTranslate: 0
    property real headerAnimOpacity: 1
    property string displayTitle: Qt.formatDate(root.currentActiveDate, "MMMM yyyy")
    property int waveEpoch: 0
    property Item selectedDayItem1: null
    property Item selectedDayItem2: null
    property Item todayItem1: null
    property Item todayItem2: null
    property var lastDeletedEvent: null
    property list<var> retiringWaves: []
    property int retiringAnimTick: 0
    property bool prevReverse: false

    function randomizeShape(): void {
        if (root.isSameDay(root.selectedDate, root.today)) {
            root.currentShape = MaterialShape.Sunny;
            return;
        }
        let nextShape = root.nonSunnyShapeList[Math.floor(Math.random() * root.nonSunnyShapeList.length)];
        while (nextShape === root.currentShape && root.nonSunnyShapeList.length > 1) {
            nextShape = root.nonSunnyShapeList[Math.floor(Math.random() * root.nonSunnyShapeList.length)];
        }
        root.currentShape = nextShape;
    }

    function isSameDay(d1: var, d2: var): bool {
        if (!d1 || !d2)
            return false;
        return d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate();
    }

    function isDateInRange(d: var, start: var, end: var): bool {
        if (!d || !start || !end)
            return false;
        const val = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
        const val1 = start.getFullYear() * 10000 + (start.getMonth() + 1) * 100 + start.getDate();
        const val2 = end.getFullYear() * 10000 + (end.getMonth() + 1) * 100 + end.getDate();
        return val >= Math.min(val1, val2) && val <= Math.max(val1, val2);
    }

    function dateAtPos(targetGrid: MonthGrid, fromItem: Item, mx: real, my: real): var {
        if (!targetGrid || !targetGrid.visible || !targetGrid.contentItem || !targetGrid.contentItem.children)
            return null;
        const pt = fromItem ? fromItem.mapToItem(targetGrid.contentItem, mx, my) : targetGrid.mapToItem(targetGrid.contentItem, mx, my);
        const children = targetGrid.contentItem.children;
        for (let i = 0; i < children.length; ++i) {
            const c = children[i];
            if (!c.model || !c.model.date)
                continue;
            if (pt.x >= c.x && pt.x < c.x + c.width && pt.y >= c.y && pt.y < c.y + c.height)
                return c.model.date;
        }
        return null;
    }

    function startAdd(): void {
        const hasDraft = root.draftMode === "add" && (root.draftTitle !== "" || root.draftDesc !== "" || root.draftStartDate !== "");
        isAdding = true;
        editingId = "";
        const s = Events.formatDateKey(root.selectedDate);
        const e = root.isRangeSelected ? Events.formatDateKey(root.rangeEndDate) : "";
        if (e && e < s) {
            formStartDate = e;
            formEndDate = s;
        } else {
            formStartDate = s;
            formEndDate = e;
        }
        titleField.text = hasDraft ? root.draftTitle : "";
        timeField.text = (hasDraft && root.draftTime !== "") ? root.draftTime : Time.format(GlobalConfig.services.useTwelveHourClock ? "h:mm AP" : "hh:mm");
        descField.text = hasDraft ? root.draftDesc : "";
        if (hasDraft) {
            formStartDate = root.draftStartDate || formStartDate;
            formEndDate = root.draftEndDate;
        }
        root.clearDraft();
        Qt.callLater(() => {
            if (root.isFormOpen)
                titleField.forceActiveFocus();
        });
    }

    function startEdit(evt: var): void {
        const hasDraft = root.draftMode === "edit" && root.draftEditingId === evt.id;
        isAdding = false;
        editingId = evt.id;
        formStartDate = hasDraft ? (root.draftStartDate || evt.date) : evt.date;
        formEndDate = hasDraft ? root.draftEndDate : (evt.endDate || "");
        titleField.text = hasDraft ? root.draftTitle : (evt.title || "");
        timeField.text = hasDraft ? root.draftTime : (evt.time || "");
        descField.text = hasDraft ? root.draftDesc : (evt.description || "");
        root.clearDraft();
        Qt.callLater(() => {
            if (root.isFormOpen)
                titleField.forceActiveFocus();
        });
    }

    function clearDraft(): void {
        root.draftMode = "";
        root.draftEditingId = "";
        root.draftTitle = "";
        root.draftTime = "";
        root.draftDesc = "";
        root.draftStartDate = "";
        root.draftEndDate = "";
    }

    function cancelForm(keepDraft: bool): void {
        if (keepDraft) {
            root.draftMode = root.isAdding ? "add" : (root.editingId !== "" ? "edit" : "");
            root.draftEditingId = root.editingId;
            root.draftTitle = titleField.text;
            root.draftTime = timeField.text;
            root.draftDesc = descField.text;
            root.draftStartDate = root.formStartDate;
            root.draftEndDate = root.formEndDate;
        } else {
            root.clearDraft();
        }
        isAdding = false;
        editingId = "";
        formStartDate = "";
        formEndDate = "";
        titleField.text = "";
        timeField.text = "";
        descField.text = "";
        addBtn.forceActiveFocus();
    }

    function saveForm(): void {
        const title = titleField.text.trim();
        if (!title)
            return;
        const startDate = formStartDate || Events.formatDateKey(root.selectedDate);
        const endDate = formEndDate;

        if (isAdding) {
            Events.addEvent(startDate, timeField.text.trim(), title, descField.text.trim(), endDate);
        } else if (editingId) {
            Events.updateEvent(editingId, timeField.text.trim(), title, descField.text.trim(), startDate, endDate);
        }
        root.clearRetiringWave(startDate, endDate);
        root.rangeEndDate = root.selectedDate;
        root.prevRangeDays = 0;
        root.selectionDrawProgress = 0;
        selectionDrawAnim.stop();
        cancelForm(false);
    }

    function navigateMonth(newDate: date): void {
        if (root.isFormOpen)
            root.cancelForm(true);

        if (newDate.getMonth() === root.viewDate.getMonth() && newDate.getFullYear() === root.viewDate.getFullYear()) {
            root.viewDate = newDate;
            return;
        }

        if (transitionAnim.running)
            transitionAnim.complete();

        const currentActive = root.currentActiveDate;
        root.scrollDirection = newDate > currentActive ? 1 : -1;
        root.viewDate = newDate;

        if (root.activeGridIndex === 0) {
            root.grid2Date = newDate;
        } else {
            root.grid1Date = newDate;
        }

        root.isTransitioning = true;
        root.waveEpoch++;
        transitionAnim.restart();
    }

    function resetToToday(): void {
        if (root.isRangeSelected)
            root.retireActiveWave();
        if (root.isFormOpen)
            root.cancelForm(true);

        const now = new Date();
        selectedDate = now;
        rangeEndDate = now;
        prevRangeDays = 0;
        selectionDrawProgress = 0;
        prevReverse = false;
        selectionDrawAnim.stop();
        currentShape = MaterialShape.Sunny;
        root.navigateMonth(now);
    }

    function deleteWithUndo(evt: var): void {
        if (!evt)
            return;
        root.lastDeletedEvent = evt;
        undoTimer.restart();
        Events.deleteEvent(evt.id);
    }

    function undoDelete(): void {
        if (!root.lastDeletedEvent)
            return;
        Events.restoreEvent(root.lastDeletedEvent);
        root.lastDeletedEvent = null;
        undoTimer.stop();
    }

    function retireActiveWave(): void {
        if (!root.isRangeSelected)
            return;
        const s = Events.formatDateKey(root.selectedDate);
        const e = Events.formatDateKey(root.rangeEndDate);
        if (!s || !e || s === e)
            return;
        const minKey = s < e ? s : e;
        const maxKey = s < e ? e : s;

        if (root.retiringWaves.some(w => w && w.startDate === minKey && w.endDate === maxKey))
            return;

        const dStart = new Date(minKey + "T12:00:00");
        const dEnd = new Date(maxKey + "T12:00:00");
        const days = Math.max(1, Math.round(Math.abs(dEnd.getTime() - dStart.getTime()) / (1000 * 60 * 60 * 24)));
        const baseDuration = days > 25 ? 1100 : (days > 15 ? 900 : 600);

        retiringWaveComp.createObject(root, {
            startDate: minKey,
            endDate: maxKey,
            animDuration: Math.round(baseDuration * (Tokens.anim.durations.scale ?? 1))
        });
    }

    function addRetiringWave(rw: var): void {
        root.retiringWaves = [...root.retiringWaves, rw];
    }

    function removeRetiringWave(rw: var): void {
        root.retiringWaves = root.retiringWaves.filter(w => w !== rw);
    }

    function clearRetiringWave(sKey: string, eKey: string): void {
        const minK = sKey < eKey ? sKey : eKey;
        const maxK = sKey < eKey ? eKey : sKey;
        const matches = root.retiringWaves.filter(w => w && w.startDate === minK && w.endDate === maxK);
        for (let i = 0; i < matches.length; ++i) {
            if (matches[i])
                matches[i].destroy();
        }
    }

    function clearAllRetiringWaves(): void {
        for (let i = 0; i < root.retiringWaves.length; ++i) {
            if (root.retiringWaves[i])
                root.retiringWaves[i].destroy();
        }
        root.retiringWaves = [];
    }

    function updateRangeSelection(newEndDate: date): void {
        if (!newEndDate)
            return;
        if (root.isSameDay(root.selectedDate, newEndDate)) {
            if (root.isRangeSelected)
                root.retireActiveWave();
            root.rangeEndDate = newEndDate;
            root.prevRangeDays = 0;
            root.selectionDrawProgress = 0;
            root.prevReverse = false;
            selectionDrawAnim.stop();
            return;
        }

        const sKey = Events.formatDateKey(root.selectedDate);
        const oldEKey = Events.formatDateKey(root.rangeEndDate);
        const newEKey = Events.formatDateKey(newEndDate);

        const isReverse = sKey > newEKey;
        const dirFlipped = isReverse !== root.prevReverse;
        root.prevReverse = isReverse;

        const dStart = new Date(sKey + "T12:00:00");
        const dOldEnd = new Date(oldEKey + "T12:00:00");
        const dNewEnd = new Date(newEKey + "T12:00:00");

        const oldDays = root.isRangeSelected ? Math.max(1, Math.round(Math.abs(dOldEnd.getTime() - dStart.getTime()) / (1000 * 60 * 60 * 24))) : 0;
        const newDays = Math.max(1, Math.round(Math.abs(dNewEnd.getTime() - dStart.getTime()) / (1000 * 60 * 60 * 24)));

        root.rangeEndDate = newEndDate;

        let startProgress = 0;
        if (!dirFlipped && oldDays > 0 && oldDays < newDays && !root.isSameDay(root.rangeEndDate, root.selectedDate))
            startProgress = oldDays / newDays;

        const baseDuration = newDays > 25 ? 1100 : (newDays > 15 ? 900 : 600);

        selectionDrawAnim.stop();
        selectionDrawAnim.from = startProgress;
        selectionDrawAnim.to = 1.0;
        selectionDrawAnim.duration = Math.round(baseDuration * Math.max(0.3, 1.0 - startProgress)) * (Tokens.anim.durations.scale ?? 1);
        selectionDrawAnim.start();
        root.prevRangeDays = newDays;
    }

    function moveSelectionDays(offset: int, isShift: bool): void {
        if (root.isFormOpen)
            return;
        const targetBase = isShift ? root.rangeEndDate : root.selectedDate;
        const newDate = new Date(targetBase.getFullYear(), targetBase.getMonth(), targetBase.getDate() + offset);
        if (isShift) {
            root.updateRangeSelection(newDate);
        } else {
            if (root.isRangeSelected)
                root.retireActiveWave();
            root.selectedDate = newDate;
            root.rangeEndDate = newDate;
            root.prevRangeDays = 0;
            root.selectionDrawProgress = 0;
            root.prevReverse = false;
            selectionDrawAnim.stop();
            root.randomizeShape();
        }
        if (newDate.getMonth() !== root.viewDate.getMonth() || newDate.getFullYear() !== root.viewDate.getFullYear()) {
            root.navigateMonth(newDate);
        }
    }

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            root.navigateMonth(new Date(nonAnimCurrYear, nonAnimCurrMonth - 1, 1));
        else if (event.angleDelta.y < 0)
            root.navigateMonth(new Date(nonAnimCurrYear, nonAnimCurrMonth + 1, 1));
    }

    function formatHumanDate(dateKey: var): string {
        if (!dateKey)
            return "";
        const key = Events.formatDateKey(dateKey);
        if (key) {
            const d = new Date(key + "T12:00:00");
            if (!isNaN(d.getTime()))
                return Qt.formatDate(d, "MMM d");
        }
        const fallback = dateKey instanceof Date ? dateKey : new Date(dateKey);
        return isNaN(fallback.getTime()) ? String(dateKey) : Qt.formatDate(fallback, "MMM d");
    }

    function formatHumanRange(startKey: var, endKey: var): string {
        const sStr = root.formatHumanDate(startKey);
        const eStr = root.formatHumanDate(endKey);
        if (!sStr)
            return eStr;
        if (!eStr || sStr === eStr)
            return sStr;
        return `${sStr} → ${eStr}`;
    }

    implicitWidth: 320
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    acceptedButtons: Qt.MiddleButton
    onClicked: root.resetToToday()

    Timer {
        id: undoTimer

        interval: 5000
        onTriggered: root.lastDeletedEvent = null
    }

    NumberAnimation {
        id: selectionDrawAnim

        target: root
        property: "selectionDrawProgress"
        from: 0.0
        to: 1.0
        duration: 600 * (Tokens.anim.durations.scale ?? 1)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.64, 0.06, 0.47, 0.91, 1, 1]
    }

    Component {
        id: retiringWaveComp

        QtObject {
            id: rwItem

            property string startDate: ""
            property string endDate: ""
            property real progress: 0.0
            property int animDuration: 600

            property var anim: NumberAnimation {
                target: rwItem
                property: "progress"
                from: 0.0
                to: 1.0
                duration: rwItem.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.64, 0.06, 0.47, 0.91, 1, 1]
                running: true
                onFinished: rwItem.destroy()
            }

            onProgressChanged: root.retiringAnimTick++
            Component.onCompleted: root.addRetiringWave(rwItem)
            Component.onDestruction: root.removeRetiringWave(rwItem)
        }
    }

    ParallelAnimation {
        id: transitionAnim

        onFinished: {
            root.activeGridIndex = root.activeGridIndex === 0 ? 1 : 0;
            root.displayTitle = Qt.formatDate(root.viewDate, "MMMM yyyy");
            root.isTransitioning = false;
            root.scrollProgress = 0;
            root.waveEpoch++;
        }

        Anim {
            target: root
            property: "scrollProgress"
            from: 0
            to: 1
            duration: Tokens.anim.durations.expressiveDefaultSpatial * 1.3 * (Tokens.anim.durations.scale ?? 1)
            type: Anim.DefaultSpatial
        }

        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "headerAnimTranslate"
                    to: root.Tokens.padding.extraLarge * -root.scrollDirection
                    type: Anim.FastSpatial
                }
                Anim {
                    target: root
                    property: "headerAnimOpacity"
                    to: 0
                    type: Anim.FastEffects
                }
            }
            ScriptAction {
                script: {
                    root.displayTitle = Qt.formatDate(root.viewDate, "MMMM yyyy");
                    root.headerAnimTranslate = root.Tokens.padding.extraLarge * root.scrollDirection;
                }
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "headerAnimTranslate"
                    to: 0
                    duration: Tokens.anim.durations.expressiveDefaultSpatial * 1.3 * (Tokens.anim.durations.scale ?? 1)
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: root
                    property: "headerAnimOpacity"
                    to: 1
                    duration: Tokens.anim.durations.expressiveDefaultSpatial * 1.3 * (Tokens.anim.durations.scale ?? 1)
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    Connections {
        function onCurrentNameChanged(): void {
            if (root.popouts.currentName !== "clock") {
                if (root.isFormOpen)
                    root.cancelForm(true);
                dragArea.hoveredDate = null;
                dragArea.startPressDate = null;
                dragArea.isDragging = false;
                root.lastDeletedEvent = null;
                undoTimer.stop();
                root.clearAllRetiringWaves();
            }
        }

        target: root.popouts
    }

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            text: Time.format(GlobalConfig.services.useTwelveHourClock ? "h:mm:ss AP" : "hh:mm:ss")
            font: Tokens.font.title.builders.medium.weight(Font.Bold).build()
            color: Colours.palette.m3primary
        }

        RowLayout {
            id: monthNavigationRow

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            IconButton {
                isRound: true
                icon: "chevron_left"
                Accessible.name: Tr.tr("Previous month")
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small
                onClicked: root.navigateMonth(new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth - 1, 1))
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                implicitWidth: monthYearDisplay.implicitWidth + Tokens.padding.large * 2
                implicitHeight: monthYearDisplay.implicitHeight + Tokens.padding.extraSmall * 2

                StateLayer {
                    color: Colours.palette.m3primary
                    radius: pressed ? Tokens.rounding.small : height / 2
                    disabled: root.nonAnimCurrMonth === root.today.getMonth() && root.nonAnimCurrYear === root.today.getFullYear() && root.isSameDay(root.selectedDate, root.today)
                    onClicked: root.resetToToday()

                    Behavior on radius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                StyledText {
                    id: monthYearDisplay

                    opacity: root.headerAnimOpacity
                    transform: Translate {
                        x: root.headerAnimTranslate
                    }

                    anchors.centerIn: parent
                    text: root.displayTitle
                    color: Colours.palette.m3primary
                    font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                }
            }

            IconButton {
                isRound: true
                icon: "chevron_right"
                Accessible.name: Tr.tr("Next month")
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small
                onClicked: root.navigateMonth(new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth + 1, 1))
            }
        }

        DayOfWeekRow {
            id: daysRow

            Layout.fillWidth: true
            Layout.leftMargin: gridViewport.pad
            Layout.rightMargin: gridViewport.pad
            locale: root.currentActiveGrid.locale

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: (model.day === 6 || model.day === 7) ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
            }
        }

        Item {
            id: gridViewport

            readonly property real pad: Tokens.padding.extraSmall + 2

            Layout.fillWidth: true
            implicitHeight: (root.isTransitioning ? Math.max(grid.implicitHeight, grid2.implicitHeight) : root.currentActiveGrid.implicitHeight) + pad * 2
            clip: true

            // Month Grid Buffer 1
            Item {
                id: grid1Container

                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height
                y: {
                    if (!root.isTransitioning)
                        return root.activeGridIndex === 0 ? 0 : -gridViewport.height;
                    if (root.activeGridIndex === 0)
                        return -gridViewport.height * root.scrollDirection * root.scrollProgress;
                    return gridViewport.height * root.scrollDirection * (1.0 - root.scrollProgress);
                }
                visible: root.activeGridIndex === 0 || root.isTransitioning

                // Today marker (soft Sunny shape when a different date is selected)
                MaterialShape {
                    id: todayIndicator

                    readonly property Item todayItem: {
                        if (root.todayItem1)
                            return root.todayItem1;
                        const _m = grid.month;
                        const _y = grid.year;
                        if (!grid.contentItem || !grid.contentItem.children)
                            return null;
                        return grid.contentItem.children.find(c => c.model && c.model.month === _m && c.model.today) ?? null;
                    }

                    x: todayItem ? Math.round(grid.x + todayItem.x + (todayItem.width - implicitWidth) / 2) : 0
                    y: todayItem ? Math.round(grid.y + todayItem.y + (todayItem.height - implicitHeight) / 2) : 0
                    z: 0

                    implicitSize: todayItem ? Math.max(todayItem.implicitWidth, todayItem.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                    shape: MaterialShape.Sunny

                    clip: true
                    color: Colours.palette.m3primary
                    opacity: todayItem && !root.isSameDay(root.selectedDate, root.today) ? 0.3 : 0
                    visible: opacity > 0
                }

                // Group container for both MonthWaves and MonthGrid
                Item {
                    id: gridGroup1

                    anchors.fill: parent
                    opacity: (root.activeGridIndex === 0 || (grid.contentItem && grid.contentItem.children && grid.contentItem.children.length >= 28)) ? 1 : 0

                    // Multi-Day Organic Wave Shapes
                    MonthWaves {
                        anchors.fill: grid
                        grid: grid
                    }

                    MonthGrid {
                        id: grid

                        anchors.fill: parent
                        anchors.margins: gridViewport.pad
                        z: 1

                        month: root.grid1Date.getMonth()
                        year: root.grid1Date.getFullYear()

                        spacing: 3
                        locale: Qt.locale()

                        delegate: DayCell {
                            grid: grid
                        }
                    }
                }

                // Wrapper providing the exact dynamic shape alpha mask
                Item {
                    id: shapeWrapper1

                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.samples: 4
                    z: 2

                    // Active Selected Date Indicator with Randomized MaterialShape Morphing
                    MaterialShape {
                        id: selectionIndicator

                        readonly property var selectedItem: {
                            if (root.selectedDayItem1)
                                return root.selectedDayItem1;
                            const _m = grid.month;
                            const _y = grid.year;
                            const _sd = root.selectedDate;
                            if (!grid.contentItem || !grid.contentItem.children)
                                return null;
                            return grid.contentItem.children.find(c => c.model && c.model.month === _m && root.isSameDay(_sd, c.model.date)) ?? null;
                        }

                        x: selectedItem ? Math.round(grid.x + selectedItem.x + (selectedItem.width - implicitWidth) / 2) : 0
                        y: selectedItem ? Math.round(grid.y + selectedItem.y + (selectedItem.height - implicitHeight) / 2) : 0

                        implicitSize: selectedItem ? Math.max(selectedItem.implicitWidth, selectedItem.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                        shape: root.currentShape

                        color: Colours.palette.m3primary
                        opacity: selectedItem ? 1 : 0
                        visible: opacity > 0

                        animationEasing: Tokens.anim.expressiveDefaultSpatial
                        animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * (Tokens.anim.durations.scale ?? 1)

                        Behavior on color {
                            CAnim {}
                        }

                        Behavior on x {
                            enabled: !root.isTransitioning && root.activeGridIndex === 0 && selectionIndicator.selectedItem !== null

                            Anim {
                                type: Anim.Emphasized
                            }
                        }

                        Behavior on y {
                            enabled: !root.isTransitioning && root.activeGridIndex === 0 && selectionIndicator.selectedItem !== null

                            Anim {
                                type: Anim.Emphasized
                            }
                        }

                        MaterialShape {
                            id: shapeHoverOverlay

                            anchors.fill: parent
                            shape: selectionIndicator.shape
                            animationEasing: selectionIndicator.animationEasing
                            animationDuration: selectionIndicator.animationDuration

                            color: Colours.palette.m3onPrimary
                            opacity: {
                                if (selectionIndicator.selectedItem?.isPressed)
                                    return 0.15;
                                if (selectionIndicator.selectedItem?.isHovered)
                                    return 0.10;
                                return 0;
                            }

                            Behavior on opacity {
                                Anim {
                                    type: Anim.FastEffects
                                }
                            }
                        }
                    }
                }

                // Inverted text, dots, and wave overlay masked to the exact vector shape
                Colouriser {
                    anchors.fill: parent
                    z: 3

                    source: gridGroup1
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onPrimary

                    maskEnabled: true
                    maskSource: shapeWrapper1
                    maskSpreadAtMin: 1
                    maskThresholdMin: 0.5

                    opacity: selectionIndicator.opacity
                    visible: opacity > 0
                }
            }

            // Month Grid Buffer 2
            Item {
                id: grid2Container

                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height
                y: {
                    if (!root.isTransitioning)
                        return root.activeGridIndex === 1 ? 0 : -gridViewport.height;
                    if (root.activeGridIndex === 1)
                        return -gridViewport.height * root.scrollDirection * root.scrollProgress;
                    return gridViewport.height * root.scrollDirection * (1.0 - root.scrollProgress);
                }
                visible: root.activeGridIndex === 1 || root.isTransitioning

                // Today marker for Buffer 2
                MaterialShape {
                    id: todayIndicator2

                    readonly property Item todayItem: {
                        if (root.todayItem2)
                            return root.todayItem2;
                        const _m = grid2.month;
                        const _y = grid2.year;
                        if (!grid2.contentItem || !grid2.contentItem.children)
                            return null;
                        return grid2.contentItem.children.find(c => c.model && c.model.month === _m && c.model.today) ?? null;
                    }

                    x: todayItem ? Math.round(grid2.x + todayItem.x + (todayItem.width - implicitWidth) / 2) : 0
                    y: todayItem ? Math.round(grid2.y + todayItem.y + (todayItem.height - implicitHeight) / 2) : 0
                    z: 0

                    implicitSize: todayItem ? Math.max(todayItem.implicitWidth, todayItem.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                    shape: MaterialShape.Sunny

                    clip: true
                    color: Colours.palette.m3primary
                    opacity: todayItem && !root.isSameDay(root.selectedDate, root.today) ? 0.3 : 0
                    visible: opacity > 0
                }

                // Group container for both MonthWaves and MonthGrid for Buffer 2
                Item {
                    id: gridGroup2

                    anchors.fill: parent
                    opacity: (root.activeGridIndex === 1 || (grid2.contentItem && grid2.contentItem.children && grid2.contentItem.children.length >= 28)) ? 1 : 0

                    // Multi-Day Organic Wave Shapes for Buffer 2
                    MonthWaves {
                        anchors.fill: grid2
                        grid: grid2
                    }

                    MonthGrid {
                        id: grid2

                        anchors.fill: parent
                        anchors.margins: gridViewport.pad
                        z: 1

                        month: root.grid2Date.getMonth()
                        year: root.grid2Date.getFullYear()

                        spacing: 3
                        locale: Qt.locale()

                        delegate: DayCell {
                            grid: grid2
                        }
                    }
                }

                // Wrapper providing the exact dynamic shape alpha mask for Buffer 2
                Item {
                    id: shapeWrapper2

                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.samples: 4
                    z: 2

                    // Active Selected Date Indicator for Buffer 2
                    MaterialShape {
                        id: selectionIndicator2

                        readonly property var selectedItem: {
                            if (root.selectedDayItem2)
                                return root.selectedDayItem2;
                            const _m = grid2.month;
                            const _y = grid2.year;
                            const _sd = root.selectedDate;
                            if (!grid2.contentItem || !grid2.contentItem.children)
                                return null;
                            return grid2.contentItem.children.find(c => c.model && c.model.month === _m && root.isSameDay(_sd, c.model.date)) ?? null;
                        }

                        x: selectedItem ? Math.round(grid2.x + selectedItem.x + (selectedItem.width - implicitWidth) / 2) : 0
                        y: selectedItem ? Math.round(grid2.y + selectedItem.y + (selectedItem.height - implicitHeight) / 2) : 0

                        implicitSize: selectedItem ? Math.max(selectedItem.implicitWidth, selectedItem.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                        shape: root.currentShape

                        color: Colours.palette.m3primary
                        opacity: selectedItem ? 1 : 0
                        visible: opacity > 0

                        animationEasing: Tokens.anim.expressiveDefaultSpatial
                        animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * (Tokens.anim.durations.scale ?? 1)

                        Behavior on color {
                            CAnim {}
                        }

                        Behavior on x {
                            enabled: !root.isTransitioning && root.activeGridIndex === 1 && selectionIndicator2.selectedItem !== null

                            Anim {
                                type: Anim.Emphasized
                            }
                        }

                        Behavior on y {
                            enabled: !root.isTransitioning && root.activeGridIndex === 1 && selectionIndicator2.selectedItem !== null

                            Anim {
                                type: Anim.Emphasized
                            }
                        }

                        MaterialShape {
                            id: shapeHoverOverlay2

                            anchors.fill: parent
                            shape: selectionIndicator2.shape
                            animationEasing: selectionIndicator2.animationEasing
                            animationDuration: selectionIndicator2.animationDuration

                            color: Colours.palette.m3onPrimary
                            opacity: {
                                if (selectionIndicator2.selectedItem?.isPressed)
                                    return 0.15;
                                if (selectionIndicator2.selectedItem?.isHovered)
                                    return 0.10;
                                return 0;
                            }

                            Behavior on opacity {
                                Anim {
                                    type: Anim.FastEffects
                                }
                            }
                        }
                    }
                }

                // Inverted text, dots, and wave overlay masked to the exact vector shape for Buffer 2
                Colouriser {
                    anchors.fill: parent
                    z: 3

                    source: gridGroup2
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onPrimary

                    maskEnabled: true
                    maskSource: shapeWrapper2
                    maskSpreadAtMin: 1
                    maskThresholdMin: 0.5

                    opacity: selectionIndicator2.opacity
                    visible: opacity > 0
                }
            }

            MouseArea {
                id: dragArea

                property real startX: 0
                property real startY: 0
                property var startPressDate: null
                property var hoveredDate: null
                property bool isDragging: false

                anchors.fill: parent
                z: 10
                hoverEnabled: true
                cursorShape: (dragArea.hoveredDate && !root.isTransitioning) ? Qt.PointingHandCursor : Qt.ArrowCursor
                activeFocusOnTab: true
                focus: true

                Keys.onLeftPressed: event => {
                    if (!root.isTransitioning)
                        root.moveSelectionDays(-1, event.modifiers & Qt.ShiftModifier);
                    event.accepted = true;
                }
                Keys.onRightPressed: event => {
                    if (!root.isTransitioning)
                        root.moveSelectionDays(1, event.modifiers & Qt.ShiftModifier);
                    event.accepted = true;
                }
                Keys.onUpPressed: event => {
                    if (!root.isTransitioning)
                        root.moveSelectionDays(-7, event.modifiers & Qt.ShiftModifier);
                    event.accepted = true;
                }
                Keys.onDownPressed: event => {
                    if (!root.isTransitioning)
                        root.moveSelectionDays(7, event.modifiers & Qt.ShiftModifier);
                    event.accepted = true;
                }
                Keys.onReturnPressed: event => {
                    if (!root.isFormOpen && !root.isTransitioning) {
                        root.startAdd();
                        event.accepted = true;
                    }
                }
                Keys.onSpacePressed: event => {
                    if (!root.isFormOpen && !root.isTransitioning) {
                        root.startAdd();
                        event.accepted = true;
                    }
                }

                onPressed: mouse => {
                    if (root.isTransitioning)
                        return;
                    if (mouse.button === Qt.LeftButton)
                        dragArea.forceActiveFocus();
                    startX = mouse.x;
                    startY = mouse.y;
                    isDragging = false;
                    const d = root.dateAtPos(root.currentActiveGrid, dragArea, mouse.x, mouse.y);
                    startPressDate = d;
                    if (!d)
                        return;
                    if (mouse.modifiers & Qt.ControlModifier) {
                        root.updateRangeSelection(d);
                    } else {
                        if (root.isRangeSelected)
                            root.retireActiveWave();
                        if (root.isFormOpen)
                            root.cancelForm(true);
                        root.selectedDate = d;
                        root.rangeEndDate = d;
                        root.prevRangeDays = 0;
                        root.selectionDrawProgress = 0;
                        root.prevReverse = false;
                        selectionDrawAnim.stop();
                        root.randomizeShape();
                    }
                }

                onPositionChanged: mouse => {
                    if (root.isTransitioning)
                        return;
                    const d = root.dateAtPos(root.currentActiveGrid, dragArea, mouse.x, mouse.y);
                    hoveredDate = d;
                    if (!mouse.buttons)
                        return;
                    const dx = mouse.x - startX;
                    const dy = mouse.y - startY;
                    if (!isDragging && (dx * dx + dy * dy >= 36))
                        isDragging = true;
                }

                onReleased: mouse => {
                    if (root.isTransitioning)
                        return;
                    const d = root.dateAtPos(root.currentActiveGrid, dragArea, mouse.x, mouse.y);
                    if (isDragging && d && !root.isSameDay(root.selectedDate, d)) {
                        root.updateRangeSelection(d);
                    }
                    if (d && d.getMonth() !== root.currentActiveGrid.month)
                        root.navigateMonth(d);
                    isDragging = false;
                    startPressDate = null;
                }

                onExited: () => {
                    hoveredDate = null;
                    if (!pressed) {
                        startPressDate = null;
                        isDragging = false;
                    }
                }
                onCanceled: {
                    hoveredDate = null;
                    startPressDate = null;
                    isDragging = false;
                }
            }
        }

        // Divider
        StyledRect {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            Layout.bottomMargin: Tokens.spacing.extraSmall
            implicitHeight: 1
            color: Colours.palette.m3outlineVariant
        }

        // Events Section Header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Events • %1").arg(Qt.formatDate(root.selectedDate, "ddd, MMM d"))
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3primary
            }

            Item {
                implicitHeight: Math.max(addBtn.implicitHeight, formActions.implicitHeight)
                implicitWidth: root.isFormOpen ? formActions.implicitWidth : addBtn.implicitWidth

                Behavior on implicitWidth {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                // Add Event Button [+]
                IconButton {
                    id: addBtn

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    isRound: true
                    icon: "add"
                    Accessible.name: Tr.tr("Add event")
                    type: IconButton.Text
                    padding: Tokens.padding.extraSmall
                    font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                    visible: opacity > 0
                    opacity: !root.isFormOpen ? 1 : 0
                    scale: !root.isFormOpen ? 1 : 0.6
                    enabled: !root.isFormOpen
                    onClicked: root.startAdd()

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                }

                // Form Action Buttons [✓] and [✕]
                RowLayout {
                    id: formActions

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.extraSmall
                    visible: opacity > 0
                    opacity: root.isFormOpen ? 1 : 0
                    scale: root.isFormOpen ? 1 : 0.6
                    enabled: root.isFormOpen

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    // Save Button [✓]
                    IconButton {
                        isRound: true
                        icon: "check"
                        Accessible.name: Tr.tr("Save event")
                        type: IconButton.Filled
                        padding: Tokens.padding.extraSmall
                        enabled: root.isFormOpen && (titleField.text ?? "").trim().length > 0
                        onClicked: root.saveForm()
                    }

                    // Cancel Button [✕]
                    IconButton {
                        isRound: true
                        icon: "close"
                        Accessible.name: Tr.tr("Cancel")
                        type: IconButton.Text
                        padding: Tokens.padding.extraSmall
                        onClicked: root.cancelForm(false)
                    }
                }
            }
        }

        // Events Agenda & Form Container
        Item {
            Layout.fillWidth: true
            implicitHeight: eventsInner.implicitHeight
            clip: true

            ColumnLayout {
                id: eventsInner

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.spacing.small

                // --- Inline Form (Add or Edit) ---
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.isFormOpen
                    spacing: Tokens.spacing.small

                    // Date range indicator chip
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.extraSmall
                        Layout.rightMargin: Tokens.padding.extraSmall
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: root.formEndDate && root.formEndDate !== root.formStartDate ? "date_range" : "event"
                            font: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                if (root.formEndDate && root.formEndDate !== root.formStartDate) {
                                    const minD = root.formStartDate < root.formEndDate ? root.formStartDate : root.formEndDate;
                                    const maxD = root.formStartDate < root.formEndDate ? root.formEndDate : root.formStartDate;
                                    return root.formatHumanRange(minD, maxD);
                                }
                                return root.formatHumanDate(root.formStartDate || Events.formatDateKey(root.selectedDate));
                            }
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        IconButton {
                            visible: root.formEndDate && root.formEndDate !== root.formStartDate
                            isRound: true
                            icon: "close"
                            Accessible.name: Tr.tr("Clear date range")
                            type: IconButton.Text
                            padding: Tokens.padding.extraSmall
                            font: Tokens.font.icon.builders.small.scale(0.8).build()
                            onClicked: {
                                if (root.isRangeSelected)
                                    root.retireActiveWave();
                                root.formEndDate = "";
                                root.rangeEndDate = root.selectedDate;
                                root.prevRangeDays = 0;
                                root.selectionDrawProgress = 0;
                                selectionDrawAnim.stop();
                            }
                        }
                    }

                    TransparentTextField {
                        id: titleField

                        Layout.fillWidth: true
                        placeholderText: root.isAdding ? Tr.tr("New Event") : Tr.tr("Event title")
                        leadingIcon: "edit"
                        KeyNavigation.tab: timeField
                        KeyNavigation.backtab: descField
                        onAccepted: root.saveForm()
                        Keys.onEscapePressed: event => {
                            root.cancelForm(false);
                            event.accepted = true;
                        }
                    }

                    TransparentTextField {
                        id: timeField

                        Layout.fillWidth: true
                        placeholderText: Tr.tr("Time")
                        leadingIcon: "schedule"
                        KeyNavigation.tab: descField
                        KeyNavigation.backtab: titleField
                        onAccepted: root.saveForm()
                        Keys.onEscapePressed: event => {
                            root.cancelForm(false);
                            event.accepted = true;
                        }
                    }

                    TransparentTextField {
                        id: descField

                        Layout.fillWidth: true
                        placeholderText: Tr.tr("Description")
                        leadingIcon: "notes"
                        KeyNavigation.tab: titleField
                        KeyNavigation.backtab: timeField
                        onAccepted: root.saveForm()
                        Keys.onEscapePressed: event => {
                            root.cancelForm(false);
                            event.accepted = true;
                        }
                    }
                }

                // --- Events List (Rows) ---
                Flickable {
                    id: eventsFlickable

                    readonly property var dayEvents: Events.getEvents(Events.formatDateKey(root.selectedDate))
                    property real savedContentY: 0
                    property string lastSelectedDateKey: ""

                    onDayEventsChanged: {
                        const currentKey = Events.formatDateKey(root.selectedDate);
                        if (currentKey !== lastSelectedDateKey) {
                            lastSelectedDateKey = currentKey;
                            savedContentY = 0;
                            contentY = 0;
                        } else {
                            const prevY = savedContentY;
                            Qt.callLater(() => {
                                if (eventsFlickable)
                                    eventsFlickable.contentY = Math.min(prevY, Math.max(0, eventsFlickable.contentHeight - eventsFlickable.height));
                            });
                        }
                    }

                    onContentYChanged: {
                        if (contentY >= 0)
                            savedContentY = contentY;
                    }

                    Layout.fillWidth: true
                    implicitHeight: Math.min(eventsListCol.implicitHeight, 220)
                    contentHeight: eventsListCol.implicitHeight
                    clip: true
                    visible: !root.isFormOpen && dayEvents.length > 0

                    ColumnLayout {
                        id: eventsListCol

                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: Tokens.spacing.extraSmall

                        // Event Items Repeater
                        Repeater {
                            model: ScriptModel {
                                values: eventsFlickable.dayEvents
                            }

                            Item {
                                id: eventRow

                                required property var modelData

                                implicitHeight: rowInner.implicitHeight + Tokens.padding.extraSmall * 2
                                Layout.fillWidth: true

                                RowLayout {
                                    id: rowInner

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Tokens.padding.extraSmall
                                    anchors.rightMargin: Tokens.padding.extraSmall
                                    spacing: Tokens.spacing.small

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            spacing: Tokens.spacing.extraSmall

                                            StyledText {
                                                visible: (eventRow.modelData.time || "").length > 0
                                                text: eventRow.modelData.time || ""
                                                font: Tokens.font.label.small
                                                color: Colours.palette.m3primary
                                            }

                                            StyledText {
                                                visible: (eventRow.modelData.time || "").length > 0
                                                text: "•"
                                                font: Tokens.font.label.small
                                                color: Colours.palette.m3outline
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: eventRow.modelData.title
                                                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                                                color: Colours.palette.m3onSurface
                                                elide: Text.ElideRight
                                            }
                                        }

                                        RowLayout {
                                            visible: Boolean(eventRow.modelData.endDate && eventRow.modelData.endDate > eventRow.modelData.date)
                                            spacing: Tokens.spacing.extraSmall

                                            MaterialIcon {
                                                text: "date_range"
                                                font: Tokens.font.icon.builders.small.scale(0.75).build()
                                                color: Colours.palette.m3tertiary
                                            }

                                            StyledText {
                                                text: root.formatHumanRange(eventRow.modelData.date, eventRow.modelData.endDate)
                                                font: Tokens.font.body.builders.small.scale(0.8).build()
                                                color: Colours.palette.m3tertiary
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            visible: (eventRow.modelData.description || "").length > 0
                                            text: eventRow.modelData.description || ""
                                            font: Tokens.font.body.builders.small.scale(0.85).build()
                                            color: Colours.palette.m3onSurfaceVariant
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // Edit Button
                                    IconButton {
                                        isRound: true
                                        icon: "edit"
                                        Accessible.name: Tr.tr("Edit event")
                                        type: IconButton.Text
                                        font: Tokens.font.icon.small
                                        padding: Tokens.padding.extraSmall
                                        onClicked: root.startEdit(eventRow.modelData)
                                    }

                                    // Delete Button
                                    IconButton {
                                        isRound: true
                                        icon: "delete"
                                        Accessible.name: Tr.tr("Delete event")
                                        type: IconButton.Text
                                        inactiveOnColour: Colours.palette.m3error
                                        font: Tokens.font.icon.small
                                        padding: Tokens.padding.extraSmall
                                        onClicked: root.deleteWithUndo(eventRow.modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                // Undo Row
                RowLayout {
                    id: undoRow

                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.extraSmall
                    Layout.rightMargin: Tokens.padding.extraSmall
                    visible: root.lastDeletedEvent !== null
                    opacity: visible ? 1 : 0
                    spacing: Tokens.spacing.small

                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Event deleted")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    TextButton {
                        text: Tr.tr("Undo")
                        Accessible.name: Tr.tr("Undo delete")
                        type: TextButton.Text
                        onClicked: root.undoDelete()
                    }

                    IconButton {
                        isRound: true
                        icon: "close"
                        Accessible.name: Tr.tr("Dismiss")
                        type: IconButton.Text
                        font: Tokens.font.icon.builders.small.scale(0.8).build()
                        padding: Tokens.padding.extraSmall
                        onClicked: {
                            undoTimer.stop();
                            root.lastDeletedEvent = null;
                        }
                    }
                }
            }
        }
    }

    component MonthWaves: Shape {
        id: wavesRoot

        required property MonthGrid grid

        readonly property int epoch: root.waveEpoch
        readonly property var ranges: {
            const _e = wavesRoot.epoch;
            return Events.getRangesForMonth(wavesRoot.grid.year, wavesRoot.grid.month);
        }
        readonly property bool hasActiveSelectionRange: {
            const _e = wavesRoot.epoch;
            if (!root.isRangeSelected)
                return false;
            const s = Events.formatDateKey(root.selectedDate);
            const e = Events.formatDateKey(root.rangeEndDate);
            const minKey = s < e ? s : e;
            const maxKey = s < e ? e : s;
            const y = wavesRoot.grid.year;
            const m = wavesRoot.grid.month;
            const monthStart = `${y}-${String(m + 1).padStart(2, "0")}-01`;
            const lastDay = new Date(y, m + 1, 0).getDate();
            const monthEnd = `${y}-${String(m + 1).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
            return minKey <= monthEnd && maxKey >= monthStart;
        }
        readonly property bool hasRetiringRanges: {
            const _e = wavesRoot.epoch;
            const rws = root.retiringWaves;
            if (!rws || rws.length === 0)
                return false;
            const y = wavesRoot.grid.year;
            const m = wavesRoot.grid.month;
            const monthStart = `${y}-${String(m + 1).padStart(2, "0")}-01`;
            const lastDay = new Date(y, m + 1, 0).getDate();
            const monthEnd = `${y}-${String(m + 1).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
            return rws.some(rw => rw && rw.startDate <= monthEnd && rw.endDate >= monthStart);
        }

        function computeRangeSvg(sDate: string, eDate: string, startProgress: real, endProgress: real, reverse: bool): string {
            const p0 = Math.max(0.0, Math.min(1.0, startProgress));
            const p1 = Math.max(0.0, Math.min(1.0, endProgress));
            if (p0 >= p1)
                return "";

            const g = wavesRoot.grid;
            if (!g || !g.contentItem || !g.contentItem.children || g.contentItem.children.length === 0)
                return "";

            const minKey = sDate < eDate ? sDate : eDate;
            const maxKey = sDate < eDate ? eDate : sDate;

            const children = g.contentItem.children;
            const cells = [];
            for (let i = 0; i < children.length; ++i) {
                const c = children[i];
                if (!c.model || !c.model.date)
                    continue;
                const key = Events.formatDateKey(c.model.date);
                if (key >= minKey && key <= maxKey) {
                    const fallbackDotY = c.y + (c.height + 18) / 2 + 3;
                    const dotY = c.dotCenterY !== undefined ? c.dotCenterY : fallbackDotY;
                    const evts = Events.getEvents(key);
                    const count = Math.min(evts.length, 5);
                    let dotX = c.x + c.width / 2;
                    if (count > 1) {
                        const halfOffset = ((count - 1) * 5.5) / 2;
                        if (key === minKey) {
                            dotX = c.x + c.width / 2 + halfOffset;
                        } else if (key === maxKey) {
                            dotX = c.x + c.width / 2 - halfOffset;
                        }
                    }
                    cells.push({
                        key: key,
                        x: c.x,
                        y: c.y,
                        width: c.width,
                        height: c.height,
                        dotX: dotX,
                        dotY: dotY
                    });
                }
            }

            if (cells.length === 0)
                return "";

            cells.sort((a, b) => a.key.localeCompare(b.key));

            const rows = [];
            let currentRow = [cells[0]];
            for (let i = 1; i < cells.length; ++i) {
                const prev = cells[i - 1];
                const curr = cells[i];
                if (Math.abs(curr.y - prev.y) < 5) {
                    currentRow.push(curr);
                } else {
                    rows.push(currentRow);
                    currentRow = [curr];
                }
            }
            if (currentRow.length > 0)
                rows.push(currentRow);

            const rowData = [];
            let totalDist = 0;

            for (let r = 0; r < rows.length; ++r) {
                const rowCells = rows[r];
                if (rowCells.length === 0)
                    continue;

                const first = rowCells[0];
                const last = rowCells[rowCells.length - 1];
                const dotY = first.dotY;

                const isEventStart = (first.key === minKey);
                const isEventEnd = (last.key === maxKey);

                const waypoints = [];
                if (!isEventStart)
                    waypoints.push(first.x);
                for (let i = 0; i < rowCells.length; ++i)
                    waypoints.push(rowCells[i].dotX);
                if (!isEventEnd)
                    waypoints.push(last.x + last.width);

                if (waypoints.length < 2)
                    continue;

                let rowLen = 0;
                for (let i = 0; i < waypoints.length - 1; ++i) {
                    const span = Math.abs(waypoints[i + 1] - waypoints[i]);
                    if (span > 0)
                        rowLen += span;
                }

                rowData.push({
                    waypoints: waypoints,
                    dotY: dotY,
                    rowLen: rowLen
                });
                totalDist += rowLen;
            }

            if (totalDist <= 0 || rowData.length === 0)
                return "";

            if (reverse) {
                rowData.reverse();
                for (let r = 0; r < rowData.length; ++r)
                    rowData[r].waypoints.reverse();
            }

            const d0 = p0 * totalDist;
            const d1 = p1 * totalDist;
            if (d0 >= d1)
                return "";

            function subQuad(p0x, p0y, p1x, p1y, p2x, p2y, u0, u1) {
                const c0 = (1 - u0) * (1 - u0);
                const c1 = 2 * u0 * (1 - u0);
                const c2 = u0 * u0;
                const r0x = c0 * p0x + c1 * p1x + c2 * p2x;
                const r0y = c0 * p0y + c1 * p1y + c2 * p2y;

                const m0 = (1 - u0) * (1 - u1);
                const m1 = u0 + u1 - 2 * u0 * u1;
                const m2 = u0 * u1;
                const r1x = m0 * p0x + m1 * p1x + m2 * p2x;
                const r1y = m0 * p0y + m1 * p1y + m2 * p2y;

                const k0 = (1 - u1) * (1 - u1);
                const k1 = 2 * u1 * (1 - u1);
                const k2 = u1 * u1;
                const r2x = k0 * p0x + k1 * p1x + k2 * p2x;
                const r2y = k0 * p0y + k1 * p1y + k2 * p2y;

                return {
                    r0x: r0x,
                    r0y: r0y,
                    r1x: r1x,
                    r1y: r1y,
                    r2x: r2x,
                    r2y: r2y
                };
            }

            let accumDist = 0;
            let svgPath = "";
            const amp = 2.5;

            for (let r = 0; r < rowData.length; ++r) {
                const rd = rowData[r];
                const waypoints = rd.waypoints;
                const dotY = rd.dotY;

                let d = "";
                let drawnInRow = false;

                for (let i = 0; i < waypoints.length - 1; ++i) {
                    const xA = waypoints[i];
                    const xB = waypoints[i + 1];
                    const dx = xB - xA;
                    const span = Math.abs(dx);
                    if (span <= 0)
                        continue;

                    const segStart = accumDist;
                    const segEnd = accumDist + span;
                    accumDist = segEnd;

                    if (segEnd <= d0 || segStart >= d1)
                        continue;

                    const t0 = Math.max(0.0, (d0 - segStart) / span);
                    const t1 = Math.min(1.0, (d1 - segStart) / span);
                    if (t0 >= t1)
                        continue;

                    const dir = dx >= 0 ? 1 : -1;
                    const half = span / 2;
                    const p0x = xA, p0y = dotY;
                    const p1x = xA + dir * (span / 4), p1y = dotY - dir * amp;
                    const p2x = xA + dir * half, p2y = dotY;

                    const q0x = xA + dir * half, q0y = dotY;
                    const q1x = xA + dir * (3 * span / 4), q1y = dotY + dir * amp;
                    const q2x = xB, q2y = dotY;

                    // First half [0.0, 0.5]
                    if (t0 < 0.5) {
                        const u0 = t0 * 2.0;
                        const u1 = Math.min(1.0, t1 * 2.0);
                        if (u0 < u1) {
                            const sq = subQuad(p0x, p0y, p1x, p1y, p2x, p2y, u0, u1);
                            if (!drawnInRow) {
                                d += `M ${sq.r0x.toFixed(2)},${sq.r0y.toFixed(2)} `;
                                drawnInRow = true;
                            }
                            d += `Q ${sq.r1x.toFixed(2)},${sq.r1y.toFixed(2)} ${sq.r2x.toFixed(2)},${sq.r2y.toFixed(2)} `;
                        }
                    }

                    // Second half [0.5, 1.0]
                    if (t1 > 0.5) {
                        const v0 = Math.max(0.0, (t0 - 0.5) * 2.0);
                        const v1 = (t1 - 0.5) * 2.0;
                        if (v0 < v1) {
                            const sq = subQuad(q0x, q0y, q1x, q1y, q2x, q2y, v0, v1);
                            if (!drawnInRow) {
                                d += `M ${sq.r0x.toFixed(2)},${sq.r0y.toFixed(2)} `;
                                drawnInRow = true;
                            }
                            d += `Q ${sq.r1x.toFixed(2)},${sq.r1y.toFixed(2)} ${sq.r2x.toFixed(2)},${sq.r2y.toFixed(2)} `;
                        }
                    }
                }

                if (drawnInRow)
                    svgPath += d + " ";
            }

            return svgPath;
        }

        preferredRendererType: Shape.CurveRenderer
        asynchronous: true
        anchors.fill: parent
        z: 2

        // Saved Event Ranges (Permanent Waves)
        ShapePath {
            strokeWidth: 2
            strokeColor: Colours.palette.m3primary
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: {
                    const _e = wavesRoot.epoch;
                    const ranges = wavesRoot.ranges;
                    if (!ranges || ranges.length === 0)
                        return "";
                    let fullPath = "";
                    for (let i = 0; i < ranges.length; ++i) {
                        const r = ranges[i];
                        fullPath += wavesRoot.computeRangeSvg(r.startDate, r.endDate, 0.0, 1.0, false) + " ";
                    }
                    return fullPath;
                }
            }
        }

        // Active Range Selection Wave (Drawing in forward)
        ShapePath {
            strokeWidth: 2
            strokeColor: Colours.palette.m3tertiary
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: {
                    const _e = wavesRoot.epoch;
                    const _p = root.selectionDrawProgress;
                    if (!wavesRoot.hasActiveSelectionRange || _p <= 0)
                        return "";
                    const s = Events.formatDateKey(root.selectedDate);
                    const e = Events.formatDateKey(root.rangeEndDate);
                    const minKey = s < e ? s : e;
                    const maxKey = s < e ? e : s;
                    return wavesRoot.computeRangeSvg(minKey, maxKey, 0.0, _p, s > e);
                }
            }
        }

        // Retiring Selection Waves (Erasing forward from start to end in parallel)
        ShapePath {
            strokeWidth: 2
            strokeColor: Colours.palette.m3tertiary
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: {
                    const _e = wavesRoot.epoch;
                    const _tick = root.retiringAnimTick;
                    const rws = root.retiringWaves;
                    if (!wavesRoot.hasRetiringRanges || !rws || rws.length === 0)
                        return "";
                    let fullPath = "";
                    for (let i = 0; i < rws.length; ++i) {
                        const rw = rws[i];
                        if (rw && rw.progress < 1.0)
                            fullPath += wavesRoot.computeRangeSvg(rw.startDate, rw.endDate, rw.progress, 1.0, false) + " ";
                    }
                    return fullPath;
                }
            }
        }
    }

    component DayCell: Item {
        id: dayItem

        required property MonthGrid grid
        required property var model

        Accessible.role: Accessible.Cell
        Accessible.name: dayItem.model ? Qt.formatDate(dayItem.model.date, "dddd, MMMM d, yyyy") : ""
        Accessible.selected: dayItem.isSelected

        readonly property real dotCenterX: dayItem.x + dayItem.width / 2
        readonly property real dotCenterY: dayItem.y + (text.y > 0 ? (text.y + text.height + 3) : ((dayItem.height + text.implicitHeight) / 2 + 3))
        readonly property bool isSelected: dayItem.model.month === dayItem.grid.month && root.isSameDay(root.selectedDate, dayItem.model.date)
        readonly property bool isToday: dayItem.model.month === dayItem.grid.month && Boolean(dayItem.model.today)
        readonly property var dayEvents: Events.getEvents(Events.formatDateKey(dayItem.model.date))
        readonly property int eventCount: Math.min(dayItem.dayEvents.length, 5)
        readonly property bool hasEvents: dayItem.eventCount > 0
        readonly property bool isHovered: root.isSameDay(dragArea.hoveredDate, dayItem.model.date)
        readonly property bool isPressed: dragArea.pressed && root.isSameDay(dragArea.startPressDate, dayItem.model.date)
        readonly property bool isInDragRange: dragArea.isDragging && root.isDateInRange(dayItem.model?.date, dragArea.startPressDate, dragArea.hoveredDate)

        implicitWidth: implicitHeight
        implicitHeight: text.implicitHeight + Tokens.padding.medium

        onIsSelectedChanged: {
            if (isSelected) {
                if (dayItem.grid === grid2)
                    root.selectedDayItem2 = dayItem;
                else
                    root.selectedDayItem1 = dayItem;
            } else {
                if (dayItem.grid === grid2 && root.selectedDayItem2 === dayItem)
                    root.selectedDayItem2 = null;
                else if (root.selectedDayItem1 === dayItem)
                    root.selectedDayItem1 = null;
            }
        }

        onIsTodayChanged: {
            if (isToday) {
                if (dayItem.grid === grid2)
                    root.todayItem2 = dayItem;
                else
                    root.todayItem1 = dayItem;
            } else {
                if (dayItem.grid === grid2 && root.todayItem2 === dayItem)
                    root.todayItem2 = null;
                else if (root.todayItem1 === dayItem)
                    root.todayItem1 = null;
            }
        }

        Component.onCompleted: {
            if (isSelected) {
                if (dayItem.grid === grid2)
                    root.selectedDayItem2 = dayItem;
                else
                    root.selectedDayItem1 = dayItem;
            }
            if (isToday) {
                if (dayItem.grid === grid2)
                    root.todayItem2 = dayItem;
                else
                    root.todayItem1 = dayItem;
            }
        }

        Component.onDestruction: {
            if (root.selectedDayItem1 === dayItem)
                root.selectedDayItem1 = null;
            if (root.selectedDayItem2 === dayItem)
                root.selectedDayItem2 = null;
            if (root.todayItem1 === dayItem)
                root.todayItem1 = null;
            if (root.todayItem2 === dayItem)
                root.todayItem2 = null;
        }

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.small
            color: Colours.palette.m3onSurface
            opacity: {
                if (dayItem.isSelected)
                    return 0;
                if (dayItem.isPressed)
                    return 0.15;
                if (dayItem.isHovered || dayItem.isInDragRange)
                    return 0.08;
                return 0;
            }

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }

        StyledText {
            id: text

            anchors.centerIn: parent

            horizontalAlignment: Text.AlignHCenter
            text: dayItem.grid.locale.toString(dayItem.model.day)
            color: {
                const dayOfWeek = dayItem.model.date.getDay();
                if (dayOfWeek === 0 || dayOfWeek === 6)
                    return Colours.palette.m3tertiary;

                return Colours.palette.m3onSurfaceVariant;
            }
            opacity: dayItem.model.today || dayItem.model.month === dayItem.grid.month ? 1 : 0.4
            font: Tokens.font.body.small
        }

        Row {
            anchors.top: text.bottom
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            visible: dayItem.eventCount > 0

            Repeater {
                model: dayItem.eventCount

                StyledRect {
                    required property int index

                    readonly property var evt: dayItem.dayEvents[index]
                    readonly property bool isRange: Boolean(evt && evt.endDate && evt.endDate > evt.date)

                    width: 4
                    height: 4
                    radius: Tokens.rounding.full
                    color: isRange ? Colours.palette.m3tertiary : Colours.palette.m3primary
                    border.width: 0.8
                    border.color: Colours.palette.m3surface
                }
            }
        }
    }

    component TransparentTextField: StyledTextField {
        id: tf

        type: StyledTextField.Filled
        verticalPadding: Tokens.padding.large
        horizontalPadding: Tokens.padding.small
        topPadding: verticalPadding + filledOffset + Tokens.spacing.extraSmall
        bottomPadding: verticalPadding - filledOffset

        background: Item {
            StateLayer {
                id: stateLayer

                radius: Tokens.rounding.small
                cursorShape: Qt.IBeamCursor
                disabled: tf.activeFocus
                onClicked: tf.forceActiveFocus()
            }

            StyledRect {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: tf.activeFocus ? 2 : 1
                color: tf.isError ? Colours.palette.m3error : (tf.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.25))

                Behavior on implicitHeight {
                    Anim {}
                }

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }
}
