import qs.widgets
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Config.dashboard.sizes.dateTimeWidth

    readonly property bool use12HourFormat: Config.services.useTwelveHourClock
    readonly property string timeFormat: use12HourFormat ? "hh:mm:A" : "hh:mm"
    readonly property list<string> timeComponents: Time.format(timeFormat).split(":")

    Column {
        id: timeColumn
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        Item {
            id: timeDisplay
            width: root.width
            height: childrenRect.height

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: -(Appearance.font.size.extraLarge * 0.5)

                StyledText {
                    id: hoursText
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.timeComponents[0]
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                }

                StyledText {
                    id: separator
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: "•••"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.extraLarge * 0.9
                }

                StyledText {
                    id: minutesText
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.timeComponents[1]
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                }

                StyledText {
                    id: amPmText
                    visible: root.use12HourFormat
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.timeComponents[2]
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                }
            }
        }

        StyledText {
            id: dateDisplay
            width: root.width
            horizontalAlignment: Text.AlignHCenter
            text: Time.format("ddd, d")
            color: Colours.palette.m3tertiary
            font.pointSize: Appearance.font.size.normal
            font.weight: 500
        }
    }
}
