pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property real centerScale

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + Tokens.spacing.small
    implicitHeight: hourMetrics.tightBoundingRect.height

    StyledText {
        id: hours

        y: -root.calcTopOff(hourMetrics)
        text: Time.hourStr
        color: Colours.palette.m3primary
        font: Tokens.font.headline.builders.large.scale(7 * root.centerScale).width(30).build()

        TextMetrics {
            id: hourMetrics

            text: hours.text
            font: hours.font
        }
    }

    StyledText {
        id: minutes

        anchors.right: parent.right
        y: -root.calcTopOff(minuteMetrics)

        text: Time.minuteStr
        color: Colours.palette.m3secondary
        font: Tokens.font.headline.builders.large.scale((GlobalConfig.services.useTwelveHourClock ? 3.8 : 7) * root.centerScale).width(30).build()

        TextMetrics {
            id: minuteMetrics

            text: minutes.text
            font: minutes.font
        }
    }

    Loader {
        anchors.left: minutes.left
        anchors.leftMargin: minuteMetrics.tightBoundingRect.x
        y: hourMetrics.tightBoundingRect.height - implicitHeight

        active: GlobalConfig.services.useTwelveHourClock
        asynchronous: true

        sourceComponent: StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.large

            implicitWidth: minuteMetrics.tightBoundingRect.width
            implicitHeight: amPmMetrics.tightBoundingRect.height + Tokens.padding.large * 2

            StyledText {
                id: amPm

                anchors.centerIn: parent
                width: amPmMetrics.tightBoundingRect.width
                height: amPmMetrics.tightBoundingRect.height
                transform: Translate {
                    x: -amPmMetrics.tightBoundingRect.x
                    y: -root.calcTopOff(amPmMetrics)
                }

                text: Time.amPmStr
                color: Colours.palette.m3onSurface
                font: Tokens.font.headline.builders.small.scale(2 * root.centerScale).width(30).build()

                TextMetrics {
                    id: amPmMetrics

                    text: amPm.text
                    font: amPm.font
                }
            }
        }
    }
}
