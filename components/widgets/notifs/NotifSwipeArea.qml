import QtQuick
import Caelestia.Config
import qs.components

MouseArea {
    id: root

    required property bool expanded
    property bool expandable: true
    property bool dragExpand: expandable
    property bool hoveringLink
    property bool dragged
    property point pressPos
    property real lastX
    property real lastMoveTime
    property real velocity

    signal swiped
    signal dismissed
    signal requestExpand(expand: bool)

    hoverEnabled: true
    cursorShape: hoveringLink ? Qt.PointingHandCursor : pressedButtons === Qt.LeftButton ? Qt.ClosedHandCursor : undefined
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    preventStealing: dragExpand

    drag.target: pressedButtons === Qt.LeftButton ? this : null
    drag.axis: Drag.XAxis

    onPressed: event => {
        dragged = false;
        pressPos = Qt.point(event.x, event.y);
        lastX = x;
        lastMoveTime = Date.now();
        velocity = 0;
        if (event.button === Qt.RightButton && expandable)
            requestExpand(!expanded);
        else if (event.button === Qt.MiddleButton)
            dismissed();
    }
    onPositionChanged: event => {
        if (pressedButtons !== Qt.LeftButton)
            return;

        if (Math.abs(event.x - pressPos.x) > drag.threshold || Math.abs(event.y - pressPos.y) > drag.threshold)
            dragged = true;

        const now = Date.now();
        const dt = now - lastMoveTime;
        if (dt > 0) {
            velocity = (velocity + (x - lastX) / dt * 1000) / 2;
            lastX = x;
            lastMoveTime = now;
        }

        if (dragExpand) {
            const diffY = event.y - pressPos.y;
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
