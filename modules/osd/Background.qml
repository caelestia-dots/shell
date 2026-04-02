import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

ShapePath {
    id: root

    required property Wrapper wrapper
    required property real rounding
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
    }
    PathLine {
        relativeX: -(root.wrapper.width - root.roundingX * 2)
        relativeY: 0
    }
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.rounding * 2
    }
    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
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

    Behavior on fillColor {
        CAnim {}
    }
}
