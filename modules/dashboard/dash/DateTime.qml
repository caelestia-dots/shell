import qs.widgets
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Config.dashboard.sizes.dateTimeWidth

    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")

    ColumnLayout {
        id: timeColumn

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        Item {
            id: timeDisplay

            width: root.width
            height: childrenRect.height

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: -(Appearance.font.size.extraLarge * 0.5)

                StyledText {
                    id: hoursText

                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.timeComponents[0]
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                }

                StyledText {
                    id: separator

                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: "•••"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.extraLarge * 0.9
                }

                StyledText {
                    id: minutesText

                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.timeComponents[1]
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                }

                StyledText {
                    id: amPmText

                    visible: Config.services.useTwelveHourClock
                    Layout.alignment: Qt.AlignHCenter
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
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: Time.format("ddd, d")
            color: Colours.palette.m3tertiary
            font.pointSize: Appearance.font.size.normal
            font.weight: 500
        }
    }
}
