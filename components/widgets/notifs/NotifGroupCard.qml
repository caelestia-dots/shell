pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Models
import Caelestia.Scheme
import qs.components

StyledRect {
    id: root

    required property NotifGroup group
    required property Flickable container
    required property bool expanded
    property bool expandable: true
    property int baseSurface: 0
    property int baseLayer: baseSurface

    readonly property list<var> notifs: [...group.notifs]
    readonly property bool single: notifs.length === 1
    readonly property alias rowPressed: notifList.rowPressed
    readonly property list<color> surfaces: [Colours.palette.surfaceContainer, Colours.palette.surfaceContainerHigh, Colours.palette.surfaceContainerHighest]
    readonly property int nonAnimHeight: {
        const headerHeight = header.implicitHeight + (expanded ? Tokens.spacing.extraSmall : 0);
        const columnHeight = headerHeight + notifList.layoutHeight;
        return Math.round(Math.max(TokenConfig.sizes.notifs.image, columnHeight) + Tokens.padding.medium * 2);
    }

    signal requestExpand(expand: bool)
    signal swiped(notif: NotifData)
    signal linkActivated(notif: NotifData)

    function surface(offset: int, layer: int): color {
        return Colours.layer(surfaces[Math.min(baseSurface + offset, surfaces.length - 1)], baseLayer + layer);
    }

    Component.onCompleted: group.ref(this)

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: nonAnimHeight

    clip: true
    radius: Tokens.rounding.large
    color: !expanded && group.urgency === NotifData.Critical ? Colours.palette.secondaryContainer : surface(0, 1)

    Behavior on implicitHeight {
        Anim {}
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.medium

        NotifAvatar {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.topMargin: root.expanded && !root.single ? header.implicitHeight + Tokens.spacing.extraSmall + Tokens.padding.extraSmall : 0
            image: root.expanded ? root.notifs[0]?.image ?? "" : root.group.image
            icon: root.expanded ? root.notifs[0]?.appIcon ?? "" : root.group.icon
            urgency: root.expanded ? root.notifs[0]?.urgency ?? NotifData.Normal : root.group.urgency
            lowFillColour: root.surface(1, 2)
            summary: root.notifs[0]?.summary ?? ""
            progress: (root.notifs[0]?.hints.value ?? 0) / 100

            Behavior on Layout.topMargin {
                Anim {}
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: root.expanded ? Tokens.spacing.extraSmall : 0

            Behavior on spacing {
                Anim {}
            }

            NotifGroupHeader {
                id: header

                anchors.left: parent.left
                anchors.right: parent.right
                appName: root.group.appName
                single: root.single
                timeStr: root.notifs[0]?.timeStr ?? ""
                count: root.notifs.length
                urgency: root.group.urgency
                pillColour: root.surface(1, 2)
                expandable: root.expandable
                expanded: root.expanded
                onToggle: root.requestExpand(!root.expanded)
            }

            NotifGroupList {
                id: notifList

                notifs: root.notifs
                expanded: root.expanded
                single: root.single
                headerHeight: header.implicitHeight
                headerTitleWidth: header.titleWidth
                expandable: root.expandable
                container: root.container
                itemColour: root.surface(1, 2)
                buttonColour: root.surface(2, 3)
                onRequestExpand: expand => root.requestExpand(expand)
                onSwiped: notif => root.swiped(notif)
                onLinkActivated: notif => root.linkActivated(notif)
            }
        }
    }
}
