pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.hallownest
import qs.services

// Events of one day with inline add/edit forms, unfolded over the notch week view
Item {
    id: root

    required property date date
    readonly property list<var> events: Events.eventsOn(date)
    property bool adding
    property string editingUid

    signal close

    function formatDate(date: date): string {
        return Qt.formatDate(date, Events.dateFormat);
    }

    onDateChanged: {
        adding = false;
        editingUid = "";
        Events.loadMonth(date.getFullYear(), date.getMonth(), "window");
    }

    Component.onCompleted: Events.loadMonth(date.getFullYear(), date.getMonth(), "window")

    Keys.onEscapePressed: {
        if (adding || editingUid) {
            adding = false;
            editingUid = "";
        } else {
            close();
        }
    }

    RowLayout {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium + 2
        anchors.bottomMargin: 0
        spacing: Tokens.spacing.small

        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 14
            color: backArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "arrow_back"
                color: backArea.containsMouse ? Hallownest.soul : Hallownest.steel
                fontStyle: Tokens.font.icon.small
            }

            MouseArea {
                id: backArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }

        StyledText {
            Layout.leftMargin: 2
            text: Qt.locale().toString(root.date, "dddd")
            color: Hallownest.soul
            font.family: Hallownest.serif
            font.pointSize: 11.5
            font.weight: Font.Bold
            font.capitalization: Font.Capitalize
        }

        StyledText {
            Layout.fillWidth: true
            text: Qt.locale().toString(root.date, "d MMMM yyyy")
            color: Hallownest.subtext
            font.pointSize: 9.5
            elide: Text.ElideRight
        }

        HkButton {
            visible: !root.adding && !root.editingUid
            disabled: !Events.available
            icon: "add"
            text: Tr.tr("Add event")
            tinted: true
            accent: Hallownest.lifeblood
            onClicked: root.adding = true
        }
    }

    HkDivider {
        id: headerDivider

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.padding.medium + 2
        anchors.rightMargin: Tokens.padding.medium + 2
        anchors.topMargin: Tokens.spacing.small
        opacity: 0.55
    }

    StyledFlickable {
        id: view

        anchors.top: headerDivider.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium + 2
        anchors.topMargin: Tokens.spacing.small

        clip: true
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: content.implicitHeight

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        ColumnLayout {
            id: content

            width: view.width
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                visible: !Events.available
                text: Tr.tr("khal is not installed or configured, so events can't be loaded")
                color: Hallownest.grimm
                font.pointSize: 9
                wrapMode: Text.WordWrap
            }

            Loader {
                Layout.fillWidth: true
                active: root.adding
                visible: active

                sourceComponent: EventForm {}
            }

            Repeater {
                model: root.events

                Loader {
                    id: eventLoader

                    required property var modelData

                    Layout.fillWidth: true
                    sourceComponent: root.editingUid === modelData.uid ? editForm : eventCard

                    Component {
                        id: eventCard

                        EventCard {
                            modelData: eventLoader.modelData
                        }
                    }

                    Component {
                        id: editForm

                        EventForm {
                            event: eventLoader.modelData
                        }
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraLarge * 1.6
                visible: root.events.length === 0 && !root.adding
                spacing: Tokens.spacing.small

                Mask {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: 30
                    filled: false
                    opacity: 0.45
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Tr.tr("No events this day")
                    color: Hallownest.faint
                    font.family: Hallownest.serif
                    font.pointSize: 10.5
                }
            }
        }
    }

    component EventCard: HkCard {
        id: card

        required property var modelData
        property bool confirmDelete
        readonly property color accent: modelData.colour || Hallownest.lifeblood

        Layout.fillWidth: true
        implicitHeight: cardLayout.implicitHeight + 20

        RowLayout {
            id: cardLayout

            anchors.fill: parent
            anchors.margins: 10
            spacing: Tokens.spacing.medium

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 3
                radius: 1.5
                color: card.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: card.modelData.allDay ? Tr.tr("All day") : `${card.modelData.start}–${card.modelData.end}`
                        color: card.accent
                        font.family: Hallownest.mono
                        font.pointSize: 8.5
                        font.weight: Font.DemiBold
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: card.modelData.title
                        color: Hallownest.soul
                        font.pointSize: 9.5
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                Flow {
                    id: infoFlow

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.large

                    InfoRow {
                        icon: "location_on"
                        text: card.modelData.location
                    }

                    InfoRow {
                        icon: "event_repeat"
                        text: card.modelData.recurring ? (card.modelData.until ? Tr.tr("Weekly until %1").arg(root.formatDate(card.modelData.until)) : Tr.tr("Repeats")) : ""
                    }

                    InfoRow {
                        icon: "notes"
                        text: card.modelData.description
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: editArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"
                opacity: !!root.editingUid || root.adding ? 0.35 : 1

                Behavior on color {
                    CAnim {}
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "edit"
                    color: editArea.containsMouse ? Hallownest.soul : Hallownest.steel
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: editArea

                    anchors.fill: parent
                    enabled: !root.editingUid && !root.adding
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.editingUid = card.modelData.uid
                }
            }

            HkButton {
                Layout.alignment: Qt.AlignTop
                icon: card.confirmDelete ? "delete_forever" : "delete"
                text: card.confirmDelete ? Tr.tr("Delete") : ""
                accent: Hallownest.grimm
                tinted: card.confirmDelete
                filled: card.confirmDelete
                onClicked: {
                    if (card.confirmDelete)
                        Events.remove(card.modelData.uid);
                    else
                        card.confirmDelete = true;
                }
            }
        }

        // Reset the delete confirmation if not confirmed shortly
        Timer {
            running: card.confirmDelete
            interval: 3000
            onTriggered: card.confirmDelete = false
        }
    }

    component InfoRow: RowLayout {
        id: info

        property string icon
        property string text

        width: Math.min(implicitWidth, parent?.width ?? implicitWidth)
        visible: !!text
        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            text: info.icon
            color: Hallownest.subtext
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            Layout.fillWidth: true
            text: info.text
            color: Hallownest.subtext
            font.pointSize: 9
            elide: Text.ElideRight
        }
    }

    component EventForm: HkCard {
        id: form

        // Event being edited (null when adding). Edits to a repeating event apply to the whole series.
        property var event: null
        readonly property bool editingSeries: !!event?.recurring
        readonly property string initialUntil: event?.until ? root.formatDate(event.until) : ""

        readonly property var timeRe: /^([01]?\d|2[0-3]):[0-5]\d$/
        readonly property bool showDate: !!event && !editingSeries
        readonly property date eventDate: showDate ? Date.fromLocaleDateString(Qt.locale(), dateField.text.trim(), Events.dateFormat) : root.date
        readonly property bool dateValid: !showDate || !isNaN(eventDate)
        readonly property date untilDate: Date.fromLocaleDateString(Qt.locale(), untilField.text.trim(), Events.dateFormat)
        readonly property bool untilValid: !weekly.checked || !untilField.text.trim() || (!isNaN(untilDate) && (editingSeries || untilDate >= eventDate))
        readonly property bool timesWellFormed: allDay.checked || (timeRe.test(startField.text) && timeRe.test(endField.text))
        readonly property bool timesValid: timesWellFormed && (allDay.checked || endField.text.padStart(5, "0") > startField.text.padStart(5, "0"))
        readonly property bool valid: titleField.text.trim() && timesValid && untilValid && dateValid
        readonly property string message: {
            if (!dateValid)
                return Tr.tr("Enter a valid date");
            if (!timesWellFormed)
                return Tr.tr("Use HH:MM for times");
            if (!timesValid)
                return Tr.tr("End must be after start");
            if (!untilValid)
                return Tr.tr("Enter a date after this day");
            if (editingSeries)
                return Tr.tr("Changes apply to every occurrence");
            return "";
        }

        function close(): void {
            root.adding = false;
            root.editingUid = "";
        }

        function save(): void {
            if (!valid)
                return;

            const data = {
                title: titleField.text.trim(),
                // A series keeps its start day, unless it stops repeating (then it stays on this day)
                date: editingSeries && weekly.checked ? null : eventDate,
                allDay: allDay.checked,
                start: startField.text.padStart(5, "0"),
                end: endField.text.padStart(5, "0"),
                weekly: weekly.checked,
                until: weekly.checked && untilField.text.trim() ? untilDate : null,
                untilChanged: untilField.text.trim() !== initialUntil,
                location: locationField.text.trim(),
                description: descriptionField.text.trim()
            };
            if (event)
                Events.update(event.uid, data);
            else
                Events.add(data);
            close();
        }

        Layout.fillWidth: true
        implicitHeight: formLayout.implicitHeight + 28
        ornate: true

        Component.onCompleted: titleField.forceFocus()

        GridLayout {
            id: formLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            columns: 2
            rowSpacing: Tokens.spacing.small
            columnSpacing: Tokens.spacing.medium

            StyledText {
                Layout.columnSpan: 2
                text: form.event ? Tr.tr("Edit event") : Tr.tr("New event")
                color: Hallownest.soul
                font.family: Hallownest.serif
                font.pointSize: 11
                font.weight: Font.Bold
            }

            Field {
                id: titleField

                Layout.columnSpan: 2
                label: Tr.tr("Title")
                icon: "title"
                text: form.event?.title ?? ""
                onAccepted: form.save()
            }

            SwitchRow {
                id: allDay

                label: Tr.tr("All day")
                checked: form.event?.allDay ?? false
            }

            SwitchRow {
                id: weekly

                label: form.event?.recurring && !/FREQ=WEEKLY/.test(form.event.repeat ?? "") ? Tr.tr("Repeat") : Tr.tr("Repeat weekly")
                checked: form.event?.recurring ?? false
            }

            Field {
                id: startField

                visible: !allDay.checked
                label: Tr.tr("Start")
                icon: "schedule"
                text: form.event && !form.event.allDay ? form.event.start : "09:00"
                error: !form.timesWellFormed || !form.timesValid
                onAccepted: form.save()
            }

            Field {
                id: endField

                visible: !allDay.checked
                label: Tr.tr("End")
                icon: "schedule"
                text: form.event && !form.event.allDay ? form.event.end : "10:00"
                error: !form.timesWellFormed || !form.timesValid
                onAccepted: form.save()
            }

            Field {
                id: dateField

                visible: form.showDate
                label: Tr.tr("Date")
                icon: "event"
                text: root.formatDate(root.date)
                error: !form.dateValid
                onAccepted: form.save()
            }

            Field {
                id: untilField

                visible: weekly.checked
                label: {
                    const count = /COUNT=(\d+)/.exec(form.event?.repeat ?? "");
                    if (count && !text.trim())
                        return Tr.tr("Until (now ends after %1 occurrences)").arg(count[1]);
                    return Tr.tr("Until (optional, e.g. %1)").arg(root.formatDate(new Date(root.date.getFullYear(), root.date.getMonth() + 1, root.date.getDate())));
                }
                icon: "event_busy"
                text: form.initialUntil
                error: !form.untilValid
                onAccepted: form.save()
            }

            Field {
                id: locationField

                label: Tr.tr("Location (optional)")
                icon: "location_on"
                text: form.event?.location ?? ""
                onAccepted: form.save()
            }

            Field {
                id: descriptionField

                label: Tr.tr("Notes (optional)")
                icon: "notes"
                text: form.event?.description ?? ""
                onAccepted: form.save()
            }

            RowLayout {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: form.message
                    color: form.editingSeries && form.valid ? Hallownest.subtext : Hallownest.grimm
                    font.pointSize: 9
                    wrapMode: Text.WordWrap
                }

                HkButton {
                    text: Tr.trCtx("Cancel", "button")
                    onClicked: form.close()
                }

                HkButton {
                    icon: "check"
                    text: Tr.trCtx("Save", "button")
                    filled: true
                    disabled: !form.valid
                    onClicked: form.save()
                }
            }
        }
    }

    component Field: ColumnLayout {
        id: field

        property alias label: fieldLabel.text
        property alias text: input.text
        property alias icon: input.leadingIcon
        property bool error

        signal accepted

        function forceFocus(): void {
            input.forceActiveFocus();
        }

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 3

        StyledText {
            id: fieldLabel

            Layout.leftMargin: 6
            color: field.error ? Hallownest.grimm : Hallownest.subtext
            font.pointSize: 8
        }

        HkField {
            id: input

            Layout.fillWidth: true
            onAccepted: field.accepted()
        }
    }

    component SwitchRow: RowLayout {
        id: switchRow

        property alias label: switchLabel.text
        property bool checked

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: Tokens.spacing.medium

        StyledText {
            id: switchLabel

            Layout.fillWidth: true
            Layout.leftMargin: 6
            color: Hallownest.text
            font.pointSize: 10
        }

        HkSwitch {
            checked: switchRow.checked
            onToggled: c => switchRow.checked = c
        }
    }
}
