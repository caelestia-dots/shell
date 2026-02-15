import qs.config
import QtQuick

ColorAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
