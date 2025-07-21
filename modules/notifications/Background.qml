import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.border.rounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding
    property real fullHeightRounding: wrapper.height >= QsWindow.window?.height - Config.border.thickness * 2 ? -rounding : rounding

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    PathLine {
        relativeX: -(root.wrapper.width + root.rounding)
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY * 2
    }
    PathArc {
        relativeX: root.fullHeightRounding
        relativeY: root.roundingY
        radiusX: Math.abs(root.fullHeightRounding)
        radiusY: Math.min(root.rounding, root.wrapper.height)
        direction: root.fullHeightRounding < 0 ? PathArc.Clockwise : PathArc.Counterclockwise
    }
    PathLine {
        relativeX: root.wrapper.height > 0 ? root.wrapper.width - root.rounding - root.fullHeightRounding : root.wrapper.width
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: root.rounding
        radiusX: root.rounding
        radiusY: root.rounding
    }

    Behavior on fillColor {
        ColorAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Behavior on fullHeightRounding {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
