import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    // implicitWidth: 300
    // implicitHeight: 100

    // Rectangle {
    //     anchors.fill: parent
    // }

    Behavior on implicitHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
