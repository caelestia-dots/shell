pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

Slider {
    id: root

    property bool wavy
    property bool animateWave
    property real waveFrequency: 6
    property int waveDuration: 1000
    property int radius: Tokens.rounding.medium
    property bool interactionOnMove: true
    readonly property bool dragging: mouse.pressed

    property color fgColour: enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
    property color bgColour: enabled ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

    property real pos: visualPosition
    property real filledWidth

    signal interaction(v: real)

    Component.onCompleted: filledWidth = Qt.binding(() => (width - handle.implicitWidth - handle.anchors.leftMargin) * pos)

    implicitWidth: 200
    implicitHeight: 12

    contentItem: Item {
        anchors.fill: parent

        StyledRect {
            id: remaining

            anchors.left: handle.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitHeight: parent.height * (parent.height <= 12 ? opacity : Math.min(opacity * 2, 1))
            opacity: Math.min(width, 12) / 12

            radius: root.radius
            topLeftRadius: Tokens.rounding.extraSmall / 2
            bottomLeftRadius: Tokens.rounding.extraSmall / 2
            color: root.bgColour
        }

        StyledRect {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 4 * remaining.opacity

            implicitWidth: implicitHeight
            implicitHeight: 4 * remaining.opacity
            opacity: remaining.opacity

            radius: Tokens.rounding.full
            color: root.fgColour
        }

        StyledRect {
            id: handle

            anchors.left: filled.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitWidth: 4
            implicitHeight: {
                const t = CUtils.clamp((parent.height - 12) / 16, 0, 1);
                const lerp = (a, b) => a + (b - a) * t;
                return parent.height * (mouse.pressed ? lerp(3.5, 1.5) : lerp(3, 1.2));
            }

            radius: Tokens.rounding.full
            color: root.fgColour

            Behavior on implicitHeight {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Loader {
            id: filled

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true

            sourceComponent: root.wavy ? waveComp : lineComp
        }

        Component {
            id: lineComp

            StyledRect {
                implicitWidth: root.filledWidth
                implicitHeight: root.height

                radius: root.radius
                topRightRadius: Tokens.rounding.extraSmall / 2
                bottomRightRadius: Tokens.rounding.extraSmall / 2
                color: root.fgColour
            }
        }

        Component {
            id: waveComp

            WavyLine {
                lineWidth: root.height * 0.7
                frequency: root.waveFrequency
                startX: x
                fullLength: root.width - handle.implicitWidth - handle.anchors.leftMargin
                color: root.fgColour

                implicitWidth: root.filledWidth
                implicitHeight: lineWidth * amplitudeMultiplier * 2 + lineWidth

                Anim on waveProgress {
                    running: true
                    paused: !root.animateWave
                    from: 0
                    to: 1
                    duration: root.waveDuration
                    easing.type: Easing.Linear
                    loops: Animation.Infinite
                }

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }

    Binding {
        id: posBinding

        target: root
        property: "pos"
        value: CUtils.clamp(mouse.pressStartPos + mouse.dragMovement, 0, 1)
        when: mouse.pressed
    }

    MouseArea {
        id: mouse

        property real pressStartX
        property real pressStartPos
        property real dragMovement

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        preventStealing: true
        implicitHeight: handle.implicitHeight

        onPressed: e => {
            widthBehavior.enabled = false;
            pressStartX = e.x;
            pressStartPos = root.visualPosition;
        }
        onPositionChanged: e => {
            dragMovement = (e.x - pressStartX) / width;
            if (root.interactionOnMove)
                root.interaction(posBinding.value);
        }
        onReleased: e => {
            root.interaction(posBinding.value);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }

    Behavior on filledWidth {
        id: widthBehavior

        Anim {}
    }
}
