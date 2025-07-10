import "root:/config"
import QtQuick

ListView {
    id: root

    maximumFlickVelocity: 3000

    rebound: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
