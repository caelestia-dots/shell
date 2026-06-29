import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.components
import qs.services

TextFieldBase {
    id: root

    property int smallFontSize: Tokens.font.label.small.pointSize
    readonly property real smallFontScale: smallFontSize / font.pointSize

    readonly property int horizontalPadding: Tokens.padding.large
    property int radius: Tokens.rounding.small
    readonly property int clampedRadius: Math.min(horizontalPadding, Math.min(width, height) / 2, radius)

    readonly property real outlineGap: placeholder.width * root.smallFontScale + root.Tokens.spacing.extraSmall * 2
    property real outlineGapScale: activeFocus ? 1 : 0

    leftPadding: horizontalPadding
    rightPadding: horizontalPadding

    background: Shape {
        id: bg

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        ShapePath {
            strokeWidth: root.activeFocus ? 2 : 1
            strokeColor: root.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 16 - root.clampedRadius + root.outlineGap * (1 - root.outlineGapScale) / 2 + root.outlineGap * root.outlineGapScale

            PathLine {
                x: bg.width - root.clampedRadius
            }
            PathArc {
                x: bg.width
                y: root.clampedRadius
                radiusX: root.clampedRadius
                radiusY: root.clampedRadius
            }
            PathLine {
                x: bg.width
                y: bg.height - root.clampedRadius
            }
            PathArc {
                x: bg.width - root.clampedRadius
                y: bg.height
                radiusX: root.clampedRadius
                radiusY: root.clampedRadius
            }
            PathLine {
                x: root.clampedRadius
                y: bg.height
            }
            PathArc {
                x: 0
                y: bg.height - root.clampedRadius
                radiusX: root.clampedRadius
                radiusY: root.clampedRadius
            }
            PathLine {
                x: 0
                y: root.clampedRadius
            }
            PathArc {
                x: root.clampedRadius
                y: 0
                radiusX: root.clampedRadius
                radiusY: root.clampedRadius
            }
            PathLine {
                x: 16 - root.clampedRadius + root.outlineGap * (1 - root.outlineGapScale) / 2
            }

            Behavior on strokeWidth {
                Anim {}
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    Behavior on outlineGapScale {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    StyledText {
        id: placeholder

        font.family: root.font.family
        font.variableAxes: root.font.variableAxes
        font.pointSize: root.font.pointSize
        font.weight: root.font.weight

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.horizontalPadding
        renderType: Text.QtRendering

        text: root.placeholderText
        color: root.activeFocus ? Colours.palette.m3primary : root.placeholderTextColor

        states: State {
            name: "small"
            when: root.activeFocus

            PropertyChanges {
                placeholder.scale: root.smallFontScale
                placeholder.anchors.leftMargin: -(1 - root.smallFontScale) * placeholder.width / 2 + root.horizontalPadding - root.Tokens.spacing.extraSmall
            }
            AnchorChanges {
                target: placeholder
                anchors.verticalCenter: root.top
            }
        }

        transitions: Transition {
            Anim {
                properties: "scale,leftMargin"
                type: Anim.DefaultEffects
            }
            AnchorAnim {
                duration: Tokens.anim.durations.expressiveDefaultEffects
                easing: Tokens.anim.expressiveDefaultEffects
            }
        }
    }
}
