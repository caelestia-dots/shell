import QtQuick
import qs.components

Flickable {
    id: root

    // How far one wheel notch scrolls
    property real wheelStep: 120
    property bool doneFakeFlick

    maximumFlickVelocity: 3000

    // Reset only when the user scrolls again, so the flick this triggers can't
    // trigger another rebound and leave the view stuck "moving" - which makes
    // the Flickable swallow every press meant for the controls inside it.
    onDraggingChanged: {
        if (dragging)
            doneFakeFlick = false;
    }

    rebound: Transition {
        onRunningChanged: {
            if (!running && !root.doneFakeFlick) {
                root.doneFakeFlick = true;
                root.flick(1, 1);
                root.flick(-1, -1);
                Qt.callLater(() => root.cancelFlick());
            }
        }

        Anim {
            properties: "x,y"
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse

        onWheel: event => {
            const min = -root.topMargin;
            const max = Math.max(min, root.contentHeight - root.height + root.bottomMargin);
            const from = wheelAnim.running ? wheelAnim.to : root.contentY;
            const to = Math.max(min, Math.min(max, from - event.angleDelta.y / 120 * root.wheelStep));
            if (to === root.contentY)
                return;

            root.doneFakeFlick = false;
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
