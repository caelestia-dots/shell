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

    readonly property list<var> notifs: [...group.notifs]
    readonly property list<color> surfaces: [Colours.palette.surfaceContainer, Colours.palette.surfaceContainerHigh, Colours.palette.surfaceContainerHighest]
    readonly property int nonAnimHeight: {
        const headerHeight = header.implicitHeight + (root.expanded ? Math.round(Tokens.spacing.extraSmall) : 0);
        const columnHeight = headerHeight + notifList.layoutHeight;
        return Math.round(Math.max(TokenConfig.sizes.notifs.image, columnHeight) + Tokens.padding.medium * 2);
    }

    signal requestExpand(expand: bool)
    signal swiped(notif: NotifData)
    signal linkActivated(notif: NotifData)

    function surface(offset: int, layer: int): color {
        return Colours.layer(surfaces[Math.min(baseSurface + offset, surfaces.length - 1)], layer);
    }

    Component.onCompleted: group.ref(this)

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: nonAnimHeight

    clip: true
    radius: Tokens.rounding.large
    color: group.urgency === NotifData.Critical ? Colours.palette.secondaryContainer : surface(0, 2)

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
            image: root.group.image
            icon: root.group.icon
            urgency: root.group.urgency
            lowFillColour: root.surface(1, 3)
            summary: root.notifs[0]?.summary ?? ""
            progress: (root.notifs[0]?.hints.value ?? 0) / 100
        }

        Column {
            Layout.fillWidth: true
            spacing: root.expanded ? Math.round(Tokens.spacing.extraSmall) : 0

            Behavior on spacing {
                Anim {}
            }

            NotifGroupHeader {
                id: header

                anchors.left: parent.left
                anchors.right: parent.right
                appName: root.group.appName
                timeStr: root.notifs[0]?.timeStr ?? ""
                count: root.notifs.length
                urgency: root.group.urgency
                pillColour: root.surface(1, 3)
                expandable: root.expandable
                expanded: root.expanded
                onToggle: root.requestExpand(!root.expanded)
            }

            NotifGroupList {
                id: notifList

                notifs: root.notifs
                expanded: root.expanded
                expandable: root.expandable
                container: root.container
                itemColour: root.surface(1, 3)
                buttonColour: root.surface(2, 4)
                onRequestExpand: expand => root.requestExpand(expand)
                onSwiped: notif => root.swiped(notif)
                onLinkActivated: notif => root.linkActivated(notif)
            }
        }
    }
}
