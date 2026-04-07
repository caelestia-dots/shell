import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services
import qs.config

ShapePath {
    id: root

    required property Item clipboardPreview
    readonly property real rounding: Config.border.rounding

    strokeWidth: clipboardPreview.visible ? -1 : 0
    fillColor: Colours.palette.m3surface

    // Bottom left inverse arc
    PathArc {
        relativeX: root.rounding
        relativeY: root.clipboardPreview.height > root.rounding ? -root.rounding : -root.clipboardPreview.height
        radiusX: root.rounding
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }

    // Left edge going up
    PathLine {
        relativeX: 0
        relativeY: root.clipboardPreview.height > root.rounding * 2 ? -(root.clipboardPreview.height - root.rounding * 2) : 0
    }

    // Top left rounded corner
    PathArc {
        relativeX: root.rounding
        relativeY: -root.rounding
        radiusX: root.rounding
        radiusY: root.rounding
    }

    // Top edge
    PathLine {
        relativeX: root.clipboardPreview.width - root.rounding * 2
        relativeY: 0
    }

    // Top right rounded corner
    PathArc {
        relativeX: root.rounding
        relativeY: root.rounding
        radiusX: root.rounding
        radiusY: root.rounding
    }

    // Right edge going down
    PathLine {
        relativeX: 0
        relativeY: root.clipboardPreview.height > root.rounding * 2 ? root.clipboardPreview.height - root.rounding * 2 : 0
    }

    // Bottom right inverse fillet
    PathArc {
        relativeX: root.rounding
        relativeY: root.clipboardPreview.height > root.rounding ? root.rounding : root.clipboardPreview.height
        radiusX: root.rounding
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }

    Behavior on fillColor {
        CAnim {}
    }
}
