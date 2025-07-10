import "root:/services"
import "root:/config"
import QtQuick
import QtQuick.Effects

StyledRect {
    required property int extra

    anchors.right: parent.right
    anchors.margins: Appearance.padding.normal

    color: Colours.palette.m3tertiary
    radius: Appearance.rounding.small

    implicitWidth: count.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: count.implicitHeight + Appearance.padding.small * 2

    layer.enabled: opacity > 0
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 10
        shadowColor: Colours.palette.m3shadow
    }

    opacity: extra > 0 ? 1 : 0
    scale: extra > 0 ? 1 : 0.5

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
