import qs.widgets
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: 0

    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeComponents[0]
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge * 4
            font.family: Appearance.font.family.mono
            font.weight: 800
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: ":"
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.extraLarge * 4
            font.family: Appearance.font.family.mono
            font.weight: 800
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeComponents[1]
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge * 4
            font.family: Appearance.font.family.mono
            font.weight: 800
        }

        StyledText {
            visible: Config.services.useTwelveHourClock
            Layout.leftMargin: Appearance.spacing.normal
            Layout.alignment: Qt.AlignVCenter

            text: root.timeComponents[2]
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.extraLarge * 3
            font.weight: 700
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: Appearance.padding.large * 3

        text: Time.format("dddd, d MMMM yyyy")
        color: Colours.palette.m3tertiary
        font.pointSize: Appearance.font.size.extraLarge
        font.family: Appearance.font.family.mono
        font.bold: true
    }
}
