pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

LazyListView {
    id: root

    required property Props props
    required property list<var> notifs
    required property bool expanded
    required property Flickable container
    required property DrawerVisibilities visibilities

    signal requestToggleExpand(expand: bool)

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: contentHeight

    spacing: Math.round(Tokens.spacing.small / 2)
    asynchronous: true

    readyDelay: 1
    cacheBuffer: 400
    removeDuration: Tokens.anim.durations.normal

    useCustomViewport: true
    viewport: {
        tWatcher.transform; // mapToItem is not reactive so use this to trigger updates
        return Qt.rect(0, container.contentY - mapToItem(container.contentItem, 0, 0).y, width, container.height);
    }

    model: ScriptModel {
        values: {
            if (root.expanded)
                return root.notifs;

            let count = 0;
            let i = 0;
            const previewNum = root.Config.notifs.groupPreviewNum;
            while (i < root.notifs.length && count < previewNum) {
                if (!(root.notifs[i]?.closed ?? true))
                    count++;
                i++;
            }

            return root.notifs.slice(0, i);
        }
    }

    delegate: Component {
        MouseArea {
            id: notif

            required property int index
            required property NotifData modelData

            property int startY

            Component.onCompleted: modelData?.lock(this)
            Component.onDestruction: modelData?.unlock(this)

            LazyListView.preferredHeight: modelData?.closed || LazyListView.removing ? 0 : notifInner.nonAnimHeight
            LazyListView.visibleHeight: modelData?.closed || LazyListView.removing ? 0 : notifInner.implicitHeight
            implicitHeight: notifInner.implicitHeight

            opacity: LazyListView.removing || LazyListView.adding ? 0 : 1
            scale: LazyListView.removing || LazyListView.adding ? 0.7 : 1

            hoverEnabled: true
            cursorShape: notifInner.body?.hoveredLink ? Qt.PointingHandCursor : pressed ? Qt.ClosedHandCursor : undefined
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            preventStealing: !root.expanded
            enabled: !(modelData?.closed ?? true)

            drag.target: this
            drag.axis: Drag.XAxis

            onPressed: event => {
                startY = event.y;
                if (event.button === Qt.RightButton)
                    root.requestToggleExpand(!root.expanded);
                else if (event.button === Qt.MiddleButton)
                    modelData?.close();
            }
            onPositionChanged: event => {
                if (pressed && !root.expanded) {
                    const diffY = event.y - startY;
                    if (Math.abs(diffY) > Config.notifs.expandThreshold)
                        root.requestToggleExpand(diffY > 0);
                }
            }
            onReleased: event => {
                if (Math.abs(x) < width * Config.notifs.clearThreshold)
                    x = 0;
                else
                    modelData?.close();
            }

            ParallelAnimation {
                running: notif.modelData?.closed ?? false
                onFinished: notif.modelData?.unlock(notif)

                Anim {
                    target: notif
                    property: "opacity"
                    to: 0
                }
                Anim {
                    target: notif
                    property: "x"
                    to: notif.x >= 0 ? notif.width : -notif.width
                }
            }

            Notif {
                id: notifInner

                anchors.fill: parent
                modelData: notif.modelData
                props: root.props
                expanded: root.expanded
                visibilities: root.visibilities
            }

            Behavior on y {
                enabled: notif.LazyListView.ready

                Anim {
                    type: Anim.DefaultSpatial
                }
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on x {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }
    }

    TransformWatcher {
        id: tWatcher

        a: root.container.contentItem
        b: root
    }
}
