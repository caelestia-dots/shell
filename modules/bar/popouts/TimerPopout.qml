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

    required property PopoutState popouts

    property int popoutTab: 0

    property int timerHours: 0
    property int timerMinutes: 0
    property int timerSeconds: 0

    property int alarmHours: AlarmService.alarmHour
    property int alarmMinutes: AlarmService.alarmMinute

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        // Tab row
        RowLayout {
            Layout.topMargin: Tokens.padding.small
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.smaller

            component TabChip: StyledRect {
                id: chip

                property bool chipActive: false
                property string chipText: ""
                property string chipIcon: ""
                signal clicked()

                implicitWidth: chipRow.implicitWidth + Tokens.padding.normal * 2
                implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2

                color: chipActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh
                radius: Tokens.rounding.full

                StateLayer {
                    radius: parent.radius
                    onClicked: chip.clicked()
                }

                RowLayout {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.smaller

                    MaterialIcon {
                        text: chip.chipIcon
                        font.pointSize: Tokens.font.size.small
                        color: chip.chipActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        id: chipLabel
                        text: chip.chipText
                        font.pointSize: Tokens.font.size.small
                        color: chip.chipActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            TabChip {
                chipText: qsTr("Timer")
                chipIcon: "timer"
                chipActive: root.popoutTab === 0
                onClicked: root.popoutTab = 0
            }

            TabChip {
                chipText: qsTr("Alarm")
                chipIcon: "alarm"
                chipActive: root.popoutTab === 1
                onClicked: root.popoutTab = 1
            }
        }

        StackLayout {
            currentIndex: root.popoutTab

            // --- Timer tab ---
            ColumnLayout {
                spacing: Tokens.spacing.small

                Item { Layout.fillHeight: true }

                // Timer done: Bongo Cat
                ColumnLayout {
                    visible: TimerService.timerDone
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    AnimatedImage {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 140

                        source: Paths.absolutePath(GlobalConfig.paths.mediaGif)
                        speed: 2.0
                        playing: TimerService.timerDone
                        fillMode: AnimatedImage.PreserveAspectFit
                        asynchronous: true
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.small
                        Layout.alignment: Qt.AlignHCenter
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        verticalPadding: Tokens.padding.small
                        text: qsTr("Dismiss")
                        icon: "close"
                        onClicked: {
                            TimerService.timerDone = false;
                        }
                    }
                }

                // Idle: set timer
                ColumnLayout {
                    visible: !TimerService.active && !TimerService.timerDone
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Tokens.spacing.small

                        SpinGroup {
                            label: qsTr("H")
                            max: 23
                            value: root.timerHours
                            onValueModified: v => {
                                root.timerHours = v;
                            }
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
                            onValueModified: v => {
                                root.timerMinutes = v;
                            }
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
                            onValueModified: v => {
                                root.timerSeconds = v;
                            }
                        }
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.small
                        Layout.alignment: Qt.AlignHCenter
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        verticalPadding: Tokens.padding.small
                        text: qsTr("Start")
                        icon: "play_arrow"
                        onClicked: TimerService.start(root.timerHours, root.timerMinutes, root.timerSeconds)
                    }
                }

                // Active: running/paused
                ColumnLayout {
                    visible: TimerService.active && !TimerService.timerDone
                    Layout.fillWidth: true
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
                        Layout.alignment: Qt.AlignHCenter
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

                            Behavior on width {
                                Anim {}
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Tokens.spacing.small
                        spacing: Tokens.spacing.small

                        IconTextButton {
                            Layout.fillWidth: true
                            inactiveColour: Colours.palette.m3secondaryContainer
                            inactiveOnColour: Colours.palette.m3onSecondaryContainer
                            verticalPadding: Tokens.padding.small
                            text: TimerService.running ? qsTr("Pause") : qsTr("Resume")
                            icon: TimerService.running ? "pause" : "play_arrow"
                            onClicked: {
                                if (TimerService.running)
                                    TimerService.pause();
                                else
                                    TimerService.resume();
                            }
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

                Item { Layout.fillHeight: true }
            }

            // --- Alarm tab ---
            ColumnLayout {
                spacing: Tokens.spacing.small

                Item { Layout.fillHeight: true }

                // Active alarm indicator
                ColumnLayout {
                    visible: AlarmService.active
                    Layout.fillWidth: true
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
                        Layout.alignment: Qt.AlignHCenter
                        inactiveColour: Colours.palette.m3errorContainer
                        inactiveOnColour: Colours.palette.m3onErrorContainer
                        verticalPadding: Tokens.padding.small
                        text: qsTr("Cancel alarm")
                        icon: "close"
                        onClicked: AlarmService.cancelAlarm()
                    }
                }

                // Set alarm
                ColumnLayout {
                    visible: !AlarmService.active
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Tokens.spacing.small

                        SpinGroup {
                            label: qsTr("H")
                            max: 23
                            value: root.alarmHours
                            onValueModified: v => {
                                root.alarmHours = v;
                            }
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
                            onValueModified: v => {
                                root.alarmMinutes = v;
                            }
                        }
                    }

                    IconTextButton {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.small
                        Layout.alignment: Qt.AlignHCenter
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        verticalPadding: Tokens.padding.small
                        text: qsTr("Set alarm")
                        icon: "alarm"
                        onClicked: AlarmService.setAlarm(root.alarmHours, root.alarmMinutes)
                    }
                }

                Item { Layout.fillHeight: true }
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
            implicitHeight: arrowIcon.implicitHeight + Tokens.padding.small * 2

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
                id: arrowIcon
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
            implicitWidth: numText.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: numText.implicitHeight + Tokens.padding.small * 2

            StyledText {
                id: numText
                visible: false
                text: "00"
                font.pointSize: Tokens.font.size.larger
                font.family: Tokens.font.family.mono
            }

            TextInput {
                id: numInput
                anchors.centerIn: parent
                width: numText.implicitWidth

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
            implicitHeight: arrowIcon.implicitHeight + Tokens.padding.small * 2

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
