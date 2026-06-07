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
            bottomLeftR: Tokens.rounding.normal
            bottomRightR: Tokens.rounding.normal
            onClicked: root.dashState.timerPanelTab = 1
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

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    SpinGroup {
                        readOnly: TimerService.active
                        max: 23
                        value: TimerService.active
                            ? Math.floor(TimerService.remainingSeconds / 3600)
                            : root.timerHours
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
                        readOnly: TimerService.active
                        max: 59
                        value: TimerService.active
                            ? Math.floor((TimerService.remainingSeconds % 3600) / 60)
                            : root.timerMinutes
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
                        readOnly: TimerService.active
                        max: 59
                        value: TimerService.active
                            ? (TimerService.remainingSeconds % 60)
                            : root.timerSeconds
                        onValueModified: v => root.timerSeconds = v
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    opacity: TimerService.active ? 1 : 0
                    Behavior on opacity { Anim {} }

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
            }

            ActionBtn {
                visible: !TimerService.active
                x: (parent.width - tabCol.width - width) / 2
                width: parent.width - Tokens.sizes.dashboard.dateTimeWidth - Tokens.spacing.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.padding.normal
                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                text: qsTr("Start")
                icon: "play_arrow"
                onClicked: TimerService.start(root.timerHours, root.timerMinutes, root.timerSeconds)
            }

            RowLayout {
                visible: TimerService.active
                x: (parent.width - tabCol.width - width) / 2
                width: parent.width - Tokens.sizes.dashboard.dateTimeWidth - Tokens.spacing.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.padding.normal
                spacing: Tokens.spacing.small

                ActionBtn {
                    Layout.fillWidth: true
                    inactiveColour: Colours.palette.m3secondaryContainer
                    inactiveOnColour: Colours.palette.m3onSecondaryContainer
                    text: TimerService.running ? qsTr("Pause") : qsTr("Resume")
                    icon: TimerService.running ? "pause" : "play_arrow"
                    onClicked: TimerService.running ? TimerService.pause() : TimerService.resume()
                }

                ActionBtn {
                    inactiveColour: Colours.palette.m3errorContainer
                    inactiveOnColour: Colours.palette.m3onErrorContainer
                    text: qsTr("Cancel")
                    icon: "close"
                    onClicked: TimerService.cancel()
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

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    SpinGroup {
                        readOnly: AlarmService.active
                        max: 23
                        value: AlarmService.active ? AlarmService.alarmHour : root.alarmHours
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
                        readOnly: AlarmService.active
                        max: 59
                        value: AlarmService.active ? AlarmService.alarmMinute : root.alarmMinutes
                        onValueModified: v => root.alarmMinutes = v
                    }
                }
            }

            ActionBtn {
                visible: !AlarmService.active
                x: (parent.width - tabCol.width - width) / 2
                width: parent.width - Tokens.sizes.dashboard.dateTimeWidth - Tokens.spacing.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.padding.normal
                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                text: qsTr("Set alarm")
                icon: "alarm"
                onClicked: AlarmService.setAlarm(root.alarmHours, root.alarmMinutes)
            }

            ActionBtn {
                visible: AlarmService.active
                x: (parent.width - tabCol.width - width) / 2
                width: parent.width - Tokens.sizes.dashboard.dateTimeWidth - Tokens.spacing.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.padding.normal
                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer
                text: qsTr("Cancel alarm")
                icon: "close"
                onClicked: AlarmService.cancelAlarm()
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

    component SpinGroup: StyledRect {
        id: spinGroup

        property int value: 0
        property int min: 0
        property int max: 99
        property bool readOnly: false

        signal valueModified(int v)

        onValueChanged: {
            if (!readOnly && !numInput.activeFocus)
                numInput.text = String(value).padStart(2, "0");
        }

        color: readOnly ? "transparent" : Colours.tPalette.m3surfaceContainerHigh
        radius: Tokens.rounding.normal
        implicitWidth: numSizer.implicitWidth + Tokens.padding.large * 2
        implicitHeight: numSizer.implicitHeight + Tokens.padding.large * 2

        Behavior on color { ColorAnimation { duration: 150 } }

        StyledText {
            id: numSizer
            visible: false
            text: "00"
            font.pointSize: Tokens.font.size.extraLarge
            font.family: Tokens.font.family.mono
        }

        MouseArea {
            id: spinMouse
            anchors.fill: parent
            enabled: !spinGroup.readOnly
            hoverEnabled: true
            cursorShape: Qt.SizeVerCursor
            onClicked: numInput.forceActiveFocus()
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) {
                    spinGroup.valueModified(Math.min(spinGroup.max, spinGroup.value + 1));
                } else if (wheel.angleDelta.y < 0) {
                    spinGroup.valueModified(Math.max(spinGroup.min, spinGroup.value - 1));
                }
                wheel.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: spinGroup.radius
            color: Colours.palette.m3onSurface
            opacity: !spinGroup.readOnly && spinMouse.containsMouse ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        TextInput {
            id: numInput
            anchors.centerIn: parent
            width: numSizer.implicitWidth
            visible: !spinGroup.readOnly

            Component.onCompleted: text = String(spinGroup.value).padStart(2, "0")
            font.pointSize: Tokens.font.size.extraLarge
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
                spinGroup.valueModified(v);
                text = String(v).padStart(2, "0");
            }

            onTextEdited: {
                const v = Math.min(spinGroup.max, Math.max(spinGroup.min, parseInt(text) || 0));
                spinGroup.valueModified(v);
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

        StyledText {
            anchors.centerIn: parent
            visible: spinGroup.readOnly
            text: String(spinGroup.value).padStart(2, "0")
            font.pointSize: Tokens.font.size.extraLarge
            font.family: Tokens.font.family.mono
            color: Colours.palette.m3onSurface
            horizontalAlignment: Text.AlignHCenter
        }
    }

    component ActionBtn: IconTextButton {
        verticalPadding: Tokens.padding.small
        radius: stateLayer.pressed
            ? Tokens.rounding.small / 2
            : implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        scale: stateLayer.pressed ? 1.06 : 1.0

        Behavior on radius {
            Anim { type: Anim.FastSpatial }
        }
        Behavior on scale {
            Anim { type: Anim.FastSpatial }
        }
    }
}
