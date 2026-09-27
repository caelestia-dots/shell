pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.widgets
import qs.services
import qs.modules.utilities as Utilities

Item {
    id: root

    required property ScreenState screenState
    required property real availableHeight
    required property bool mirrored
    required property bool utilitiesOnTop
    required property Item osdPanel
    required property Item sessionPanel
    required property Item utilitiesPanel
    readonly property int padding: Tokens.padding.large
    readonly property int clampedPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)

    // Only content changes invalidate the delegate-height sum.
    readonly property real naturalHeight: {
        const count = list.count;
        if (count === 0)
            return 0;

        let height = (count - 1) * Tokens.spacing.medium;
        for (const child of list.contentItem.children) {
            const wrapper = child as NotifWrapper;
            if (wrapper && wrapper.index >= 0)
                height += wrapper.nonAnimHeight;
        }

        return height + padding + clampedPadding;
    }
    readonly property real maximumHeight: {
        let height = Infinity;

        if (screenState.osd) {
            const h = osdPanel.y - (root.parent.y + root.y) - clampedPadding;
            if (height > h)
                height = h;
        }

        if (screenState.session) {
            const h = sessionPanel.y - (root.parent.y + root.y) - clampedPadding;
            if (height > h)
                height = h;
        }

        if (screenState.utilities && !utilitiesOnTop) {
            const h = availableHeight - (utilitiesPanel as Utilities.Wrapper).nonAnimHeight - padding * 2 - Tokens.spacing.extraLarge;
            if (height > h)
                height = h;
        }

        return Math.max(0, Math.min(utilitiesOnTop ? availableHeight : availableHeight + padding - clampedPadding * 2 + Config.border.thickness, height + padding + clampedPadding));
    }
    property real desiredHeight: Math.min(naturalHeight, maximumHeight)

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: mirrored ? parent.left : undefined
    anchors.right: mirrored ? undefined : parent.right

    clip: true
    implicitWidth: Tokens.sizes.notifs.width
    // The moving viewport must constrain every animation frame, not just its target.
    implicitHeight: Math.max(0, Math.min(desiredHeight, maximumHeight))

    ClippingWrapperRectangle {
        anchors.fill: parent
        anchors.margins: root.padding
        anchors.topMargin: Math.min(root.clampedPadding, root.height)
        anchors.bottomMargin: Math.min(root.padding, Math.max(0, root.height - anchors.topMargin))
        anchors.leftMargin: root.mirrored ? root.clampedPadding : root.padding
        anchors.rightMargin: root.mirrored ? root.padding : root.clampedPadding

        color: "transparent"
        radius: Tokens.rounding.large

        StyledListView {
            id: list

            // Delegate positions include the ListView origin and animated layout.
            readonly property point visibleIndices: {
                const count = list.count;
                if (count === 0 || list.height <= 0)
                    return Qt.point(0, -1);

                const top = list.contentY;
                const bottom = top + list.height;
                let first = count;
                let last = -1;
                for (const child of list.contentItem.children) {
                    const wrapper = child as NotifWrapper;
                    if (!wrapper || wrapper.index < 0 || wrapper.index >= count || !wrapper.visible || wrapper.height <= 0)
                        continue;

                    if (wrapper.y + wrapper.height > top)
                        first = Math.min(first, wrapper.index);
                    if (wrapper.y + (wrapper.idx === 0 ? 0 : Tokens.spacing.medium) < bottom)
                        last = Math.max(last, wrapper.index);
                }

                // A viewport inside spacing can contain no notification pixels.
                return Qt.point(first, Math.max(first - 1, last));
            }

            model: ScriptModel {
                values: Notifs.popups.filter(n => !n.closed)
            }

            anchors.fill: parent

            orientation: Qt.Vertical
            spacing: 0
            cacheBuffer: (QsWindow.window as QsWindow)?.screen.height ?? 0

            delegate: NotifWrapper {}

            move: Transition {
                Anim {
                    property: "y"
                }
            }

            displaced: Transition {
                Anim {
                    property: "y"
                }
            }

            ExtraIndicator {
                anchors.top: parent.top
                extra: list.visibleIndices.x
            }

            ExtraIndicator {
                anchors.bottom: parent.bottom
                extra: list.count - list.visibleIndices.y - 1
            }
        }
    }

    Behavior on desiredHeight {
        Anim {}
    }

    component NotifWrapper: Item {
        id: wrapper

        required property NotifData modelData
        required property int index
        readonly property alias nonAnimHeight: notif.nonAnimHeight
        property int idx

        onIndexChanged: {
            if (index !== -1)
                idx = index;
        }

        implicitWidth: notif.implicitWidth
        implicitHeight: notif.implicitHeight + (idx === 0 ? 0 : Tokens.spacing.medium)

        ListView.onRemove: removeAnim.start()

        SequentialAnimation {
            id: removeAnim

            PropertyAction {
                target: wrapper
                property: "ListView.delayRemove"
                value: true
            }
            PropertyAction {
                target: wrapper
                property: "enabled"
                value: false
            }
            PropertyAction {
                target: wrapper
                property: "implicitHeight"
                value: 0
            }
            PropertyAction {
                target: wrapper
                property: "z"
                value: 1
            }
            Anim {
                target: notif
                property: "x"
                to: (notif.x >= 0 ? root.implicitWidth : -root.implicitWidth) * 2
                duration: Tokens.anim.durations.normal
                easing: Tokens.anim.emphasized
            }
            PropertyAction {
                target: wrapper
                property: "ListView.delayRemove"
                value: false
            }
        }

        ClippingRectangle {
            anchors.top: parent.top
            anchors.topMargin: wrapper.idx === 0 ? 0 : Tokens.spacing.medium

            color: "transparent"
            radius: notif.radius
            implicitWidth: notif.implicitWidth
            implicitHeight: notif.implicitHeight

            Notification {
                id: notif

                modelData: wrapper.modelData
                implicitWidth: root.implicitWidth - root.padding - root.clampedPadding
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Tokens.anim.durations.expressiveDefaultSpatial
        easing: Tokens.anim.expressiveDefaultSpatial
    }
}
