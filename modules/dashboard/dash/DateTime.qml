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
}
