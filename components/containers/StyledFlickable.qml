import QtQuick
import qs.components

Flickable {
    id: root

    // How far one wheel notch scrolls
    property real wheelStep: 120

    maximumFlickVelocity: 3000

    // Don't let a running wheel animation fight the user grabbing the content
    onDraggingChanged: {
        if (dragging)
            wheelAnim.stop();
    }

    rebound: Transition {
        enabled: Math.abs(root.verticalOvershoot) >= 0.5 || Math.abs(root.horizontalOvershoot) >= 0.5

        onRunningChanged: {
            if (running)
                return;
            const x = root.contentX;
            const y = root.contentY;
            root.contentX = x + 1;
            root.contentY = y + 1;
            root.contentX = x;
            root.contentY = y;
        }

        Anim {
            properties: "x,y"
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        blocking: root.contentHeight + root.topMargin + root.bottomMargin > root.height

        onWheel: event => {
            const min = -root.topMargin;
            const max = Math.max(min, root.contentHeight - root.height + root.bottomMargin);
            const from = wheelAnim.running ? wheelAnim.to : root.contentY;
            const to = Math.max(min, Math.min(max, from - event.angleDelta.y / 120 * root.wheelStep));
            if (to === root.contentY)
                return;

            wheelAnim.to = to;
            wheelAnim.restart();
        }
    }

    Anim {
        id: wheelAnim

        target: root
        property: "contentY"
        type: Anim.FastSpatial
    }
}
