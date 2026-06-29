pragma ComponentBehavior: Bound

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
    property real outlineGapScale: activeFocus || text ? 1 : 0

    property string leadingIcon
    property string trailingIcon
    readonly property int leadingOffset: leadingIcon ? leadingIconLoader.width + leadingIconLoader.anchors.leftMargin : 0
    readonly property int trailingOffset: trailingIcon ? trailingIconLoader.width + trailingIconLoader.anchors.rightMargin : 0

    property string supportingText
    readonly property int supportingTextOffset: supportingText ? supportingTextLoader.height + Tokens.spacing.extraSmall : 0

    leftPadding: horizontalPadding + leadingOffset
    rightPadding: horizontalPadding + trailingOffset
    topPadding: Tokens.padding.large
    bottomPadding: Tokens.padding.large + supportingTextOffset

    onPressed: {
        if (!stateLayer.disabled)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }

    background: Shape {
        id: bg

        anchors.fill: parent
        anchors.bottomMargin: root.supportingTextOffset
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        ShapePath {
            strokeWidth: root.activeFocus ? 2 : 1
            strokeColor: root.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: root.horizontalPadding - root.clampedRadius + root.outlineGap * (1 - root.outlineGapScale) / 2 + root.outlineGap * root.outlineGapScale

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
                x: root.horizontalPadding - root.clampedRadius + root.outlineGap * (1 - root.outlineGapScale) / 2
            }

            Behavior on strokeWidth {
                Anim {}
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }

        StateLayer {
            id: stateLayer

            cursorShape: Qt.IBeamCursor
            disabled: root.activeFocus
            manualPressOverride: tapHandler.pressed
            onClicked: root.focus = true
        }
    }

    Behavior on outlineGapScale {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Item {
        id: contentWrapper

        anchors.fill: parent
        anchors.bottomMargin: root.supportingTextOffset

        StyledText {
            id: placeholder

            font.family: root.font.family
            font.variableAxes: root.font.variableAxes
            font.pointSize: root.font.pointSize
            font.weight: root.font.weight

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: root.leftPadding
            renderType: Text.QtRendering

            text: root.placeholderText
            color: root.activeFocus ? Colours.palette.m3primary : root.text ? Colours.palette.m3outline : root.placeholderTextColor

            states: State {
                name: "small"
                when: root.activeFocus || root.text

                PropertyChanges {
                    placeholder.scale: root.smallFontScale
                    placeholder.anchors.leftMargin: -(1 - root.smallFontScale) * placeholder.width / 2 + root.horizontalPadding - root.Tokens.spacing.extraSmall
                }
                AnchorChanges {
                    target: placeholder
                    anchors.verticalCenter: contentWrapper.top
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

        Loader {
            id: leadingIconLoader

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.medium
            active: root.leadingIcon

            sourceComponent: MaterialIcon {
                text: root.leadingIcon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.medium.scale(0.9).build()
            }
        }

        Loader {
            id: trailingIconLoader

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Tokens.padding.medium
            active: root.trailingIcon

            sourceComponent: MaterialIcon {
                text: root.trailingIcon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.medium.scale(0.9).build()
            }
        }
    }

    Loader {
        id: supportingTextLoader

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: root.horizontalPadding
        active: root.supportingText

        sourceComponent: StyledText {
            text: root.supportingText
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }

    TapHandler {
        id: tapHandler
    }
}
