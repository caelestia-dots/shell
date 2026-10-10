pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

StyledRect {
    id: root

    property bool isHorizontal: false
    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall

    implicitWidth: isHorizontal ? content.implicitWidth + padding * 2 : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : content.implicitHeight + padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Loader {
        id: content

        anchors.centerIn: parent
        sourceComponent: root.isHorizontal ? horizontalClock : verticalClock
    }

    Component {
        id: horizontalClock

        RowLayout {
            spacing: Tokens.spacing.small

            Loader {
                Layout.alignment: Qt.AlignVCenter
                asynchronous: true
                active: Config.bar.clock.showIcon
                visible: active

                sourceComponent: MaterialIcon {
                    text: "calendar_month"
                    color: root.colour
                    fontStyle: Tokens.font.icon.small
                }
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                asynchronous: true
                active: Config.bar.clock.showDate
                visible: active

                sourceComponent: StyledText {
                    text: Time.format("ddd d")
                    font: Tokens.font.body.small
                    color: root.colour
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: {
                    let str = `${Time.hourStr}:${Time.minuteStr}`;
                    if (Config.bar.clock.showSeconds)
                        str += `:${Time.format("ss")}`;
                    if (Units.twelveHourClock)
                        str += ` ${Time.amPmStr.toLowerCase()}`;
                    return str;
                }
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: root.colour
            }
        }
    }

    Component {
        id: verticalClock

        ColumnLayout {
            id: layout

            readonly property var font: Tokens.font.body.builders.small.scale(1.1)

            function fontFor(text: string, metricWidth: real): font {
                const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / metricWidth);
                return font.width(scale * 100).letterSpacing(scale).build();
            }

            spacing: Tokens.spacing.extraSmall

            Loader {
                Layout.alignment: Qt.AlignHCenter
                asynchronous: true
                active: Config.bar.clock.showIcon
                visible: active

                sourceComponent: MaterialIcon {
                    text: "calendar_month"
                    color: root.colour
                }
            }

            Loader {
                Layout.alignment: Qt.AlignHCenter
                asynchronous: true
                active: Config.bar.clock.showDate
                visible: active

                sourceComponent: ColumnLayout {
                    spacing: layout.spacing - 4

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Time.format("ddd")
                        font: Tokens.font.body.builders.small.scale(0.9).build()
                        color: root.colour
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Time.format("d")
                        font: layout.font.scale(1.1).build()
                        color: root.colour
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.leftMargin: -Tokens.padding.extraSmall
                        Layout.rightMargin: -Tokens.padding.extraSmall
                        Layout.topMargin: 4
                        Layout.bottomMargin: Tokens.padding.extraSmall / 2
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.hourStr
                font: layout.fontFor(text, hourMetrics.width)
                color: root.colour

                TextMetrics {
                    id: hourMetrics

                    font: layout.font.build()
                    text: Time.hourStr
                }
            }

            StyledText {
                Layout.topMargin: -layout.spacing - 4
                Layout.alignment: Qt.AlignHCenter
                text: Time.minuteStr
                font: layout.fontFor(text, minMetrics.width)
                color: root.colour

                TextMetrics {
                    id: minMetrics

                    font: layout.font.build()
                    text: Time.minuteStr
                }
            }

            Loader {
                Layout.topMargin: -layout.spacing - 4
                Layout.alignment: Qt.AlignHCenter
                asynchronous: true
                active: Config.bar.clock.showSeconds
                visible: active

                sourceComponent: StyledText {
                    text: Time.format("ss")
                    font: layout.fontFor(text, secMetrics.width)
                    color: root.colour

                    TextMetrics {
                        id: secMetrics

                        font: layout.font.build()
                        text: Time.format("ss")
                    }
                }
            }

            Loader {
                Layout.topMargin: -layout.spacing - 4
                Layout.alignment: Qt.AlignHCenter
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
}
