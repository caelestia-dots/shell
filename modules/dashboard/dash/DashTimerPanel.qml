pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property DashboardState dashState

    property int timerHours: 0
    property int timerMinutes: 0
    property int timerSeconds: 0

    property int alarmHours: AlarmService.alarmHour
    property int alarmMinutes: AlarmService.alarmMinute

    StackLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.normal
        currentIndex: root.dashState.timerPanelTab

        // Tab 0: Timer
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: Tokens.spacing.small

                ColumnLayout {
                    visible: TimerService.timerDone
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Your time is up!")
                        font.pointSize: Tokens.font.size.large
                        font.weight: 600
                        color: Colours.palette.m3onSurface
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        verticalPadding: Tokens.padding.small
                        text: qsTr("Dismiss")
                        icon: "close"
                        onClicked: TimerService.timerDone = false
                    }
                }

                ColumnLayout {
                    visible: !TimerService.active && !TimerService.timerDone
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Tokens.spacing.small

                        SpinGroup {
                            label: qsTr("H")
                            max: 23
                            value: root.timerHours
                            onValueModified: v => root.timerHours = v
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
                            value: root.timerMinutes
                            onValueModified: v => root.timerMinutes = v
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignVCenter
                            text: ":"
                            font.pointSize: Tokens.font.size.larger
                            font.family: Tokens.font.family.mono
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        SpinGroup {
                            label: qsTr("S")
                            max: 59
                            value: root.timerSeconds
                            onValueModified: v => root.timerSeconds = v
                        }
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        verticalPadding: Tokens.padding.small
                        text: qsTr("Start")
                        icon: "play_arrow"
                        onClicked: TimerService.start(root.timerHours, root.timerMinutes, root.timerSeconds)
                    }
                }

                ColumnLayout {
                    visible: TimerService.active && !TimerService.timerDone
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: TimerService.remainingFormatted
                        font.pointSize: Tokens.font.size.extraLarge
                        font.family: Tokens.font.family.mono
                        font.weight: 500
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 4

                        StyledRect {
                            width: parent.width
                            height: parent.height
                            radius: 2
                            color: Colours.tPalette.m3surfaceContainerHigh
                        }

                        StyledRect {
                            width: Math.max(radius * 2, TimerService.progress * parent.width)
                            height: parent.height
                            radius: 2
                            color: Colours.palette.m3primary
                            Behavior on width { Anim {} }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        IconTextButton {
                            Layout.fillWidth: true
                            inactiveColour: Colours.palette.m3secondaryContainer
                            inactiveOnColour: Colours.palette.m3onSecondaryContainer
                            verticalPadding: Tokens.padding.small
                            text: TimerService.running ? qsTr("Pause") : qsTr("Resume")
                            icon: TimerService.running ? "pause" : "play_arrow"
                            onClicked: TimerService.running ? TimerService.pause() : TimerService.resume()
                        }

                        IconTextButton {
                            inactiveColour: Colours.palette.m3errorContainer
                            inactiveOnColour: Colours.palette.m3onErrorContainer
                            verticalPadding: Tokens.padding.small
                            text: qsTr("Cancel")
                            icon: "close"
                            onClicked: TimerService.cancel()
                        }
                    }
                }
            }
        }

        // Tab 1: Alarm
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: Tokens.spacing.small

                ColumnLayout {
                    visible: AlarmService.active
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: AlarmService.alarmTimeFormatted
                        font.pointSize: Tokens.font.size.extraLarge
                        font.family: Tokens.font.family.mono
                        font.weight: 500
                        color: Colours.palette.m3primary
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        inactiveColour: Colours.palette.m3errorContainer
                        inactiveOnColour: Colours.palette.m3onErrorContainer
                        verticalPadding: Tokens.padding.small
                        text: qsTr("Cancel alarm")
                        icon: "close"
                        onClicked: AlarmService.cancelAlarm()
                    }
                }

                ColumnLayout {
                    visible: !AlarmService.active
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Tokens.spacing.small

                        SpinGroup {
                            label: qsTr("H")
                            max: 23
                            value: root.alarmHours
                            onValueModified: v => root.alarmHours = v
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
                            value: root.alarmMinutes
                            onValueModified: v => root.alarmMinutes = v
                        }
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        verticalPadding: Tokens.padding.small
                        text: qsTr("Set alarm")
                        icon: "alarm"
                        onClicked: AlarmService.setAlarm(root.alarmHours, root.alarmMinutes)
                    }
                }
            }
        }

        // Tab 2: Reminder - embedded calendar
        Item {
            clip: true
            Calendar {
                anchors.fill: parent
                dashState: root.dashState
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
            if (!numInput.activeFocus)
                numInput.text = String(value).padStart(2, "0");
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
            implicitWidth: numBox.implicitWidth
            implicitHeight: upArrow.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onSurface
                onClicked: {
                    const v = Math.min(spinGroup.max, spinGroup.value + 1);
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                    numInput.text = String(v).padStart(2, "0");
                }
            }

            MaterialIcon {
                id: upArrow
                anchors.centerIn: parent
                text: "keyboard_arrow_up"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal
            }
        }

        StyledRect {
            id: numBox
            Layout.alignment: Qt.AlignHCenter
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.small
            implicitWidth: numSizer.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: numSizer.implicitHeight + Tokens.padding.small * 2

            StyledText {
                id: numSizer
                visible: false
                text: "00"
                font.pointSize: Tokens.font.size.larger
                font.family: Tokens.font.family.mono
            }

            TextInput {
                id: numInput
                anchors.centerIn: parent
                width: numSizer.implicitWidth

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
            implicitWidth: numBox.implicitWidth
            implicitHeight: upArrow.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onSurface
                onClicked: {
                    const v = Math.max(spinGroup.min, spinGroup.value - 1);
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                    numInput.text = String(v).padStart(2, "0");
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
