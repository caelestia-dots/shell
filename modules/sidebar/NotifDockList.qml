pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.config

Item {
    id: root

    required property Props props
    required property Flickable container
    required property DrawerVisibilities visibilities

    readonly property alias repeater: repeater
    readonly property int spacing: Appearance.spacing.small

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: groups.implicitHeight

    Column {
        id: groups

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Repeater {
            id: repeater

            model: ScriptModel {
                values: [...Notifs.sidebarGroupKeys]
            }

            delegate: NotifGroupDelegate {}
        }
    }

    component NotifGroupDelegate: MouseArea {
        id: notif

        required property int index
        required property string modelData

        readonly property bool closed: notifInner.notifCount === 0
        readonly property int topSpacing: index > 0 ? root.spacing : 0
        property int startY

        function closeAll(): void {
            Notifs.closeGroup(modelData);
        }

        containmentMask: QtObject {
            function contains(p: point): bool {
                if (!root.container.contains(notif.mapToItem(root.container, p)))
                    return false;
                return notifInner.contains(p);
            }
        }

        width: root.width
        height: closed ? 0 : notifInner.implicitHeight + topSpacing
        implicitWidth: width
        implicitHeight: height
        opacity: closed ? 0 : 1
        visible: !closed || opacity > 0

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

        Item {
            id: gap

            // Keep spacing inside the delegate so Column spacing does not leave holes while groups close.
            anchors.left: notif.left
            anchors.right: notif.right
            anchors.top: notif.top
            height: notif.topSpacing
        }

        NotifGroup {
            id: notifInner

            anchors.left: notif.left
            anchors.right: notif.right
            anchors.top: gap.bottom
            modelData: notif.modelData
            props: root.props
            container: root.container
            visibilities: root.visibilities
        }

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.large
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
