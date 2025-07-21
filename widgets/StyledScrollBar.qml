import qs.services
import qs.config
import QtQuick
import QtQuick.Controls

ScrollBar {
    id: root

    contentItem: StyledRect {
        implicitWidth: 6
        opacity: root.pressed ? 1 : root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1) ? 0.8 : 0
        radius: Appearance.rounding.full
        color: Colours.palette.m3secondary

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

    CustomMouseArea {
        z: -1
        anchors.fill: parent

        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.decrease();
            else if (event.angleDelta.y < 0)
                root.increase();
        }
    }
}
