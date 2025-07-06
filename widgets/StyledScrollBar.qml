import "root:/services"
import "root:/config"
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

    MouseArea {
        z: -1
        anchors.fill: parent
        property int scrollAccumulatedY: 0
        onWheel: event => {
            // Update accumulated scroll
            if (Math.sign(event.angleDelta.y) !== Math.sign(scrollAccumulatedY)) {
                scrollAccumulatedY = 0;
            }
            scrollAccumulatedY += event.angleDelta.y;
              
            // Check for positive scroll (up)
            if (scrollAccumulatedY >= 120 && event.angleDelta.y > 0) {
                root.decrease();
                scrollAccumulatedY = 0;
            }
            // Check for negative scroll (down)
            else if (scrollAccumulatedY <= -120 && event.angleDelta.y < 0) {
                root.increase();
                scrollAccumulatedY = 0;
            }
        }
    }
}
