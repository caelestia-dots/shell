pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.normal : Tokens.padding.small

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + root.padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Column {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Loader {
            asynchronous: true
            anchors.horizontalCenter: parent.horizontalCenter

            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            visible: Config.bar.clock.showDate

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format("ddd\nd")
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.sans
            color: root.colour
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.bar.clock.showDate
            height: visible ? 1 : 0

            width: parent.width * 0.8
            color: root.colour
            opacity: 0.2
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format(GlobalConfig.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm")
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.mono
            color: root.colour
        }

        Loader {
            active: TimerService.active && (Config.bar.clock.timer?.enabled ?? true)
            visible: active
            anchors.horizontalCenter: parent.horizontalCenter

            sourceComponent: Column {
                spacing: Tokens.spacing.small

                Rectangle {
                    width: 30
                    height: 1
                    color: root.colour
                    opacity: 0.2
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                MaterialIcon {
                    text: "timer"
                    font.pointSize: Tokens.font.size.small
                    color: TimerService.running ? root.colour : Qt.alpha(root.colour, 0.5)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    horizontalAlignment: StyledText.AlignHCenter
                    text: {
                        const s = TimerService.remainingSeconds;
                        const h = Math.floor(s / 3600);
                        const m = Math.floor((s % 3600) / 60);
                        const sec = s % 60;
                        if (h > 0)
                            return h + "\n" + String(m).padStart(2, "0") + "\n" + String(sec).padStart(2, "0");
                        return String(m).padStart(2, "0") + "\n" + String(sec).padStart(2, "0");
                    }
                    font.pointSize: Tokens.font.size.smaller
                    font.family: Tokens.font.family.mono
                    color: root.colour
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
