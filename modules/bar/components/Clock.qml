import qs.widgets
import qs.services
import qs.config
import QtQuick

Column {
    id: root

    property color colour: Colours.palette.m3tertiary

    spacing: Appearance.spacing.small

    MaterialIcon {
        id: icon

        text: "calendar_month"
        color: root.colour

        anchors.horizontalCenter: parent.horizontalCenter
    }

    StyledText {
        id: text

        anchors.horizontalCenter: parent.horizontalCenter

        horizontalAlignment: StyledText.AlignHCenter
        text: Time.format(Config.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm")
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        color: root.colour
    }
}
