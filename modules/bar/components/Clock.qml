pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

MouseArea {
    id: root

    required property var popouts

    readonly property color colour: highlighted ? Colours.palette.m3onPrimary : Colours.palette.m3tertiary
    readonly property int padding: Tokens.padding.medium
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)
    readonly property bool menuOpen: popouts?.hasCurrent && popouts?.currentName === "clock"
    readonly property bool highlighted: containsMouse || menuOpen

    function fontFor(text: string, metricWidth: int): font {
        // We don't count seconds for the max width because it changes too often
        const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / metricWidth);
        return root.font.width(scale * 100).letterSpacing(scale).build();
    }

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.NoButton
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + root.padding * 2

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: root.highlighted ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer

        Behavior on color {
            CAnim {}
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.extraSmall

        Loader {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "calendar_month"
                color: root.colour
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.clock.showDate
            visible: active

            sourceComponent: ColumnLayout {
                width: layout.width
                spacing: layout.spacing - 4

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Time.format("ddd")
                    font: Tokens.font.body.builders.small.scale(0.9).build()
                    color: root.colour
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Time.format("d")
                    font: root.font.scale(1.1).build()
                    color: root.colour
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.extraSmall
                    Layout.rightMargin: Tokens.padding.extraSmall
                    Layout.topMargin: 4
                    Layout.bottomMargin: Tokens.padding.extraSmall / 2
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
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
            Layout.fillWidth: true
            Layout.topMargin: -parent.spacing - 4
            horizontalAlignment: Text.AlignHCenter
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
            Layout.fillWidth: true
            Layout.topMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.clock.showSeconds
            visible: active

            sourceComponent: StyledText {
                width: layout.width
                horizontalAlignment: Text.AlignHCenter
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
            Layout.fillWidth: true
            Layout.topMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Units.twelveHourClock
            visible: active

            sourceComponent: StyledText {
                width: layout.width
                horizontalAlignment: Text.AlignHCenter
                text: Time.amPmStr.toLowerCase()
                font: Tokens.font.body.builders.small.scale(0.9).build()
                color: root.colour
            }
        }
    }
}
