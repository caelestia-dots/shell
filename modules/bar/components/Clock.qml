pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

StyledRect {
    id: root

    required property bool horizontal
    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)

    function fontFor(text: string, metricWidth: int): font {
        // We don't count seconds for the max width because it changes too often
        const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / metricWidth);
        return root.font.width(scale * 100).letterSpacing(scale).build();
    }

    implicitWidth: horizontal ? layout.implicitWidth + root.padding * 2 : Tokens.sizes.bar.innerWidth
    implicitHeight: horizontal ? Tokens.sizes.bar.innerWidth : layout.implicitHeight + root.padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    GridLayout {
        id: layout

        anchors.centerIn: parent
        columns: root.horizontal ? -1 : 1
        rowSpacing: Tokens.spacing.extraSmall
        columnSpacing: Tokens.spacing.extraSmall

        Loader {
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        // Date
        Loader {
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.clock.showDate
            visible: active

            sourceComponent: GridLayout {
                columns: root.horizontal ? -1 : 1
                rowSpacing: layout.rowSpacing - 4
                columnSpacing: layout.columnSpacing - 4

                // Day of the week
                StyledText {
                    Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
                    Layout.rightMargin: root.horizontal ? 4 : 0
                    text: Time.format("ddd")
                    font: root.horizontal ? root.font.build() : Tokens.font.body.builders.small.scale(0.9).build()
                    color: root.colour
                }

                // Day of the month
                StyledText {
                    Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
                    text: Time.format("d")
                    font: root.font.build()
                    color: root.colour
                }

                // Separator between day and month
                Loader {
                    Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
                    // Layout.leftMargin: root.horizontal ? -Tokens.padding.extraSmall / 2 : 0
                    // Layout.rightMargin: root.horizontal ? -Tokens.padding.extraSmall / 2 : 0
                    // Layout.bottomMargin: root.horizontal ? 2 : 0
                    asynchronous: true
                    active: root.horizontal
                    visible: active

                    sourceComponent: Text {
                        text: "/"
                        font: root.font.build()
                        color: root.colour
                    }
                }

                StyledText {
                    Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
                    // Layout.bottomMargin: root.horizontal ? 2 : 0
                    text: Time.format("MM")
                    font: root.font.scale(1.1).build()
                    color: root.colour
                }

                // Seperator between date and time
                StyledRect {
                    Layout.fillWidth: !root.horizontal
                    Layout.fillHeight: root.horizontal
                    Layout.leftMargin: root.horizontal ? Tokens.padding.extraSmall * 2 : -Tokens.padding.extraSmall
                    Layout.rightMargin: root.horizontal ? Tokens.padding.extraSmall * 2 : -Tokens.padding.extraSmall
                    Layout.topMargin: root.horizontal ? -Tokens.padding.extraSmall : 4
                    Layout.bottomMargin: root.horizontal ? -Tokens.padding.extraSmall : Tokens.padding.extraSmall / 2
                    implicitWidth: root.horizontal ? 1 : 0
                    implicitHeight: root.horizontal ? 0 : 1
                    color: Colours.palette.m3outlineVariant
                }
            }
        }

        // Hour
        StyledText {
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            text: Time.hourStr
            font: root.fontFor(text, hourMetrics.width)
            color: root.colour

            TextMetrics {
                id: hourMetrics

                font: root.font.build()
                text: Time.hourStr
            }
        }

        // Seperator between hour and minute
        Loader {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: root.horizontal ? -Tokens.padding.extraSmall / 2 : 0
            Layout.rightMargin: root.horizontal ? -Tokens.padding.extraSmall / 2 : 0
            Layout.bottomMargin: root.horizontal ? 2 : 0
            asynchronous: true
            active: root.horizontal
            visible: active

            sourceComponent: Text {
                text: ":"
                font: root.font.build()
                color: root.colour
            }
        }

        // Minute
        StyledText {
            Layout.topMargin: root.horizontal ? 0 : -parent.rowSpacing - 4
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            text: Time.minuteStr
            font: root.fontFor(text, minMetrics.width)
            color: root.colour

            TextMetrics {
                id: minMetrics

                font: root.font.build()
                text: Time.minuteStr
            }
        }

        // Seperator between minute and second
        Loader {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: root.horizontal ? -Tokens.padding.extraSmall / 2 : 0
            Layout.rightMargin: root.horizontal ? -Tokens.padding.extraSmall / 2 : 0
            Layout.bottomMargin: root.horizontal ? 2 : 0
            asynchronous: true
            active: Config.bar.clock.showSeconds && root.horizontal
            visible: active

            sourceComponent: Text {
                text: ":"
                font: root.font.build()
                color: root.colour
            }
        }

        // Second
        Loader {
            Layout.topMargin: root.horizontal ? 0 : -parent.rowSpacing - 4
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.clock.showSeconds
            visible: active

            sourceComponent: StyledText {
                text: Time.format("ss")
                font: root.fontFor(text, secMetrics.width)
                color: root.colour

                TextMetrics {
                    id: secMetrics

                    font: root.font.scale(0.9).build()
                    text: Time.format("ss")
                }
            }
        }

        // AM/PM
        Loader {
            Layout.topMargin: root.horizontal ? 0 : -parent.rowSpacing - 4
            Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
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
