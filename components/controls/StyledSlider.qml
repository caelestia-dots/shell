pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.Scheme
import qs.components

Slider {
    id: root

    property bool wavy
    property bool animateWave
    property real waveFrequency: 6
    property int waveDuration: 1000
    property int radius: Tokens.rounding.medium
    property bool interactionOnMove: true
    property real handleHeight
    readonly property bool dragging: mouse.pressed

    property color fgColour: enabled ? Colours.palette.primary : Qt.alpha(Colours.palette.onSurface, 0.38)
    property color bgColour: enabled ? Colours.palette.secondaryContainer : Qt.alpha(Colours.palette.onSurface, 0.1)

    property real pos: visualPosition
    property real filledWidth

    signal interaction(v: real)

    function snapPos(p: real): real {
        if (stepSize <= 0)
            return p;
        const steps = (to - from) / stepSize;
        return Math.round(p * steps) / steps;
    }

    Component.onCompleted: filledWidth = Qt.binding(() => (width - handle.implicitWidth - handle.anchors.leftMargin * 2) * pos)

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
            visible: root.stepSize <= 0

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
                if (root.handleHeight > 0)
                    return parent.height * root.handleHeight;

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

        Repeater {
            model: root.stepSize > 0 ? Math.round((root.to - root.from) / root.stepSize) + 1 : 0

            StyledRect {
                required property int index

                readonly property int count: Math.round((root.to - root.from) / root.stepSize) + 1
                readonly property real stepPos: index / (count - 1)
                readonly property real trackLength: root.width - handle.implicitWidth - handle.anchors.leftMargin * 2
                readonly property bool nearHandle: Math.abs(stepPos - root.pos) * trackLength < handle.implicitWidth + Tokens.spacing.extraSmall * 2
                readonly property bool onFilled: stepPos <= root.pos

                x: trackLength * stepPos + handle.anchors.leftMargin + (handle.implicitWidth - implicitWidth) / 2
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 4
                implicitHeight: 4
                radius: Tokens.rounding.full
                color: onFilled ? root.bgColour : root.fgColour
                opacity: nearHandle || (root.wavy && onFilled) ? 0 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
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
                fullLength: root.width - handle.implicitWidth - handle.anchors.leftMargin * 2
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
        value: root.snapPos(CUtils.clamp(mouse.pressStartPos + mouse.dragMovement, 0, 1))
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
            widthBehavior.enabled = root.stepSize > 0;
            pressStartX = e.x;
            pressStartPos = root.visualPosition;
        }
        onPositionChanged: e => {
            dragMovement = (e.x - pressStartX) / width;
            if (root.interactionOnMove)
                root.interaction(posBinding.value);
        }
        onReleased: e => {
            const clickPos = e.x / width;
            const finalPos = mouse.dragMovement !== 0 ? posBinding.value : root.snapPos(CUtils.clamp(clickPos, 0, 1));
            root.interaction(finalPos);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }

    Behavior on filledWidth {
        id: widthBehavior

        Anim {}
    }
}
