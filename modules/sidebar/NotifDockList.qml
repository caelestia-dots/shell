pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.widgets.notifs
import qs.services

LazyListView {
    id: root

    required property Props props
    required property Flickable container
    required property ScreenState screenState

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: contentHeight

    spacing: Tokens.spacing.small
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

    removeDuration: Tokens.anim.durations.normal

    model: ScriptModel {
        values: [...Notifs.groups]
    }

    delegate: Component {
        NotifSwipeArea {
            id: notif

            required property int index
            required property NotifGroup modelData

            readonly property bool closed: card.notifs.length === 0

            function toggleExpand(expand: bool): void {
                if (expand) {
                    if (!expanded)
                        root.props.expandedNotifs.push(modelData.appName);
                } else if (expanded) {
                    root.props.expandedNotifs.splice(root.props.expandedNotifs.indexOf(modelData.appName), 1);
                }
            }

            function closeAll(): void {
                clearTimer.start();
            }

            Component.onDestruction: {
                if (closed && expanded)
                    toggleExpand(false);
            }

            LazyListView.trackViewport: !expanded && card.nonAnimHeight < card.implicitHeight
            LazyListView.preferredHeight: closed ? 0 : card.nonAnimHeight
            LazyListView.visibleHeight: card.implicitHeight
            implicitHeight: card.implicitHeight

            opacity: LazyListView.removing || closed || LazyListView.adding ? 0 : 1
            scale: LazyListView.removing || closed ? 0.6 : LazyListView.adding ? 0 : 1

            expanded: root.props.expandedNotifs.includes(modelData.appName)
            enabled: !closed

            onRequestExpand: expand => toggleExpand(expand)
            onSwiped: closeAll()
            onDismissed: closeAll()

            Timer {
                id: clearTimer

                interval: 15
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    const notifs = [...notif.modelData.notifs];
                    if (notifs.length === 0) {
                        stop();
                        return;
                    }

                    for (const n of notifs.slice(0, 30))
                        n.dismiss();
                }
            }

            NotifGroupCard {
                id: card

                group: notif.modelData
                container: root.container
                expanded: notif.expanded
                baseSurface: 1
                onRequestExpand: expand => notif.toggleExpand(expand)
                onSwiped: notif => notif.dismiss()
                onLinkActivated: root.screenState.sidebar = false
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

    Anim {
        id: contentYAnim

        target: root.container
        property: "contentY"
    }
}
