pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property string timeFormat12: Config.dashboard.showClockSeconds ? "hh:mm:ss:A" : "hh:mm:A"
    readonly property string timeFormat24: Config.dashboard.showClockSeconds ? "hh:mm:ss" : "hh:mm"
    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? timeFormat12 : timeFormat24).split(":")

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Config.dashboard.sizes.dateTimeWidth

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
            font.pointSize: Appearance.font.size.extraLarge
            font.family: Appearance.font.family.clock
            font.weight: 600
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "•••"
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.extraLarge * 0.9
            font.family: Appearance.font.family.clock
        }

        StyledText {
            Layout.topMargin: -(font.pointSize * 0.4)
            Layout.alignment: Qt.AlignHCenter
            text: Time.minuteStr
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge
            font.family: Appearance.font.family.clock
            font.weight: 600
        }

        Loader {
            Layout.alignment: Qt.AlignHCenter

            active: Config.dashboard.showClockSeconds
            visible: active

            sourceComponent: StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "•••"
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.extraLarge * 0.9
                font.family: Appearance.font.family.clock
            }
        }

        Loader {
            Layout.alignment: Qt.AlignHCenter

            active: Config.dashboard.showClockSeconds
            visible: active

            sourceComponent: StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.timeComponents[2]
                color: Colours.palette.m3secondary
                font.pointSize: Appearance.font.size.extraLarge
                font.family: Appearance.font.family.clock
                font.weight: 600
            }
        }

        Loader {
            Layout.alignment: Qt.AlignHCenter

            active: Config.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Config.dashboard.showClockSeconds ? root.timeComponents[3] : Time.amPmStr ?? ""
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.large
                font.family: Appearance.font.family.clock
                font.weight: 600
            }
        }
    }
}
