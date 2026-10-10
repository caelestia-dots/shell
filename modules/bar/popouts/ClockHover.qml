pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    readonly property real faceSize: Math.max(1, Tokens.sizes.bar.clockFaceSize)
    readonly property real faceScale: faceSize / 196
    readonly property string wideTime: {
        let widest = "0";
        for (let digit = 1; digit < 10; digit++) {
            if (fontMetrics.advanceWidth(String(digit)) > fontMetrics.advanceWidth(widest))
                widest = String(digit);
        }
        return `${widest}${widest}:${widest}${widest}:${widest}${widest}`;
    }

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    FontMetrics {
        id: fontMetrics

        font: digital.font
    }

    TextMetrics {
        id: amMetrics

        font: digital.font
        text: root.wideTime + (Units.twelveHourClock ? ` ${Qt.formatDateTime(new Date(2000, 0, 1, 1), "AP")}` : "")
    }

    TextMetrics {
        id: pmMetrics

        font: digital.font
        text: root.wideTime + (Units.twelveHourClock ? ` ${Qt.formatDateTime(new Date(2000, 0, 1, 13), "AP")}` : "")
    }

    ColumnLayout {
        id: column

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.spacing.large

        StyledRect {
            id: face

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: root.faceSize
            implicitHeight: root.faceSize
            radius: width / 2
            color: Colours.tPalette.m3surfaceContainer
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            Repeater {
                model: 60

                Rectangle {
                    id: tick

                    required property int index
                    readonly property bool hourMark: index % 5 === 0

                    width: (hourMark ? 3 : 1) * root.faceScale
                    height: (hourMark ? 10 : 5) * root.faceScale
                    radius: width / 2
                    color: hourMark ? Colours.palette.m3onSurface : Colours.palette.m3outline
                    antialiasing: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: (hourMark ? 10 : 13) * root.faceScale
                    transform: Rotation {
                        origin.x: tick.width / 2
                        origin.y: root.faceSize / 2 - tick.anchors.topMargin
                        angle: tick.index * 6
                    }
                }
            }

            Repeater {
                model: 12

                StyledText {
                    required property int index
                    readonly property real angle: index * Math.PI / 6

                    text: index === 0 ? "12" : index
                    font: Tokens.font.body.builders.small.scale(root.faceScale).weight(Font.DemiBold).build()
                    color: index % 3 === 0 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    x: face.width / 2 + Math.sin(angle) * 67 * root.faceScale - implicitWidth / 2
                    y: face.height / 2 - Math.cos(angle) * 67 * root.faceScale - implicitHeight / 2
                }
            }

            Hand {
                length: 49 * root.faceScale
                thickness: 6 * root.faceScale
                colour: Colours.palette.m3onSurface
                angle: (Time.hours % 12 + Time.minutes / 60 + Time.seconds / 3600) * 30
            }

            Hand {
                length: 67 * root.faceScale
                thickness: 4 * root.faceScale
                colour: Colours.palette.m3primary
                angle: (Time.minutes + Time.seconds / 60) * 6
            }

            Hand {
                length: 75 * root.faceScale
                thickness: 2 * root.faceScale
                colour: Colours.palette.m3tertiary
                angle: Time.seconds * 6
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 14 * root.faceScale
                implicitHeight: implicitWidth
                radius: width / 2
                color: Colours.palette.m3primary

                StyledRect {
                    anchors.centerIn: parent
                    implicitWidth: 5 * root.faceScale
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: Colours.palette.m3onPrimary
                }
            }

            NumberAnimation on scale {
                from: 0.84
                to: 1
                duration: Tokens.anim.durations.expressiveDefaultSpatial
                easing: Tokens.anim.expressiveDefaultSpatial
                running: root.visible
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.extraSmall

            StyledText {
                id: digital

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.ceil(Math.max(amMetrics.advanceWidth, pmMetrics.advanceWidth))
                horizontalAlignment: Text.AlignHCenter
                text: Time.format(Units.twelveHourClock ? "hh:mm:ss AP" : "HH:mm:ss")
                font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize).weight(Font.DemiBold).build()
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.format("dddd, d MMMM")
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component Hand: Item {
        id: hand

        required property real length
        required property real thickness
        required property color colour
        required property real angle

        anchors.horizontalCenter: face.horizontalCenter
        anchors.bottom: face.verticalCenter
        width: thickness
        height: length
        transformOrigin: Item.Bottom
        rotation: angle

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: hand.colour
            antialiasing: true
        }

        Behavior on rotation {
            enabled: root.visible

            RotationAnimation {
                duration: Tokens.anim.durations.expressiveDefaultSpatial
                direction: RotationAnimation.Shortest
                easing: Tokens.anim.expressiveDefaultSpatial
            }
        }
    }
}
