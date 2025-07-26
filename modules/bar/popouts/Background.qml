import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper
    required property bool invertBottomRounding
    readonly property real rounding: wrapper.isDetached ? Appearance.rounding.normal : Config.border.rounding
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding
    property real ibr: invertBottomRounding ? -1 : 1

    property real sideRounding: startX > 0 ? -1 : 1

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding * root.sideRounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: root.sideRounding < 0 ? PathArc.Clockwise : PathArc.Counterclockwise
    }
    PathLine {
        relativeX: root.wrapper.width - root.roundingX * 2
        relativeY: 0
    }
    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.rounding * 2
    }
    PathArc {
        relativeX: -root.roundingX * root.ibr
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: root.ibr < 0 ? PathArc.Counterclockwise : PathArc.Clockwise
    }
    PathLine {
        relativeX: -(root.wrapper.width - root.roundingX - root.roundingX * root.ibr)
        relativeY: 0
    }
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding * root.sideRounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: root.sideRounding < 0 ? PathArc.Clockwise : PathArc.Counterclockwise
    }

    Behavior on fillColor {
        ColorAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Behavior on ibr {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Behavior on sideRounding {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
