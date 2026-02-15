import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper
    required property var sidebar
    readonly property real rounding: Config.border.rounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    PathLine {
        relativeX: -(root.wrapper.width + root.rounding)
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
        direction: PathArc.Counterclockwise
    }
    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY * 2)
    }
    PathArc {
        relativeX: root.sidebar.utilsRoundingX
        relativeY: -root.roundingY
        radiusX: root.sidebar.utilsRoundingX
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }
    PathLine {
        relativeX: root.wrapper.height > 0 ? root.wrapper.width - root.rounding - root.sidebar.utilsRoundingX : root.wrapper.width
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: -root.rounding
        radiusX: root.rounding
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }

    Behavior on fillColor {
        CAnim {}
    }
}
