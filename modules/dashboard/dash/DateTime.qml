pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Tokens.sizes.dashboard.dateTimeWidth

    required property DashboardState dashState

    // Vertical tabs above the clock - only when timer panel is open
    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: Tokens.padding.normal
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.smaller
        visible: root.dashState.timerPanelOpen

        component TabChip: StyledRect {
            id: chip

            property bool chipActive: false
            property string chipText: ""
            signal clicked()

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: chipLabel.implicitWidth + Tokens.padding.small * 4
            implicitHeight: chipLabel.implicitHeight + Tokens.padding.small

            color: chipActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.full

            StateLayer {
                radius: parent.radius
                onClicked: chip.clicked()
            }

            StyledText {
                id: chipLabel
                anchors.centerIn: parent
                text: chip.chipText
                font.pointSize: Tokens.font.size.small
                color: chip.chipActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            }
        }

        TabChip {
            chipText: qsTr("Timer")
            chipActive: root.dashState.timerPanelTab === 0
            onClicked: root.dashState.timerPanelTab = 0
        }

        TabChip {
            chipText: qsTr("Alarm")
            chipActive: root.dashState.timerPanelTab === 1
            onClicked: root.dashState.timerPanelTab = 1
        }

        TabChip {
            chipText: qsTr("Reminder")
            chipActive: root.dashState.timerPanelTab === 2
            onClicked: root.dashState.timerPanelTab = 2
        }
    }

    // Clock centered in the block
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        StyledText {
            Layout.bottomMargin: -(font.pointSize * 0.4)
            Layout.alignment: Qt.AlignHCenter
            text: Time.hourStr
            color: Colours.palette.m3secondary
            font.pointSize: Tokens.font.size.extraLarge
            font.family: Tokens.font.family.clock
            font.weight: 600
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "•••"
            color: Colours.palette.m3primary
            font.pointSize: Tokens.font.size.extraLarge * 0.9
            font.family: Tokens.font.family.clock
        }

        StyledText {
            Layout.topMargin: -(font.pointSize * 0.4)
            Layout.alignment: Qt.AlignHCenter
            text: Time.minuteStr
            color: Colours.palette.m3secondary
            font.pointSize: Tokens.font.size.extraLarge
            font.family: Tokens.font.family.clock
            font.weight: 600
        }

        Loader {
            asynchronous: true
            Layout.alignment: Qt.AlignHCenter

            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr
                color: Colours.palette.m3primary
                font.pointSize: Tokens.font.size.large
                font.family: Tokens.font.family.clock
                font.weight: 600
            }
        }
    }

    // Button at bottom: alarm_add or arrow_back
    StyledRect {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.large * 2
        implicitWidth: implicitHeight
        implicitHeight: actionIcon.implicitHeight + Tokens.padding.normal * 2
        radius: Tokens.rounding.full
        color: "#e464d6"

        StateLayer {
            radius: parent.radius
            onClicked: {
                if (root.dashState.timerPanelOpen) {
                    root.dashState.timerPanelOpen = false;
                    root.dashState.timerPanelTab = 0;
                    root.dashState.reminderPickedDate = "";
                } else {
                    root.dashState.timerPanelOpen = true;
                }
            }
        }

        MaterialIcon {
            id: actionIcon
            anchors.centerIn: parent
            text: root.dashState.timerPanelOpen ? "arrow_back" : "alarm_add"
            color: Colours.palette.m3onPrimary
            font.pointSize: Tokens.font.size.normal
        }
    }
}
