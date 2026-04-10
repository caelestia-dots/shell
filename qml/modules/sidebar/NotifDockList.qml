pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import qs.components
import qs.services
import qs.config

LazyListView {
    id: root

    required property Props props
    required property Flickable container
    required property DrawerVisibilities visibilities

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: contentHeight

    spacing: Appearance.spacing.small
    readyDelay: 1
    cacheBuffer: 400
    asynchronous: true

    onViewportAdjustNeeded: d => {
        if (contentYAnim.running)
            contentYAnim.complete();
        contentYAnim.to = Math.max(0, container.contentY + d);
        contentYAnim.start();
    }

    useCustomViewport: true
    viewport: Qt.rect(0, container.contentY, width, container.height)

    removeDuration: Appearance.anim.durations.normal

    model: ScriptModel {
        values: {
            const map = new Map();
            for (const n of Notifs.notClosed)
                map.set(n.appName, null);
            for (const n of Notifs.list)
                map.set(n.appName, null);
            return [...map.keys()];
        }
    }

    delegate: Component {
        MouseArea {
            id: notif

            required property int index
            required property string modelData

            readonly property bool closed: notifInner.notifCount === 0
            property int startY

            function closeAll(): void {
                clearTimer.start();
            }

            LazyListView.trackViewport: !notifInner.expanded && notifInner.nonAnimHeight < notifInner.implicitHeight
            LazyListView.preferredHeight: closed ? 0 : notifInner.nonAnimHeight
            LazyListView.visibleHeight: notifInner.implicitHeight
            implicitHeight: notifInner.implicitHeight

            opacity: LazyListView.removing || closed || LazyListView.adding ? 0 : 1
            scale: LazyListView.removing || closed ? 0.6 : LazyListView.adding ? 0 : 1

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

            Timer {
                id: clearTimer

                interval: 15
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    const notifs = Notifs.notClosed.filter(n => n.appName === notif.modelData);
                    if (notifs.length === 0) {
                        stop();
                        return;
                    }

                    for (const n of notifs.slice(0, 30))
                        n.close();
                }
            }

            NotifGroup {
                id: notifInner

                modelData: notif.modelData
                props: root.props
                container: root.container
                visibilities: root.visibilities
            }

            Behavior on y {
                enabled: notif.LazyListView.ready

                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on x {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }

    Anim {
        id: contentYAnim

        target: root.container
        property: "contentY"
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
