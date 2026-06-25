import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property bool first
    property bool last
    // Identifier used by the settings search to scroll to this row.
    property string settingAnchor

    // Run a chase animation along the row's border, used when the settings
    // search jumps to it: a short bright segment races around the outline a
    // couple of times and then fades out. Drawn as a dashed stroke (one short
    // dash, a long gap) whose dash offset is animated, so the bright part
    // follows the rounded corners exactly.
    function flashHighlight(): void {
        chase.restart();
    }

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

    Shape {
        id: border

        // Perimeter of the rounded rect, used to size the dash so exactly one
        // bright segment travels around at a time.
        readonly property real strokeWidth: 2
        readonly property real radius: root.topLeftRadius
        readonly property real perimeter: 2 * (width + height) - 8 * radius + 2 * Math.PI * radius
        readonly property real dashLen: Math.max(1, perimeter)
        property real offset: 0

        anchors.fill: parent
        anchors.margins: strokeWidth / 2
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        opacity: 0

        ShapePath {
            strokeColor: Colours.palette.m3primary
            strokeWidth: border.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            strokeStyle: ShapePath.DashLine
            // One short visible dash, then a gap as long as the whole border.
            dashPattern: [0.18 * border.dashLen / border.strokeWidth, border.dashLen / border.strokeWidth]
            dashOffset: border.offset

            PathRectangle {
                x: 0
                y: 0
                width: border.width - border.strokeWidth
                height: border.height - border.strokeWidth
                radius: Math.max(0, border.radius - border.strokeWidth / 2)
            }
        }

        SequentialAnimation {
            id: chase

            PropertyAction {
                target: border
                property: "opacity"
                value: 1
            }
            ParallelAnimation {
                NumberAnimation {
                    target: border
                    property: "offset"
                    from: 0
                    to: 2 * border.dashLen / border.strokeWidth
                    duration: Tokens.anim.durations.extraLarge * 2
                    easing.type: Easing.InOutQuad
                }
                SequentialAnimation {
                    PauseAnimation {
                        duration: Tokens.anim.durations.large
                    }
                    NumberAnimation {
                        target: border
                        property: "opacity"
                        to: 0
                        duration: Tokens.anim.durations.large
                    }
                }
            }
        }
    }
}
