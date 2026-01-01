pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property Props props
    required property Flickable container
    required property var visibilities

    readonly property alias repeater: repeater
    readonly property int spacing: Appearance.spacing.small
    property bool flag

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: {
        const item = repeater.itemAt(repeater.count - 1);
        return item ? item.y + item.implicitHeight : 0;
    }

    Repeater {
        id: repeater

        model: ScriptModel {
            values: {
                const map = new Map();
                for (const n of Notifs.notClosed)
                    map.set(n.appName, null);
                for (const n of Notifs.list)
                    map.set(n.appName, null);
                return [...map.keys()];
            }
            onValuesChanged: root.flagChanged()
        }

        MouseArea {
            id: notif

            required property int index
            required property string modelData

            readonly property bool closed: notifInner.notifCount === 0
            readonly property alias nonAnimHeight: notifInner.nonAnimHeight
            property int startY

            function closeAll(): void {
                for (const n of Notifs.notClosed.filter(n => n.appName === modelData))
                    n.close();
            }

            y: {
                root.flag; // Force update
                let y = 0;
                for (let i = 0; i < index; i++) {
                    const item = repeater.itemAt(i);
                    if (!item.closed)
                        y += item.nonAnimHeight + root.spacing;
                }
                return y;
            }

            containmentMask: QtObject {
                function contains(p: point): bool {
                    if (!root.container.contains(notif.mapToItem(root.container, p)))
                        return false;
                    return notifInner.contains(p);
                }
            }

            implicitWidth: root.width
            implicitHeight: notifInner.implicitHeight

            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : undefined
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            preventStealing: true
            enabled: !closed

            drag.target: this
            drag.axis: Drag.XAxis

            onPressed: event => {
                startY = event.y;
                if (event.button === Qt.RightButton)
                    notifInner.toggleExpand(!notifInner.expanded);
                else if (event.button === Qt.MiddleButton)
                    closeAll();
            }
            onPositionChanged: event => {
                if (pressed) {
                    const diffY = event.y - startY;
                    if (Math.abs(diffY) > Config.notifs.expandThreshold)
                        notifInner.toggleExpand(diffY > 0);
                }
            }
            onReleased: event => {
                if (Math.abs(x) < width * Config.notifs.clearThreshold)
                    x = 0;
                else
                    closeAll();
            }

            ParallelAnimation {
                running: true

                Anim {
                    target: notif
                    property: "opacity"
                    from: 0
                    to: 1
                }
                Anim {
                    target: notif
                    property: "scale"
                    from: 0
                    to: 1
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            ParallelAnimation {
                running: notif.closed

                Anim {
                    target: notif
                    property: "opacity"
                    to: 0
                }
                Anim {
                    target: notif
                    property: "scale"
                    to: 0.6
                }
            }

            NotifGroup {
                id: notifInner

                modelData: notif.modelData
                props: root.props
                container: root.container
                visibilities: root.visibilities
            }

            Behavior on x {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on y {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }
}
