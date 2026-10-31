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
    property real lastX
    property real lastMoveTime
    property real velocity

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
        lastX = x;
        lastMoveTime = Date.now();
        velocity = 0;
        if (event.button === Qt.RightButton && expandable)
            requestExpand(!expanded);
        else if (event.button === Qt.MiddleButton)
            dismissed();
    }
    onPositionChanged: event => {
        if (!pressed)
            return;

        const now = Date.now();
        const dt = now - lastMoveTime;
        if (dt > 0) {
            velocity = (velocity + (x - lastX) / dt * 1000) / 2;
            lastX = x;
            lastMoveTime = now;
        }

        if (dragExpand) {
            const diffY = event.y - startY;
            if (Math.abs(diffY) > Config.notifs.expandThreshold)
                requestExpand(diffY > 0);
        }
    }
    onReleased: {
        const flung = Date.now() - lastMoveTime < 100 && Math.sign(velocity) === Math.sign(x) && Math.abs(velocity) > Config.notifs.clearVelocity;
        if (!flung && Math.abs(x) < width * Config.notifs.clearThreshold)
            x = 0;
        else
            swiped();
    }

    Behavior on x {
        Anim {}
    }
}
