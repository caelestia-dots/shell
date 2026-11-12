pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.notch

NotchPage {
    id: root

    readonly property list<color> colours: [Hallownest.grimm, Hallownest.gold, Hallownest.unn, Hallownest.crystal, Hallownest.steel]
    property int newColour

    function pin(focused: bool): void {
        if (focused)
            screenState.notch = true;
    }

    function submit(): void {
        Todos.add(titleField.text, newColour, dueField.text);
        titleField.text = "";
        dueField.text = "";
    }

    implicitWidth: 580
    implicitHeight: Math.max(summary.implicitHeight, layout.implicitHeight)

    HkCard {
        id: summary

        anchors.left: parent.left
        anchors.top: parent.top
        implicitWidth: 150
        implicitHeight: Math.max(summaryContent.implicitHeight + Tokens.padding.extraLarge * 2, layout.implicitHeight)
        ornate: true

        ColumnLayout {
            id: summaryContent

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: `${Todos.doneToday}/${Todos.totalToday}`
                color: Hallownest.soul
                font.family: Hallownest.serif
                font.pointSize: 26
                font.weight: Font.Bold
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Tasks done today")
                color: Hallownest.subtext
                font.pointSize: 9
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.extraSmall
                implicitWidth: 110
                implicitHeight: 4
                radius: 2
                color: Qt.alpha(Hallownest.steel, 0.18)

                Rectangle {
                    implicitWidth: parent.width * (Todos.totalToday ? Todos.doneToday / Todos.totalToday : 0)
                    implicitHeight: parent.height
                    radius: 2
                    color: Hallownest.unn

                    Behavior on implicitWidth {
                        Anim {}
                    }
                }
            }

            HkButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.small
                icon: "add"
                text: Tr.tr("Add task")
                onClicked: titleField.forceActiveFocus()
            }

            HkButton {
                Layout.alignment: Qt.AlignHCenter
                icon: "done_all"
                text: Tr.tr("Clear done")
                disabled: !Todos.items.some(i => i.done)
                onClicked: Todos.clearDone()
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: summary.right
        anchors.leftMargin: Tokens.spacing.large
        anchors.right: parent.right
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ColourDot {
                colourIndex: root.newColour
                onCycled: root.newColour = (root.newColour + 1) % root.colours.length
            }

            HkField {
                id: titleField

                Layout.fillWidth: true
                placeholderText: Tr.tr("New task")
                onAccepted: root.submit()
                onActiveFocusChanged: root.pin(activeFocus)
            }

            HkField {
                id: dueField

                Layout.preferredWidth: 100
                placeholderText: Tr.tr("HH:MM")
                leadingIcon: "schedule"
                onAccepted: root.submit()
                onActiveFocusChanged: root.pin(activeFocus)
            }

            HkButton {
                icon: "add"
                filled: true
                disabled: !titleField.text.trim()
                onClicked: root.submit()
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.small
            Layout.bottomMargin: Tokens.spacing.small
            visible: Todos.items.length === 0
            text: Tr.tr("Nothing to do")
            color: Hallownest.subtext
            font.family: Hallownest.serif
            font.pointSize: 10
        }

        StyledListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 220)
            visible: count > 0
            clip: true
            spacing: Tokens.spacing.extraSmall

            model: ScriptModel {
                values: Todos.items
                objectProp: "id"
            }

            delegate: StyledRect {
                id: task

                required property var modelData
                property bool editing
                property int editColour: modelData.colour ?? 0
                readonly property bool overdue: !modelData.done && modelData.dueAt > 0 && modelData.dueAt < Date.now()

                function save(): void {
                    Todos.edit(modelData.id, editTitle.text, editColour, editDue.text);
                    editing = false;
                }

                width: list.width
                implicitHeight: Math.max(30, row.implicitHeight + 4)
                radius: implicitHeight / 2
                color: taskHover.hovered ? Hallownest.raise(Hallownest.card, 1.3) : Hallownest.card
                border.width: 1
                border.color: Hallownest.border

                HoverHandler {
                    id: taskHover
                }

                RowLayout {
                    id: row

                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.small
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    HkCheck {
                        visible: !task.editing
                        checked: task.modelData.done
                        colour: root.colours[task.modelData.colour ?? 0]
                        onClicked: Todos.toggle(task.modelData.id)
                    }

                    ColourDot {
                        visible: task.editing
                        colourIndex: task.editColour
                        onCycled: task.editColour = (task.editColour + 1) % root.colours.length
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !task.editing
                        text: task.modelData.title
                        color: task.modelData.done ? Hallownest.faint : Hallownest.text
                        font.pointSize: 10
                        font.strikeout: task.modelData.done
                        elide: Text.ElideRight
                    }

                    HkField {
                        id: editTitle

                        Layout.fillWidth: true
                        visible: task.editing
                        text: task.modelData.title
                        onAccepted: task.save()
                        onActiveFocusChanged: root.pin(activeFocus)
                    }

                    HkField {
                        id: editDue

                        Layout.preferredWidth: 100
                        visible: task.editing
                        text: Todos.dueStr(task.modelData)
                        placeholderText: Tr.tr("HH:MM")
                        onAccepted: task.save()
                        onActiveFocusChanged: root.pin(activeFocus)
                    }

                    StyledRect {
                        visible: !task.editing && task.modelData.dueAt > 0
                        implicitWidth: dueRow.implicitWidth + Tokens.padding.small * 2
                        implicitHeight: dueRow.implicitHeight + Tokens.padding.extraSmall * 2
                        radius: Tokens.rounding.full
                        color: task.overdue ? Qt.alpha(Hallownest.grimm, 0.2) : Hallownest.button

                        Row {
                            id: dueRow

                            anchors.centerIn: parent
                            spacing: Tokens.spacing.extraSmall

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "schedule"
                                color: task.overdue ? Hallownest.grimm : Hallownest.subtext
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Todos.dueStr(task.modelData)
                                color: task.overdue ? Hallownest.grimm : Hallownest.subtext
                                font: Tokens.font.label.medium
                            }
                        }
                    }

                    HkButton {
                        implicitHeight: 22
                        visible: taskHover.hovered || task.editing
                        icon: task.editing ? "check" : "edit"
                        onClicked: {
                            if (task.editing) {
                                task.save();
                            } else {
                                task.editColour = task.modelData.colour ?? 0;
                                task.editing = true;
                                editTitle.forceActiveFocus();
                            }
                        }
                    }

                    HkButton {
                        implicitHeight: 22
                        visible: taskHover.hovered || task.editing
                        icon: task.editing ? "close" : "delete"
                        onClicked: {
                            if (task.editing)
                                task.editing = false;
                            else
                                Todos.remove(task.modelData.id);
                        }
                    }
                }
            }
        }
    }

    component ColourDot: Item {
        id: dot

        required property int colourIndex

        signal cycled

        implicitWidth: 28
        implicitHeight: 28

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 16
            implicitHeight: 16
            radius: Tokens.rounding.full
            color: root.colours[dot.colourIndex]
        }

        StateLayer {
            radius: Tokens.rounding.full
            onClicked: dot.cycled()
        }
    }
}
