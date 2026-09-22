pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)
    readonly property bool isHorizontal: Config.bar.alignment === "top" || Config.bar.alignment === "bottom"

    function fontFor(text: string, metricWidth: int): font {
        // We don't count seconds for the max width because it changes too often
        if (isHorizontal) return root.font.build();
        const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / metricWidth);
        return root.font.width(scale * 100).letterSpacing(scale).build();
    }

    implicitWidth: isHorizontal ? layout.implicitWidth + root.padding * 2 : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : layout.implicitHeight + root.padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    GridLayout {
        id: layout

        anchors.centerIn: parent
        
        flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
        rows: root.isHorizontal ? 1 : -1
        columns: root.isHorizontal ? -1 : 1
        columnSpacing: Tokens.spacing.small
        rowSpacing: root.isHorizontal ? 0 : Tokens.spacing.extraSmall

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            visible: Config.bar.clock.showIcon
            text: "calendar_month"
            color: root.colour
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            visible: Config.bar.clock.showDate && root.isHorizontal
            text: Time.format("ddd, d MMM")
            font: root.font.build()
            color: root.colour
        }

        GridLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            visible: Config.bar.clock.showDate && !root.isHorizontal
            flow: GridLayout.TopToBottom
            rows: -1
            columns: 1
            rowSpacing: layout.rowSpacing - 4

            StyledText { Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter; text: Time.format("ddd"); font: Tokens.font.body.builders.small.scale(0.9).build(); color: root.colour }
            StyledText { Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter; text: Time.format("d"); font: root.font.scale(1.1).build(); color: root.colour }
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: Tokens.padding.extraSmall / 2
                Layout.leftMargin: -Tokens.padding.extraSmall
                Layout.rightMargin: -Tokens.padding.extraSmall
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            visible: root.isHorizontal
            text: {
                let t = Time.hourStr + ":" + Time.minuteStr;
                if (Config.bar.clock.showSeconds) {
                    t += ":" + Time.format("ss");
                }
                return t;
            }
            font: root.font.build()
            color: root.colour
            horizontalAlignment: Text.AlignHCenter
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.isHorizontal
            text: Time.hourStr
            font: root.fontFor(text, hourMetrics.width)
            color: root.colour

            TextMetrics {
                id: hourMetrics
                font: root.font.build()
                text: Time.hourStr
            }
        }

        StyledText {
            Layout.topMargin: -parent.rowSpacing - 4
            Layout.alignment: Qt.AlignHCenter
            visible: !root.isHorizontal
            text: Time.minuteStr
            font: root.fontFor(text, minMetrics.width)
            color: root.colour

            TextMetrics {
                id: minMetrics

                font: root.font.build()
                text: Time.minuteStr
            }
        }

        Loader {
            Layout.topMargin: -parent.rowSpacing - 4
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.clock.showSeconds && !root.isHorizontal
            visible: active

            sourceComponent: StyledText {
                text: Time.format("ss")
                font: root.fontFor(text, secMetrics.width)
                color: root.colour

                TextMetrics {
                    id: secMetrics

                    font: root.font.build()
                    text: Time.format("ss")
                }
            }
        }

        Loader {
            Layout.topMargin: root.isHorizontal ? 0 : (-parent.rowSpacing - 4)
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            asynchronous: true
            active: Units.twelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr.toLowerCase()
                font: Tokens.font.body.builders.small.scale(0.9).build()
                color: root.colour
            }
        }
    }
}
