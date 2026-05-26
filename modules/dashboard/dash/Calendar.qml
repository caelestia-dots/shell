pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

CustomMouseArea {
    id: root

    required property DashboardState dashState

    readonly property int currMonth: dashState.currentDate.getMonth()
    readonly property int currYear: dashState.currentDate.getFullYear()
    readonly property bool reminderMode: dashState.timerPanelOpen && dashState.timerPanelTab === 2
    readonly property bool datePickMode: reminderMode && dashState.reminderPickedDate === ""
    readonly property bool dateSetMode: reminderMode && dashState.reminderPickedDate !== ""

    property string viewingReminderId: ""
    readonly property bool reminderDetailMode: !reminderMode && viewingReminderId !== ""
    readonly property var viewingReminder: viewingReminderId !== ""
        ? (ReminderService.reminders.find(r => r.id === viewingReminderId) ?? null)
        : null

    property int reminderHours: 0
    property int reminderMinutes: 0
    property string reminderText: ""

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            root.dashState.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            root.dashState.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
    }

    anchors.left: parent.left
    anchors.right: parent.right
    clip: true
    implicitHeight: inner.anchors.margins * 2 +
        monthNavigationRow.implicitHeight + inner.spacing +
        daysRow.implicitHeight + inner.spacing +
        calGridItem.implicitHeight

    acceptedButtons: Qt.MiddleButton
    onClicked: {
        if (!reminderMode)
            root.dashState.currentDate = new Date();
    }

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        // Month navigation row
        RowLayout {
            id: monthNavigationRow

            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            opacity: (root.dateSetMode || root.reminderDetailMode) ? 0 : 1
            visible: opacity > 0

            Behavior on opacity { Anim {} }

            Item {
                implicitWidth: implicitHeight
                implicitHeight: prevMonthText.implicitHeight + Tokens.padding.small * 2

                StateLayer {
                    radius: Tokens.rounding.full
                    onClicked: root.dashState.currentDate = new Date(root.currYear, root.currMonth - 1, 1)
                }

                MaterialIcon {
                    id: prevMonthText
                    anchors.centerIn: parent
                    text: "chevron_left"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 700
                }
            }

            Item {
                Layout.fillWidth: true
                implicitWidth: monthYearDisplay.implicitWidth + Tokens.padding.small * 2
                implicitHeight: monthYearDisplay.implicitHeight + Tokens.padding.small * 2

                StateLayer {
                    onClicked: {
                        if (!root.reminderMode)
                            root.dashState.currentDate = new Date();
                    }
                    anchors.fill: monthYearDisplay
                    anchors.margins: -Tokens.padding.small
                    anchors.leftMargin: -Tokens.padding.normal
                    anchors.rightMargin: -Tokens.padding.normal
                    radius: Tokens.rounding.full
                    disabled: root.reminderMode || (root.currMonth === new Date().getMonth() && root.currYear === new Date().getFullYear())
                }

                StyledText {
                    id: monthYearDisplay
                    anchors.centerIn: parent
                    text: grid.title
                    color: Colours.palette.m3primary
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 500
                    font.capitalization: Font.Capitalize
                }
            }

            Item {
                implicitWidth: implicitHeight
                implicitHeight: nextMonthText.implicitHeight + Tokens.padding.small * 2

                StateLayer {
                    onClicked: root.dashState.currentDate = new Date(root.currYear, root.currMonth + 1, 1)
                    radius: Tokens.rounding.full
                }

                MaterialIcon {
                    id: nextMonthText
                    anchors.centerIn: parent
                    text: "chevron_right"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 700
                }
            }

        }

        // Reminder date-set form (after picking a date)
        ColumnLayout {
            visible: root.dateSetMode
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            opacity: root.dateSetMode ? 1 : 0

            Behavior on opacity { Anim {} }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.dashState.reminderPickedDate
                font.pointSize: Tokens.font.size.extraLarge
                font.family: Tokens.font.family.mono
                font.weight: 600
                color: Colours.palette.m3primary
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small

                SpinGroup {
                    label: qsTr("H")
                    max: 23
                    value: root.reminderHours
                    onValueModified: v => root.reminderHours = v
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: ":"
                    font.pointSize: Tokens.font.size.larger
                    font.family: Tokens.font.family.mono
                    color: Colours.palette.m3onSurfaceVariant
                }

                SpinGroup {
                    label: qsTr("M")
                    max: 59
                    value: root.reminderMinutes
                    onValueModified: v => root.reminderMinutes = v
                }
            }

            StyledRect {
                Layout.fillWidth: true
                color: Colours.tPalette.m3surfaceContainerHigh
                radius: Tokens.rounding.small
                implicitHeight: textField.implicitHeight + Tokens.padding.small * 2

                TextInput {
                    id: textField
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.normal

                    color: Colours.palette.m3onSurface
                    font.pointSize: Tokens.font.size.normal
                    selectByMouse: true

                    onTextChanged: root.reminderText = text
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.normal
                    visible: textField.text.length === 0 && !textField.activeFocus
                    text: qsTr("Reminder text...")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.normal
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                IconTextButton {
                    Layout.fillWidth: true
                    inactiveColour: Colours.palette.m3primaryContainer
                    inactiveOnColour: Colours.palette.m3onPrimaryContainer
                    verticalPadding: Tokens.padding.small
                    text: qsTr("Set reminder")
                    icon: "alarm"
                    onClicked: {
                        const timeStr = String(root.reminderHours).padStart(2, "0") + ":" + String(root.reminderMinutes).padStart(2, "0");
                        ReminderService.addReminder(root.dashState.reminderPickedDate, timeStr, root.reminderText);
                        root.dashState.reminderPickedDate = "";
                        textField.text = "";
                        root.reminderText = "";
                        root.reminderHours = 0;
                        root.reminderMinutes = 0;
                    }
                }

                IconTextButton {
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    verticalPadding: Tokens.padding.small
                    text: qsTr("Cancel")
                    icon: "close"
                    onClicked: {
                        root.dashState.reminderPickedDate = "";
                        textField.text = "";
                        root.reminderText = "";
                    }
                }
            }
        }

        // Reminder detail view
        ColumnLayout {
            visible: root.reminderDetailMode
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            opacity: root.reminderDetailMode ? 1 : 0

            Behavior on opacity { Anim {} }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.viewingReminder?.date ?? ""
                font.pointSize: Tokens.font.size.extraLarge
                font.family: Tokens.font.family.mono
                font.weight: 600
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.viewingReminder?.time ?? ""
                font.pointSize: Tokens.font.size.larger
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: root.viewingReminder?.text ?? ""
                font.pointSize: Tokens.font.size.normal
                color: Colours.palette.m3onSurface
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                IconTextButton {
                    Layout.fillWidth: true
                    inactiveColour: Colours.palette.m3errorContainer
                    inactiveOnColour: Colours.palette.m3onErrorContainer
                    verticalPadding: Tokens.padding.small
                    text: qsTr("Remove")
                    icon: "delete"
                    onClicked: {
                        ReminderService.removeReminder(root.viewingReminderId);
                        root.viewingReminderId = "";
                    }
                }

                IconTextButton {
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    verticalPadding: Tokens.padding.small
                    text: qsTr("Close")
                    icon: "close"
                    onClicked: root.viewingReminderId = ""
                }
            }
        }

        // Day-of-week header
        DayOfWeekRow {
            id: daysRow

            Layout.fillWidth: true
            locale: grid.locale
            opacity: (root.dateSetMode || root.reminderDetailMode) ? 0 : 1
            visible: opacity > 0

            Behavior on opacity { Anim {} }

            delegate: StyledText {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.weight: 500
                color: (model.day === 0 || model.day === 6) ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant
            }
        }

        // Calendar grid
        Item {
            id: calGridItem
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight
            opacity: (root.dateSetMode || root.reminderDetailMode) ? 0 : 1
            visible: opacity > 0

            Behavior on opacity { Anim {} }

            MonthGrid {
                id: grid

                month: root.currMonth
                year: root.currYear

                anchors.fill: parent

                spacing: 3
                locale: Qt.locale()

                delegate: Item {
                    id: dayItem

                    required property var model

                    implicitWidth: implicitHeight
                    implicitHeight: dayText.implicitHeight + Tokens.padding.small * 2

                    readonly property bool hasReminder: ReminderService.reminders.some(
                        r => r.date === dayItem.model.date.toISOString().slice(0, 10)
                    )

                    StyledText {
                        id: dayText

                        anchors.centerIn: parent

                        horizontalAlignment: Text.AlignHCenter
                        text: grid.locale.toString(dayItem.model.day)
                        color: {
                            const dayOfWeek = dayItem.model.date.getUTCDay();
                            if (dayOfWeek === 0 || dayOfWeek === 6)
                                return Colours.palette.m3secondary;
                            return Colours.palette.m3onSurfaceVariant;
                        }
                        opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                        font.pointSize: Tokens.font.size.normal
                        font.weight: 500
                    }

                    // Reminder dot
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 4
                        height: 4
                        radius: 2
                        color: Colours.palette.m3primary
                        visible: dayItem.hasReminder
                    }

                    // Click to pick date for reminder
                    StateLayer {
                        radius: Tokens.rounding.small
                        visible: root.datePickMode && dayItem.model.month === grid.month
                        onClicked: {
                            root.dashState.reminderPickedDate = dayItem.model.date.toISOString().slice(0, 10);
                        }
                    }

                    // Click to view reminder details
                    StateLayer {
                        radius: Tokens.rounding.small
                        visible: !root.reminderMode && dayItem.hasReminder && dayItem.model.month === grid.month
                        onClicked: {
                            root.viewingReminderId = ReminderService.reminders.find(
                                r => r.date === dayItem.model.date.toISOString().slice(0, 10)
                            )?.id ?? "";
                        }
                    }
                }
            }

            StyledRect {
                id: todayIndicator

                readonly property Item todayItem: grid.contentItem.children.find(c => c.model.today) ?? null
                property Item today

                onTodayItemChanged: {
                    if (todayItem)
                        today = todayItem;
                }

                x: today ? today.x + (today.width - implicitWidth) / 2 : 0
                y: today?.y ?? 0

                implicitWidth: today?.implicitWidth ?? 0
                implicitHeight: today?.implicitHeight ?? 0

                clip: true
                radius: Tokens.rounding.full
                color: Colours.palette.m3primary

                opacity: todayItem ? 1 : 0
                scale: todayItem ? 1 : 0.7

                Colouriser {
                    x: -todayIndicator.x
                    y: -todayIndicator.y

                    implicitWidth: grid.width
                    implicitHeight: grid.height

                    source: grid
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onPrimary
                }

                Behavior on opacity { Anim {} }
                Behavior on scale { Anim {} }

                Behavior on x {
                    Anim { type: Anim.DefaultSpatial }
                }

                Behavior on y {
                    Anim { type: Anim.DefaultSpatial }
                }
            }
        }
    }

    component SpinGroup: ColumnLayout {
        id: spinGroup

        property int value: 0
        property int min: 0
        property int max: 99
        property string label: ""

        signal valueModified(int v)

        onValueChanged: {
            if (!spinNum.activeFocus)
                spinNum.text = String(value).padStart(2, "0");
        }

        spacing: 2

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: spinGroup.label
            font.pointSize: Tokens.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            color: "transparent"
            radius: Tokens.rounding.small
            implicitWidth: spinBox.implicitWidth
            implicitHeight: spinUp.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onSurface
                onClicked: {
                    const v = Math.min(spinGroup.max, spinGroup.value + 1);
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                    spinNum.text = String(v).padStart(2, "0");
                }
            }

            MaterialIcon {
                id: spinUp
                anchors.centerIn: parent
                text: "keyboard_arrow_up"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal
            }
        }

        StyledRect {
            id: spinBox
            Layout.alignment: Qt.AlignHCenter
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.small
            implicitWidth: spinSz.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: spinSz.implicitHeight + Tokens.padding.small * 2

            StyledText {
                id: spinSz
                visible: false
                text: "00"
                font.pointSize: Tokens.font.size.larger
                font.family: Tokens.font.family.mono
            }

            TextInput {
                id: spinNum
                anchors.centerIn: parent
                width: spinSz.implicitWidth

                Component.onCompleted: text = String(spinGroup.value).padStart(2, "0")
                font.pointSize: Tokens.font.size.larger
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3onSurface
                selectionColor: Colours.palette.m3primary
                selectedTextColor: Colours.palette.m3onPrimary
                horizontalAlignment: TextInput.AlignHCenter
                inputMethodHints: Qt.ImhDigitsOnly
                maximumLength: 2
                selectByMouse: true

                function commit(): void {
                    const v = Math.min(spinGroup.max, Math.max(spinGroup.min, parseInt(text) || 0));
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                    text = String(v).padStart(2, "0");
                }

                onEditingFinished: commit()
                onActiveFocusChanged: {
                    if (activeFocus)
                        selectAll();
                    else
                        commit();
                }
                Keys.onEscapePressed: {
                    text = String(spinGroup.value).padStart(2, "0");
                    focus = false;
                }
            }
        }

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            color: "transparent"
            radius: Tokens.rounding.small
            implicitWidth: spinBox.implicitWidth
            implicitHeight: spinUp.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onSurface
                onClicked: {
                    const v = Math.max(spinGroup.min, spinGroup.value - 1);
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                    spinNum.text = String(v).padStart(2, "0");
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "keyboard_arrow_down"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal
            }
        }
    }
}
