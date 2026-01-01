import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property real value
    property int startAngle: -90
    property int strokeWidth: Appearance.padding.smaller
    property int padding: 0
    property int spacing: Appearance.spacing.small
    property color fgColour: Colours.palette.m3primary
    property color bgColour: Colours.palette.m3secondaryContainer

    readonly property real size: Math.min(width, height)
    readonly property real arcRadius: (size - padding - strokeWidth) / 2
    readonly property real vValue: value || 1 / 360
    readonly property real gapAngle: ((spacing + strokeWidth) / (arcRadius || 1)) * (180 / Math.PI)

    preferredRendererType: Shape.CurveRenderer
    asynchronous: true

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.bgColour
        strokeWidth: root.strokeWidth
        capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

        PathAngleArc {
            startAngle: root.startAngle + 360 * root.vValue + root.gapAngle
            sweepAngle: Math.max(-root.gapAngle, 360 * (1 - root.vValue) - root.gapAngle * 2)
            radiusX: root.arcRadius
            radiusY: root.arcRadius
            centerX: root.size / 2
            centerY: root.size / 2
        }

        Behavior on strokeColor {
            CAnim {
                duration: Appearance.anim.durations.large
            }
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.fgColour
        strokeWidth: root.strokeWidth
        capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

        PathAngleArc {
            startAngle: root.startAngle
            sweepAngle: 360 * root.vValue
            radiusX: root.arcRadius
            radiusY: root.arcRadius
            centerX: root.size / 2
            centerY: root.size / 2
        }

        Behavior on strokeColor {
            CAnim {
                duration: Appearance.anim.durations.large
            }
        }
    }
}
