import qs.services
import qs.config
import QtQuick

StyledRect {
    required property int extra

    anchors.right: parent.right
    anchors.margins: Appearance.padding.normal

    color: Colours.palette.m3tertiary
    radius: Appearance.rounding.small

    implicitWidth: count.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: count.implicitHeight + Appearance.padding.small * 2

    opacity: extra > 0 ? 1 : 0
    scale: extra > 0 ? 1 : 0.5

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 2
    }

    StyledText {
        id: count

        anchors.centerIn: parent
        animate: parent.opacity > 0
        text: qsTr("+%1").arg(parent.extra)
        color: Colours.palette.m3onTertiary
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
        }
    }
}
