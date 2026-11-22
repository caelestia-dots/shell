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
    readonly property real doneRatio: Todos.totalToday ? Todos.doneToday / Todos.totalToday : 0
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
        implicitWidth: 148
        implicitHeight: Math.max(summaryContent.implicitHeight + Tokens.padding.large * 2, layout.implicitHeight)

        ColumnLayout {
            id: summaryContent

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: `${Todos.doneToday}/${Todos.totalToday}`
                color: Hallownest.soul
                font.family: Hallownest.mono
                font.pointSize: 22
                font.weight: Font.Bold
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Tasks done today")
                color: Hallownest.subtext
                font.pointSize: 8.5
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                implicitWidth: 108
                implicitHeight: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3.5
                    radius: 2
                    color: Qt.alpha(Hallownest.steel, 0.16)

                    Rectangle {
                        id: doneFill

                        width: parent.width * root.doneRatio
                        height: parent.height
                        radius: 2
                        color: Hallownest.unn

                        Behavior on width {
                            Anim {}
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, doneFill.width - 2.5)
                    width: 5
                    height: 5
                    rotation: 45
                    color: Hallownest.unn
                    visible: root.doneRatio > 0
                }
            }

            SummaryAction {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.extraSmall
                icon: "add"
                text: Tr.tr("Add task")
                onClicked: titleField.forceActiveFocus()
            }

            SummaryAction {
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
        anchors.leftMargin: Tokens.spacing.medium
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

                Layout.preferredWidth: 96
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

        Column {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.medium
            visible: Todos.items.length === 0
            spacing: Tokens.spacing.extraSmall

            Mask {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 26
                filled: false
                opacity: 0.4
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Tr.tr("Nothing to do")
                color: Hallownest.faint
                font.family: Hallownest.serif
                font.pointSize: 10
            }
        }

        StyledListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 210)
            visible: count > 0
            clip: true
            spacing: Tokens.spacing.extraSmall

            model: ScriptModel {
                values: Todos.items
                objectProp: "id"
            }

            delegate: Rectangle {
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
                implicitHeight: Math.max(32, row.implicitHeight + 6)
                radius: 10
                color: taskHover.hovered ? Hallownest.raise(Hallownest.card, 1.35) : Hallownest.card
                border.width: 1
                border.color: task.overdue ? Qt.alpha(Hallownest.grimm, 0.35) : Hallownest.border

                Behavior on color {
                    CAnim {}
                }

                HoverHandler {
                    id: taskHover
                }

                RowLayout {
                    id: row

                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.small + 2
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
                        font.pointSize: 9.5
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

                        Layout.preferredWidth: 92
                        visible: task.editing
                        text: Todos.dueStr(task.modelData)
                        placeholderText: Tr.tr("HH:MM")
                        onAccepted: task.save()
                        onActiveFocusChanged: root.pin(activeFocus)
                    }

                    Rectangle {
                        visible: !task.editing && task.modelData.dueAt > 0
                        implicitWidth: dueRow.implicitWidth + 12
                        implicitHeight: 20
                        radius: 10
                        color: task.overdue ? Qt.alpha(Hallownest.grimm, 0.16) : Hallownest.void_

                        Row {
                            id: dueRow

                            anchors.centerIn: parent
                            spacing: 4

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
                                font.family: Hallownest.mono
                                font.pointSize: 8
                            }
                        }
                    }

                    TaskIcon {
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

                    TaskIcon {
                        visible: taskHover.hovered || task.editing
                        icon: task.editing ? "close" : "delete"
                        accent: task.editing ? Hallownest.soul : Hallownest.grimm
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

    component SummaryAction: Rectangle {
        id: action

        property string icon
        property string text
        property bool disabled

        signal clicked

        implicitWidth: actionRow.implicitWidth + 14
        implicitHeight: 24
        radius: 8
        color: actionArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"
        opacity: disabled ? 0.32 : 1

        Behavior on color {
            CAnim {}
        }

        Row {
            id: actionRow

            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: action.icon
                color: actionArea.containsMouse ? Hallownest.soul : Hallownest.steel
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: action.text
                color: actionArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                font.pointSize: 8.5
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: actionArea

            anchors.fill: parent
            enabled: !action.disabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    component TaskIcon: Rectangle {
        id: taskBtn

        property string icon
        property color accent: Hallownest.soul

        signal clicked

        implicitWidth: 24
        implicitHeight: 24
        radius: 12
        color: taskBtnArea.containsMouse ? (accent === Hallownest.soul ? Hallownest.raise(Hallownest.card, 1.65) : Qt.alpha(accent, 0.16)) : "transparent"

        Behavior on color {
            CAnim {}
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: taskBtn.icon
            color: taskBtnArea.containsMouse ? taskBtn.accent : Hallownest.steel
            fontStyle: Tokens.font.icon.small
        }

        MouseArea {
            id: taskBtnArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: taskBtn.clicked()
        }
    }

    component ColourDot: Item {
        id: dot

        required property int colourIndex

        signal cycled

        implicitWidth: 26
        implicitHeight: 26

        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 10
            rotation: 45
            color: root.colours[dot.colourIndex]
            scale: dotArea.containsMouse ? 1.18 : 1

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        MouseArea {
            id: dotArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dot.cycled()
        }
    }
}
