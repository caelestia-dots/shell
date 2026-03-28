pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.config

Item {
    id: root

    required property Props props
    required property list<var> notifs
    required property bool expanded
    required property Flickable container
    required property DrawerVisibilities visibilities

    readonly property real nonAnimHeight: notifColumn.implicitHeight
    readonly property int previewCount: Config.notifs.groupPreviewNum + 1
    readonly property int openNotifCount: root.notifs.filter(notif => !notif.closed).length
    readonly property int batchSize: 50
    readonly property real estimatedNotifHeight: Math.max(1, Config.notifs.sizes.image + Appearance.padding.normal * 2)
    readonly property real animationOverscan: root.container.height * 0.5
    readonly property int renderWindowSize: Math.max(root.previewCount, Math.ceil((root.container.height + root.animationOverscan) / root.estimatedNotifHeight))
    readonly property list<var> visibleNotifs: {
        if (root.previewCount <= 0 && !root.showAllNotifs)
            return [];

        if (root.showAllNotifs) {
            const visible = [];
            let openCount = 0;
            for (const notif of root.notifs) {
                if (!notif.closed) {
                    visible.push(notif);
                    openCount++;
                } else if (notif.locks.size > 0) {
                    // Keep locked closed items around just long enough to finish their close animation.
                    visible.push(notif);
                }

                if (openCount >= root.renderCount)
                    break;
            }
            return visible;
        }

        const preview = [];
        let openCount = 0;
        for (const notif of root.notifs) {
            if (!notif.closed) {
                preview.push(notif);
                openCount++;
            } else if (notif.locks.size > 0) {
                preview.push(notif);
            }

            if (openCount >= root.previewCount)
                break;
        }
        return preview;
    }

    readonly property int spacing: Math.round(Appearance.spacing.small / 2)
    property bool showAllNotifs
    property int renderCount: previewCount

    signal requestToggleExpand(expand: bool)

    function shouldLoadMore(): bool {
        if (!root.expanded || root.renderCount >= root.openNotifCount)
            return false;
        const top = root.mapToItem(root.container.contentItem, 0, 0).y;
        const bottom = root.mapToItem(root.container.contentItem, 0, root.height).y;
        const minY = root.container.contentY - root.animationOverscan;
        const maxY = root.container.contentY + root.container.height + root.animationOverscan;
        return bottom >= minY && top <= maxY && bottom <= maxY;
    }

    function maybeLoadMore(): void {
        if (root.shouldLoadMore() && !batchTimer.running)
            batchTimer.start();
    }

    onExpandedChanged: {
        if (expanded) {
            showAllNotifs = true;
            renderCount = Math.min(root.openNotifCount, root.renderWindowSize);
            Qt.callLater(root.maybeLoadMore);
        } else {
            batchTimer.stop();
            // Collapse back to the preview model immediately so the group shrinks
            // to its final collapsed height in one step.
            showAllNotifs = false;
            renderCount = previewCount;
        }
    }

    onNotifsChanged: {
        if (!expanded) {
            showAllNotifs = false;
            renderCount = previewCount;
        } else if (renderCount > root.openNotifCount) {
            renderCount = root.openNotifCount;
        } else if (expanded) {
            renderCount = Math.max(renderCount, Math.min(root.openNotifCount, root.renderWindowSize));
            Qt.callLater(root.maybeLoadMore);
        }
    }

    onYChanged: Qt.callLater(root.maybeLoadMore)

    Layout.fillWidth: true
    implicitHeight: nonAnimHeight

    Timer {
        id: batchTimer

        interval: 16
        repeat: true
        onTriggered: {
            // Grow very large groups in batches instead of instantiating the whole list at once.
            if (!root.shouldLoadMore()) {
                stop();
                return;
            }

            root.renderCount = Math.min(root.openNotifCount, root.renderCount + root.batchSize);
            if (root.renderCount >= root.openNotifCount)
                stop();
        }
    }

    Column {
        id: notifColumn

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Repeater {
            id: repeater

            model: ScriptModel {
                values: root.visibleNotifs
            }

            delegate: NotifDelegate {}
        }
    }

    Connections {
        function onContentYChanged(): void {
            root.maybeLoadMore();
        }

        function onHeightChanged(): void {
            root.maybeLoadMore();
        }

        target: root.container
    }

    component NotifDelegate: MouseArea {
        id: notif

        required property int index
        required property NotifData modelData

        readonly property alias nonAnimHeight: notifInner.nonAnimHeight
        readonly property int topSpacing: index > 0 ? root.spacing : 0
        readonly property bool animationsEnabled: {
            const pos = notif.mapToItem(root.container.contentItem, 0, 0);
            const top = pos.y;
            const itemHeight = Math.max(notif.height, notif.nonAnimHeight);
            const bottom = top + itemHeight;
            const minY = root.container.contentY - root.animationOverscan;
            const maxY = root.container.contentY + root.container.height + root.animationOverscan;
            return bottom >= minY && top <= maxY;
        }
        property int startY

        containmentMask: QtObject {
            function contains(p: point): bool {
                if (!root.container.contains(notif.mapToItem(root.container, p)))
                    return false;
                return notifInner.contains(p);
            }
        }

        width: root.width
        // Size the list from the notification's target height so the group can expand
        // immediately instead of waiting for every child height animation to settle.
        height: modelData.closed ? 0 : notifInner.nonAnimHeight + topSpacing
        implicitWidth: width
        implicitHeight: height
        opacity: modelData.closed ? 0 : 1
        visible: !modelData.closed || opacity > 0

        hoverEnabled: true
        cursorShape: notifInner.body?.hoveredLink ? Qt.PointingHandCursor : pressed ? Qt.ClosedHandCursor : undefined
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: !root.expanded
        enabled: !modelData.closed

        drag.target: this
        drag.axis: Drag.XAxis

        onPressed: event => {
            startY = event.y;
            if (event.button === Qt.RightButton)
                root.requestToggleExpand(!root.expanded);
            else if (event.button === Qt.MiddleButton)
                modelData.close();
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
                modelData.close();
        }

        onModelDataChanged: {
            if (modelData?.closed)
                closeCleanupTimer.start();
        }

        Component.onCompleted: modelData.lock(this)
        Component.onDestruction: modelData.unlock(this)

        Connections {
            function onClosedChanged(): void {
                if (notif.modelData.closed) {
                    notif.x = notif.x >= 0 ? notif.width : -notif.width;
                    if (notif.animationsEnabled)
                        closeCleanupTimer.restart();
                    else
                        notif.modelData.unlock(notif);
                }
            }

            target: notif.modelData
        }

        Timer {
            id: closeCleanupTimer

            interval: Math.max(Appearance.anim.durations.large, Appearance.anim.durations.expressiveDefaultSpatial)
            onTriggered: notif.modelData.unlock(notif)
        }

        Item {
            id: gap

            // Keep spacing inside the delegate so Column spacing does not leave holes while items close.
            anchors.left: notif.left
            anchors.right: notif.right
            anchors.top: notif.top
            height: notif.topSpacing
        }

        Notif {
            id: notifInner

            anchors.left: notif.left
            anchors.right: notif.right
            anchors.top: gap.bottom
            modelData: notif.modelData
            props: root.props
            expanded: root.expanded
            animationsEnabled: notif.animationsEnabled
            visibilities: root.visibilities
        }

        Behavior on height {
            enabled: notif.animationsEnabled

            Anim {
                duration: Appearance.anim.durations.large
            }
        }

        Behavior on opacity {
            enabled: notif.animationsEnabled

            Anim {}
        }

        Behavior on x {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }
}
