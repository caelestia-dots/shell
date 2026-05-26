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

    // Tab column: square buttons (width = each button's height = total height / 3)
    ColumnLayout {
        id: tabCol
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: height / 3 * 0.8
        spacing: 0
        z: 1

        TabBtn {
            btnIcon: "timer"
            btnText: qsTr("Timer")
            btnActive: root.dashState.timerPanelTab === 0
            topLeftR: Tokens.rounding.normal
            topRightR: Tokens.rounding.normal
            onClicked: root.dashState.timerPanelTab = 0
        }

        TabBtn {
            btnIcon: "alarm"
            btnText: qsTr("Alarm")
            btnActive: root.dashState.timerPanelTab === 1
            onClicked: root.dashState.timerPanelTab = 1
        }

        TabBtn {
            btnIcon: "calendar_month"
            btnText: qsTr("Reminder")
            btnActive: root.dashState.timerPanelTab === 2
            bottomLeftR: Tokens.rounding.normal
            bottomRightR: Tokens.rounding.normal
            onClicked: root.dashState.timerPanelTab = 2
        }
    }

    // Content with vertical slide animation between tabs
    Item {
        anchors.fill: parent
        anchors.margins: Tokens.padding.normal
        clip: true

        // Tab 0: Timer
        Item {
            y: (0 - root.dashState.timerPanelTab) * parent.height
            width: parent.width
            height: parent.height
            Behavior on y { Anim { type: Anim.DefaultSpatial } }

            BackBtn { dashState: root.dashState }

            ColumnLayout {
                anchors.verticalCenter: parent.verticalCenter
                x: (parent.width - tabCol.width - width) / 2
                width: parent.width - Tokens.sizes.dashboard.dateTimeWidth - Tokens.spacing.normal
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
            y: (1 - root.dashState.timerPanelTab) * parent.height
            width: parent.width
            height: parent.height
            Behavior on y { Anim { type: Anim.DefaultSpatial } }

            BackBtn { dashState: root.dashState }

            ColumnLayout {
                anchors.verticalCenter: parent.verticalCenter
                x: (parent.width - tabCol.width - width) / 2
                width: parent.width - Tokens.sizes.dashboard.dateTimeWidth - Tokens.spacing.normal
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

        // Tab 2: Calendar centered with limited width
        Item {
            y: (2 - root.dashState.timerPanelTab) * parent.height
            width: parent.width
            height: parent.height
            clip: true
            Behavior on y { Anim { type: Anim.DefaultSpatial } }

            BackBtn { dashState: root.dashState }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                x: (parent.width - tabCol.width - width) / 2
                width: parent.width - Tokens.sizes.dashboard.dateTimeWidth - Tokens.spacing.normal
                height: parent.height

                Calendar {
                    anchors.fill: parent
                    dashState: root.dashState
                }
            }
        }
    }

    component TabBtn: StyledRect {
        id: btn

        property bool btnActive: false
        property string btnIcon: ""
        property string btnText: ""
        property real topLeftR: 0
        property real topRightR: 0
        property real bottomLeftR: 0
        property real bottomRightR: 0

        signal clicked()

        Layout.fillHeight: true
        Layout.fillWidth: true

        radius: 0
        topLeftRadius: topLeftR
        topRightRadius: topRightR
        bottomLeftRadius: bottomLeftR
        bottomRightRadius: bottomRightR

        color: btnActive
            ? Colours.palette.m3primaryContainer
            : Colours.tPalette.m3surfaceContainerHigh

        Rectangle {
            anchors.fill: parent
            radius: 0
            topLeftRadius: btn.topLeftR
            topRightRadius: btn.topRightR
            bottomLeftRadius: btn.bottomLeftR
            bottomRightRadius: btn.bottomRightR
            color: Colours.palette.m3onSurface
            opacity: btnMouse.containsPress ? 0.15 : btnMouse.containsMouse ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: btn.clicked()
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.smaller

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: btn.btnIcon
                font.pointSize: Tokens.font.size.normal
                color: btn.btnActive
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: btn.btnText
                font.pointSize: Tokens.font.size.small
                color: btn.btnActive
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component BackBtn: StyledRect {
        required property DashboardState dashState

        implicitWidth: implicitHeight
        implicitHeight: _backIcon.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainerHigh

        StateLayer {
            radius: parent.radius
            onClicked: {
                dashState.timerPanelOpen = false;
                dashState.timerPanelTab = 0;
                dashState.reminderPickedDate = "";
            }
        }

        MaterialIcon {
            id: _backIcon
            anchors.centerIn: parent
            text: "arrow_back"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.normal
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
