pragma ComponentBehavior: Bound

import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

BusyIndicator {
    id: root

    property color fgColour: Colours.palette.m3onPrimaryContainer
    property color bgColour: Colours.palette.m3primaryContainer

    background: null

    contentItem: Shape {
        id: shape

        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        RotationAnimator on rotation {
            from: 0
            to: 180
            running: root.visible && root.running
            loops: Animation.Infinite
            duration: Appearance.anim.durations.extraLarge
            easing.type: Easing.Linear
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }

        ShapePath {
            strokeWidth: Math.min(root.implicitWidth, root.implicitHeight) * 0.18
            strokeColor: root.bgColour
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                radiusX: root.implicitWidth / 2
                radiusY: root.implicitHeight / 2
                startAngle: 0
                sweepAngle: 360
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }

        ShapePath {
            strokeWidth: Math.min(root.implicitWidth, root.implicitHeight) * 0.18
            strokeColor: root.fgColour
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                radiusX: root.implicitWidth / 2
                radiusY: root.implicitHeight / 2
                startAngle: -sweepAngle / 2
                sweepAngle: 60
            }

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                radiusX: root.implicitWidth / 2
                radiusY: root.implicitHeight / 2
                startAngle: 180 - sweepAngle / 2
                sweepAngle: 60
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }
}
