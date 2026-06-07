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

    required property DrawerVisibilities visibilities
    required property Item osdPanel
    required property Item sessionPanel
    required property Item utilitiesPanel
    readonly property int padding: Tokens.padding.large
    readonly property int clampedPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    implicitWidth: Tokens.sizes.notifs.width
    implicitHeight: {
        const count = list.count;
        if (count === 0)
            return 0;

        let height = (count - 1) * Tokens.spacing.medium;
        for (let i = 0; i < count; i++)
            height += (list.itemAtIndex(i) as NotifWrapper)?.nonAnimHeight ?? 0;

        if (visibilities.osd) {
            const h = osdPanel.y - clampedPadding;
            if (height > h)
                height = h;
        }

        if (visibilities.session) {
            const h = sessionPanel.y - clampedPadding;
            if (height > h)
                height = h;
        }

        if (visibilities.utilities) {
            const h = ((QsWindow.window as QsWindow)?.screen.height ?? 0) - (utilitiesPanel as Utilities.Wrapper).nonAnimHeight - Config.border.thickness * 2 - padding * 2 - Tokens.spacing.extraLarge;
            if (height > h)
                height = h;
        }

        return Math.min(((QsWindow.window as QsWindow)?.screen?.height ?? 0) + padding - clampedPadding * 2 - Config.border.thickness, height + padding + clampedPadding);
    }

    ClippingWrapperRectangle {
        anchors.fill: parent
        anchors.margins: root.padding
        anchors.topMargin: root.clampedPadding
        anchors.rightMargin: root.clampedPadding

        color: "transparent"
        radius: Tokens.rounding.large

        StyledListView {
            id: list

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
                extra: {
                    const count = list.count;
                    if (count === 0)
                        return 0;

                    const scrollY = list.contentY;

                    let height = 0;
                    for (let i = 0; i < count; i++) {
                        height += ((list.itemAtIndex(i) as NotifWrapper)?.nonAnimHeight ?? 0) + Tokens.spacing.medium;

                        if (height - Tokens.spacing.medium >= scrollY)
                            return i;
                    }

                    return count;
                }
            }

            ExtraIndicator {
                anchors.bottom: parent.bottom
                extra: {
                    const count = list.count;
                    if (count === 0)
                        return 0;

                    const scrollY = list.contentHeight - (list.contentY + list.height);

                    let height = 0;
                    for (let i = count - 1; i >= 0; i--) {
                        height += ((list.itemAtIndex(i) as NotifWrapper)?.nonAnimHeight ?? 0) + Tokens.spacing.medium;

                        if (height - Tokens.spacing.medium >= scrollY)
                            return count - i - 1;
                    }

                    return 0;
                }
            }
        }
    }

    Behavior on implicitHeight {
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
