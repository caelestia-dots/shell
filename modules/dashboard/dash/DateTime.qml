pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    readonly property var separatorFont: Tokens.font.clock.size(28 * 0.9).build()
    readonly property var timeFont: {
        const value = Tokens.font.clock.size(28).weight(Font.DemiBold).build();
        value.features = {
            "tnum": 1
        };
        return value;
    }

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
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Time.hourStr
            color: Colours.palette.m3secondary
            font: root.timeFont
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "•••"
            color: Colours.palette.m3primary
            font: root.separatorFont
        }

        StyledText {
            Layout.topMargin: -(font.pointSize * 0.4)
            Layout.bottomMargin: Config.dashboard.showClockSeconds ? -(font.pointSize * 0.4) : 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Time.minuteStr
            color: Colours.palette.m3secondary
            font: root.timeFont
        }

        Loader {
            asynchronous: true
            Layout.alignment: Qt.AlignHCenter

            active: Config.dashboard.showClockSeconds
            visible: active

            sourceComponent: ColumnLayout {
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "•••"
                    color: Colours.palette.m3primary
                    font: root.separatorFont
                }

                StyledText {
                    Layout.topMargin: -(font.pointSize * 0.4)
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Time.format("ss")
                    color: Colours.palette.m3secondary
                    font: root.timeFont
                }
            }
        }

        Loader {
            asynchronous: true
            Layout.alignment: Qt.AlignHCenter

            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr
                color: Colours.palette.m3primary
                font: Tokens.font.clock.size(18).weight(Font.DemiBold).build()
            }
        }
    }
}
