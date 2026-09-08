pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

CustomMouseArea {
    id: root

    required property PopoutState popouts

    property date viewDate: new Date()
    property date selectedDate: new Date()
    property date currentDate: root.viewDate
    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()
    readonly property int nonAnimCurrMonth: root.viewDate.getMonth()
    readonly property int nonAnimCurrYear: root.viewDate.getFullYear()

    readonly property list<int> nonSunnyShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]
    property int currentShape: MaterialShape.Sunny

    property bool eventsExpanded: true
    property bool isAdding: false
    property string editingId: ""
    readonly property bool isFormOpen: root.isAdding || root.editingId !== ""

    readonly property int animDirection: root.viewDate > currentDate ? -1 : 1
    property real animTranslate
    property real animOpacity: 1

    function randomizeShape(): void {
        if (root.isSameDay(root.selectedDate, new Date())) {
            currentShape = MaterialShape.Sunny;
            return;
        }

        let nextShape = nonSunnyShapeList[Math.floor(Math.random() * nonSunnyShapeList.length)];
        while (nextShape === currentShape && nonSunnyShapeList.length > 1) {
            nextShape = nonSunnyShapeList[Math.floor(Math.random() * nonSunnyShapeList.length)];
        }
        currentShape = nextShape;
    }

    function isSameDay(d1: var, d2: var): bool {
        if (!d1 || !d2)
            return false;
        return d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate();
    }

    function startAdd(): void {
        isAdding = true;
        editingId = "";
        titleField.text = "";
        timeField.text = Time.format(GlobalConfig.services.useTwelveHourClock ? "h:mm AP" : "hh:mm");
        descField.text = "";
        Qt.callLater(() => titleField.forceActiveFocus());
    }

    function startEdit(evt: var): void {
        isAdding = false;
        editingId = evt.id;
        titleField.text = evt.title || "";
        timeField.text = evt.time || "";
        descField.text = evt.description || "";
        Qt.callLater(() => titleField.forceActiveFocus());
    }

    function cancelForm(): void {
        isAdding = false;
        editingId = "";
        titleField.text = "";
        timeField.text = "";
        descField.text = "";
    }

    function saveForm(): void {
        const title = titleField.text.trim();
        if (!title)
            return;
        const dateKey = Events.formatDateKey(root.selectedDate);

        if (isAdding) {
            Events.addEvent(dateKey, timeField.text.trim(), title, descField.text.trim());
        } else if (editingId) {
            Events.updateEvent(editingId, timeField.text.trim(), title, descField.text.trim());
        }
        cancelForm();
    }

    function resetToToday(): void {
        const now = new Date();
        viewDate = now;
        selectedDate = now;
        currentShape = MaterialShape.Sunny;
        isAdding = false;
        editingId = "";
    }

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            root.viewDate = new Date(nonAnimCurrYear, nonAnimCurrMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            root.viewDate = new Date(nonAnimCurrYear, nonAnimCurrMonth + 1, 1);
    }

    implicitWidth: 320
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    acceptedButtons: Qt.MiddleButton
    onClicked: root.resetToToday()

    Anim {
        id: trOutAnim

        running: false
        target: root
        property: "animTranslate"
        to: root.Tokens.padding.extraLarge * root.animDirection
        type: Anim.FastSpatial
    }

    Behavior on currentDate {
        SequentialAnimation {
            ParallelAnimation {
                ScriptAction {
                    script: Qt.callLater(() => trOutAnim.start())
                }
                Anim {
                    target: root
                    property: "animOpacity"
                    to: 0
                    type: Anim.FastEffects
                }
            }
            ScriptAction {
                script: {
                    trOutAnim.complete();
                    root.animTranslate = root.Tokens.padding.extraLarge * -root.animDirection;
                }
            }
            PropertyAction {}
            ParallelAnimation {
                Anim {
                    target: root
                    property: "animTranslate"
                    to: 0
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: root
                    property: "animOpacity"
                    to: 1
                    type: Anim.DefaultEffects
                }
            }
        }
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
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small
                onClicked: root.viewDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth - 1, 1)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                implicitWidth: monthYearDisplay.implicitWidth + Tokens.padding.large * 2
                implicitHeight: monthYearDisplay.implicitHeight + Tokens.padding.extraSmall * 2

                StateLayer {
                    color: Colours.palette.m3primary
                    radius: pressed ? Tokens.rounding.small : height / 2
                    disabled: {
                        const now = new Date();
                        return root.nonAnimCurrMonth === now.getMonth() && root.nonAnimCurrYear === now.getFullYear() && root.isSameDay(root.selectedDate, now);
                    }
                    onClicked: root.resetToToday()

                    Behavior on radius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                StyledText {
                    id: monthYearDisplay

                    opacity: root.animOpacity
                    transform: Translate {
                        x: root.animTranslate
                    }

                    anchors.centerIn: parent
                    text: grid.title
                    color: Colours.palette.m3primary
                    font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                }
            }

            IconButton {
                isRound: true
                icon: "chevron_right"
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small
                onClicked: root.viewDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth + 1, 1)
            }
        }

        DayOfWeekRow {
            id: daysRow

            Layout.fillWidth: true
            locale: grid.locale

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: (model.day === 6 || model.day === 7 || model.day === 0) ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight

            opacity: root.animOpacity
            transform: Translate {
                x: root.animTranslate
            }

            // Today marker (soft Sunny shape when a different date is selected)
            MaterialShape {
                id: todayIndicator

                readonly property Item todayItem: grid.contentItem.children.find(c => c.model?.today) ?? null
                property Item today

                x: today ? today.x + (today.width - implicitWidth) / 2 : 0
                y: today ? today.y - Tokens.padding.extraSmall - 1 : 0
                z: 0

                implicitSize: today ? Math.max(today.implicitWidth, today.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                shape: MaterialShape.Sunny

                clip: true
                color: Colours.palette.m3primary
                opacity: todayItem && !root.isSameDay(root.selectedDate, new Date()) ? 0.3 : 0
                visible: opacity > 0

                onTodayItemChanged: {
                    if (todayItem)
                        today = todayItem;
                }
            }

            // Active Selected Date Indicator with Randomized MaterialShape Morphing
            MaterialShape {
                id: selectionIndicator

                readonly property Item selectedItem: grid.contentItem.children.find(c => c.model && root.isSameDay(root.selectedDate, c.model.date)) ?? null
                property Item targetItem

                x: targetItem ? targetItem.x + (targetItem.width - implicitWidth) / 2 : 0
                y: targetItem ? targetItem.y - Tokens.padding.extraSmall - 1 : 0
                z: 0

                implicitSize: targetItem ? Math.max(targetItem.implicitWidth, targetItem.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                shape: root.currentShape

                clip: true
                color: Colours.palette.m3primary
                opacity: targetItem && selectedItem ? 1 : 0

                animationEasing: Tokens.anim.expressiveDefaultSpatial
                animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

                onSelectedItemChanged: {
                    if (selectedItem)
                        targetItem = selectedItem;
                }

                Behavior on color {
                    CAnim {}
                }

                Behavior on x {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on y {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }

            MonthGrid {
                id: grid

                anchors.fill: parent
                z: 1

                month: root.currMonth
                year: root.currYear

                spacing: 3
                locale: Qt.locale()

                delegate: Item {
                    id: dayItem

                    required property var model
                    readonly property bool isSelected: root.isSameDay(root.selectedDate, dayItem.model.date)
                    readonly property bool hasEvents: Events.hasEvents(Events.formatDateKey(dayItem.model.date))

                    implicitWidth: implicitHeight
                    implicitHeight: text.implicitHeight + Tokens.padding.small + 6

                    StateLayer {
                        id: dayStateLayer

                        radius: Tokens.rounding.small
                        color: dayItem.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        onClicked: {
                            if (root.isFormOpen)
                                root.cancelForm();
                            root.selectedDate = dayItem.model.date;
                            root.randomizeShape();
                        }
                    }

                    StyledText {
                        id: text

                        anchors.centerIn: parent

                        horizontalAlignment: Text.AlignHCenter
                        text: grid.locale.toString(dayItem.model.day)
                        color: {
                            if (dayItem.isSelected)
                                return Colours.palette.m3onPrimary;
                            const dayOfWeek = dayItem.model.date.getDay();
                            if (dayOfWeek === 0 || dayOfWeek === 6)
                                return Colours.palette.m3tertiary;

                            return Colours.palette.m3onSurfaceVariant;
                        }
                        opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                        font: Tokens.font.body.small

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    StyledRect {
                        anchors.top: text.bottom
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 4
                        height: 4
                        radius: Tokens.rounding.full
                        color: dayItem.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                        visible: dayItem.hasEvents

                        Behavior on color {
                            CAnim {}
                        }
                    }
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
                text: qsTr("EVENTS • ") + Qt.formatDate(root.selectedDate, "ddd, MMM d").toUpperCase()
                font: Tokens.font.label.small
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
                        type: IconButton.Filled
                        padding: Tokens.padding.extraSmall
                        enabled: root.isFormOpen && (titleField.text ?? "").trim().length > 0
                        onClicked: root.saveForm()
                    }

                    // Cancel Button [✕]
                    IconButton {
                        isRound: true
                        icon: "close"
                        type: IconButton.Text
                        padding: Tokens.padding.extraSmall
                        onClicked: root.cancelForm()
                    }
                }
            }
        }

        // Events Agenda & Form Container
        Item {
            Layout.fillWidth: true
            implicitHeight: eventsInner.implicitHeight
            visible: root.eventsExpanded
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

                    TransparentTextField {
                        id: titleField

                        Layout.fillWidth: true
                        placeholderText: root.isAdding ? qsTr("New Event") : qsTr("Event title")
                        leadingIcon: "edit"
                        onAccepted: root.saveForm()
                        Keys.onEscapePressed: event => {
                            root.cancelForm();
                            event.accepted = true;
                        }
                    }

                    TransparentTextField {
                        id: timeField

                        Layout.fillWidth: true
                        placeholderText: qsTr("Time")
                        leadingIcon: "schedule"
                        onAccepted: root.saveForm()
                        Keys.onEscapePressed: event => {
                            root.cancelForm();
                            event.accepted = true;
                        }
                    }

                    TransparentTextField {
                        id: descField

                        Layout.fillWidth: true
                        placeholderText: qsTr("Description")
                        leadingIcon: "notes"
                        onAccepted: root.saveForm()
                        Keys.onEscapePressed: event => {
                            root.cancelForm();
                            event.accepted = true;
                        }
                    }
                }

                // --- Events List (Rows) ---
                ColumnLayout {
                    id: eventsListCol

                    readonly property var dayEvents: Events.getEvents(Events.formatDateKey(root.selectedDate))

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall
                    visible: !root.isFormOpen

                    // Event Items Repeater
                    Repeater {
                        model: ScriptModel {
                            values: eventsListCol.dayEvents
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
                                    type: IconButton.Text
                                    font: Tokens.font.icon.small
                                    padding: Tokens.padding.extraSmall
                                    onClicked: root.startEdit(eventRow.modelData)
                                }

                                // Delete Button
                                IconButton {
                                    isRound: true
                                    icon: "delete"
                                    type: IconButton.Text
                                    inactiveOnColour: Colours.palette.m3error
                                    font: Tokens.font.icon.small
                                    padding: Tokens.padding.extraSmall
                                    onClicked: Events.deleteEvent(eventRow.modelData.id)
                                }
                            }
                        }
                    }
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
