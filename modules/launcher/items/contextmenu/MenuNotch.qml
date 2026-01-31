import QtQuick
import QtQuick.Shapes
import qs.config

Shape {
    id: root

    required property real cornerX
    required property real cornerY
    required property real radius
    required property int directionX  // 1 or -1
    required property int directionY  // 1 or -1
    required property color fillColor

    width: radius
    height: radius
    x: cornerX
    y: cornerY

    ShapePath {
        strokeWidth: -1
        fillColor: root.fillColor

        // Start at corner
        startX: 0
        startY: 0

        // Line in Y direction
        PathLine {
            x: 0
            y: directionY * radius
        }

        // Line in X direction to far corner
        PathLine {
            x: directionX * radius
            y: directionY * radius
        }

        // Arc from far corner back to origin using PathAngleArc for precise control
        PathAngleArc {
            centerX: directionX * radius
            centerY: directionY * radius
            radiusX: radius
            radiusY: radius
            // Match demo's arc angles for each direction combination
            startAngle: {
                if (directionX > 0 && directionY > 0)
                    return 180;      // π
                if (directionX > 0 && directionY < 0)
                    return 180;      // π
                if (directionX < 0 && directionY > 0)
                    return 0;        // 0
                return 0;                                               // 0 (dirX < 0, dirY < 0)
            }
            sweepAngle: {
                if (directionX > 0 && directionY > 0)
                    return 90;       // π to 3π/2, clockwise (false)
                if (directionX > 0 && directionY < 0)
                    return -90;      // π to π/2, anticlockwise (true)
                if (directionX < 0 && directionY > 0)
                    return -90;      // 0 to -π/2, anticlockwise (true)
                return 90;                                              // 0 to π/2, clockwise (false) (dirX < 0, dirY < 0)
            }
            moveToStart: false
        }
    }
}
