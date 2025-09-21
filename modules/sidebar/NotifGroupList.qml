pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Props props
    required property list<var> notifs
    required property bool expanded
    required property Flickable container
    required property var visibilities

    readonly property real nonAnimHeight: {
        let h = -root.spacing;
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (!item.modelData.closed && !item.previewHidden)
                h += item.nonAnimHeight + root.spacing;
        }
        return h;
    }

    readonly property int spacing: Math.round(Appearance.spacing.small / 2)
    property bool showAllNotifs
    property bool flag

    signal requestToggleExpand(expand: bool)

    onExpandedChanged: {
        if (expanded) {
            clearTimer.stop();
            showAllNotifs = true;
        } else {
            clearTimer.start();
        }
    }

    Layout.fillWidth: true
    implicitHeight: nonAnimHeight

    Timer {
        id: clearTimer

        interval: Appearance.anim.durations.normal
        onTriggered: root.showAllNotifs = false
    }

    Repeater {
        id: repeater

        model: ScriptModel {
            values: root.showAllNotifs ? root.notifs : root.notifs.slice(0, Config.notifs.groupPreviewNum + 1)
            onValuesChanged: root.flagChanged()
        }

        MouseArea {
            id: notif

            required property int index
            required property Notifs.Notif modelData

            readonly property alias nonAnimHeight: notifInner.nonAnimHeight
            readonly property bool previewHidden: {
                if (root.expanded)
                    return false;

                let extraHidden = 0;
                for (let i = 0; i < index; i++)
                    if (root.notifs[i].closed)
                        extraHidden++;

                return index >= Config.notifs.groupPreviewNum + extraHidden;
            }
            property int startY

            y: {
                root.flag; // Force update
                let y = 0;
                for (let i = 0; i < index; i++) {
                    const item = repeater.itemAt(i);
                    if (!item.modelData.closed && !item.previewHidden)
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

            opacity: previewHidden ? 0 : 1
            scale: previewHidden ? 0.7 : 1

            implicitWidth: root.width
            implicitHeight: notifInner.implicitHeight

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

            Component.onCompleted: modelData.lock(this)
            Component.onDestruction: modelData.unlock(this)

            ParallelAnimation {
                Component.onCompleted: running = !notif.previewHidden

                Anim {
                    target: notif
                    property: "opacity"
                    from: 0
                    to: 1
                }
                Anim {
                    target: notif
                    property: "scale"
                    from: 0.7
                    to: 1
                }
            }

            ParallelAnimation {
                running: notif.modelData.closed
                onFinished: notif.modelData.unlock(notif)

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

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
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

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }
}
