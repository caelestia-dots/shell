import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property color fillColor
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomRightRadius: 0
    property real bottomLeftRadius: 0

    ShapePath {
        strokeWidth: -1
        fillColor: root.fillColor

        startX: topLeftRadius
        startY: 0

        PathLine {
            x: root.width - topRightRadius
            y: 0
        }

        PathArc {
            x: root.width
            y: topRightRadius
            radiusX: topRightRadius
            radiusY: topRightRadius
        }

        PathLine {
            x: root.width
            y: root.height - bottomRightRadius
        }

        PathArc {
            x: root.width - bottomRightRadius
            y: root.height
            radiusX: bottomRightRadius
            radiusY: bottomRightRadius
        }

        PathLine {
            x: bottomLeftRadius
            y: root.height
        }

        PathArc {
            x: 0
            y: root.height - bottomLeftRadius
            radiusX: bottomLeftRadius
            radiusY: bottomLeftRadius
        }

        PathLine {
            x: 0
            y: topLeftRadius
        }

        PathArc {
            x: topLeftRadius
            y: 0
            radiusX: topLeftRadius
            radiusY: topLeftRadius
        }
    }
}
