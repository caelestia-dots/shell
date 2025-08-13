pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")

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
            text: root.timeComponents[0]
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge
            font.family: Appearance.font.family.clock
            font.weight: 600
        }

        StyledText {
            Layout.topMargin: -(font.pointSize * 0.1)
            Layout.alignment: Qt.AlignHCenter
            text: "•••"
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.extraLarge * 0.9
            font.family: Appearance.font.family.clock
        }

        StyledText {
            Layout.topMargin: -(font.pointSize * 0.4)
            Layout.alignment: Qt.AlignHCenter
            text: root.timeComponents[1]
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge
            font.family: Appearance.font.family.clock
            font.weight: 600
        }

        Loader {
            Layout.alignment: Qt.AlignHCenter

            asynchronous: true
            active: Config.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: root.timeComponents[2] ?? ""
                color: Colours.palette.m3secondary
                font.pointSize: Appearance.font.size.large
                font.family: Appearance.font.family.clock
                font.weight: 600
            }
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.normal
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Time.format("ddd, d")
            color: Colours.palette.m3tertiary
            font.pointSize: Appearance.font.size.normal
            font.family: Appearance.font.family.clock
            font.weight: 500
            elide: Text.ElideRight
        }
    }
}
