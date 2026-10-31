import QtQuick
import Caelestia.Config
import qs.components

MouseArea {
    id: root

    required property bool expanded
    property bool expandable: true
    property bool dragExpand: expandable
    property bool hoveringLink
    property int startY

    signal swiped
    signal dismissed
    signal requestExpand(expand: bool)

    hoverEnabled: true
    cursorShape: hoveringLink ? Qt.PointingHandCursor : pressed ? Qt.ClosedHandCursor : undefined
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    preventStealing: dragExpand

    drag.target: this
    drag.axis: Drag.XAxis

    onPressed: event => {
        startY = event.y;
        if (event.button === Qt.RightButton && expandable)
            requestExpand(!expanded);
        else if (event.button === Qt.MiddleButton)
            dismissed();
    }
    onPositionChanged: event => {
        if (pressed && dragExpand) {
            const diffY = event.y - startY;
            if (Math.abs(diffY) > Config.notifs.expandThreshold)
                requestExpand(diffY > 0);
        }
    }
    onReleased: {
        if (Math.abs(x) < width * Config.notifs.clearThreshold)
            x = 0;
        else
            swiped();
    }

    Behavior on x {
        Anim {}
    }
}
