import qs.config
import QtQuick
import QtQuick.Effects

MultiEffect {
    colorization: 1
    brightness: colorizationColor.hslLightness

    Behavior on colorizationColor {
        ColorAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
