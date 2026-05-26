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

    // Only clickable when panel is closed - opens the timer panel
    StateLayer {
        anchors.fill: parent
        radius: Tokens.rounding.normal
        enabled: !root.dashState.timerPanelOpen
        onClicked: root.dashState.timerPanelOpen = true
    }

    // Clock - visible when panel is closed
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        visible: !root.dashState.timerPanelOpen

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

    // Back button at top-left - visible when panel is open
    StyledRect {
        visible: root.dashState.timerPanelOpen
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Tokens.padding.normal
        anchors.leftMargin: Tokens.padding.normal
        implicitWidth: implicitHeight
        implicitHeight: backIcon.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainerHigh

        StateLayer {
            radius: parent.radius
            onClicked: {
                root.dashState.timerPanelOpen = false;
                root.dashState.timerPanelTab = 0;
                root.dashState.reminderPickedDate = "";
            }
        }

        MaterialIcon {
            id: backIcon
            anchors.centerIn: parent
            text: "arrow_back"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.normal
        }
    }
}
