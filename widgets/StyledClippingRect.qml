import qs.config
import Quickshell.Widgets
import QtQuick

ClippingRectangle {
    id: root

    color: "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
