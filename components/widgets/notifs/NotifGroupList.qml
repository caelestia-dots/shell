pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components

LazyListView {
    id: root

    required property list<var> notifs
    required property bool expanded
    required property bool expandable
    required property Flickable container
    required property color itemColour
    required property color buttonColour
    readonly property bool rowPressed: pressedRows > 0
    property int pressedRows

    signal requestExpand(expand: bool)
    signal swiped(notif: NotifData)
    signal linkActivated(notif: NotifData)

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: contentHeight

    spacing: Math.round(Tokens.spacing.extraSmall)
    asynchronous: true

    readyDelay: 1
    cacheBuffer: 400
    removeDuration: Tokens.anim.durations.normal

    useCustomViewport: true
    viewport: {
        CUtils.dependency(tWatcher.transform); // mapToItem is not reactive so use this to trigger updates
        return Qt.rect(0, container.contentY - mapToItem(container.contentItem, 0, 0).y, width, container.height);
    }

    model: ScriptModel {
        values: root.expanded ? root.notifs as Array : root.notifs.slice(0, root.Config.notifs.groupPreviewNum) as Array
    }

    delegate: Component {
        NotifSwipeArea {
            id: notif

            required property int index
            required property NotifData modelData

            Component.onCompleted: modelData.ref(this)
            Component.onDestruction: {
                if (pressed)
                    root.pressedRows--;
            }

            LazyListView.preferredHeight: LazyListView.removing ? 0 : notifInner.nonAnimHeight
            LazyListView.visibleHeight: LazyListView.removing ? 0 : notifInner.implicitHeight
            implicitHeight: notifInner.implicitHeight

            opacity: LazyListView.removing || LazyListView.adding ? 0 : 1
            scale: LazyListView.removing || LazyListView.adding ? 0.7 : 1

            expanded: root.expanded
            expandable: root.expandable
            dragExpand: false
            hoveringLink: !!notifInner.body?.hoveredLink
            enabled: root.expandable && root.expanded && !LazyListView.removing

            onPressedChanged: root.pressedRows += pressed ? 1 : -1
            onRequestExpand: expand => root.requestExpand(expand)
            onSwiped: root.swiped(modelData)
            onDismissed: modelData.dismiss()

            Connections {
                function onClosed(): void {
                    closeAnim.start();
                }

                target: notif.modelData
            }

            ParallelAnimation {
                id: closeAnim

                Anim {
                    type: Anim.DefaultEffects
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

            NotifItem {
                id: notifInner

                anchors.fill: parent
                modelData: notif.modelData
                expanded: root.expanded
                expandedColour: root.itemColour
                buttonColour: root.buttonColour
                onLinkActivated: root.linkActivated(notif.modelData)
            }

            Behavior on y {
                enabled: notif.LazyListView.ready

                Anim {}
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    TransformWatcher {
        id: tWatcher

        a: root.container.contentItem
        b: root
    }
}
