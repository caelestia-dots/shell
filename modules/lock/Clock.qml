import qs.widgets
import qs.services
import qs.config
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: 0

    readonly property bool use12HourFormat: Config.services.useTwelveHourClock
    readonly property string timeFormat: use12HourFormat ? "hh:mm:A" : "hh:mm"
    readonly property list<string> timeComponents: Time.format(timeFormat).split(":")

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
            text: root.timeComponents[1] + (root.timeComponents[2] || "")
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge * 4
            font.family: Appearance.font.family.mono
            font.weight: 800
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
