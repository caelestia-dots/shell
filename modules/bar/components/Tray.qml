pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property bool isHorizontal: false

    readonly property alias layout: layout

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall

    property bool expanded

    readonly property real nonAnimAlong: {
        if (!Config.bar.tray.compact)
            return (isHorizontal ? layout.implicitWidth : layout.implicitHeight) + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        const expandSize = isHorizontal ? expandIcon.implicitWidth : expandIcon.implicitHeight;
        const layoutSize = isHorizontal ? layout.implicitWidth : layout.implicitHeight;
        if (expanded)
            return expandSize + layoutSize + spacing + pad;
        return Math.max(Config.bar.tray.background ? Tokens.sizes.bar.innerWidth : 0, expandSize + pad);
    }

    clip: true
    visible: (isHorizontal ? width : height) > 0

    implicitWidth: isHorizontal ? nonAnimAlong : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : nonAnimAlong

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Grid {
        id: layout

        rows: root.isHorizontal ? 1 : Math.max(1, items.count)
        columns: root.isHorizontal ? Math.max(1, items.count) : 1

        anchors.centerIn: Config.bar.tray.compact ? undefined : parent
        anchors.right: Config.bar.tray.compact && root.isHorizontal ? expandIcon.left : undefined
        anchors.rightMargin: Config.bar.tray.compact && root.isHorizontal ? root.spacing : 0
        anchors.bottom: Config.bar.tray.compact && !root.isHorizontal ? expandIcon.top : undefined
        anchors.bottomMargin: Config.bar.tray.compact && !root.isHorizontal ? root.spacing : 0
        anchors.verticalCenter: Config.bar.tray.compact && root.isHorizontal ? parent.verticalCenter : undefined
        anchors.horizontalCenter: Config.bar.tray.compact && !root.isHorizontal ? parent.horizontalCenter : undefined
        spacing: Tokens.spacing.small

        opacity: root.expanded || !Config.bar.tray.compact ? 1 : 0
        visible: opacity > 0

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
        anchors.bottom: root.isHorizontal ? undefined : parent.bottom
        anchors.right: root.isHorizontal ? parent.right : undefined

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: expandIconInner.implicitWidth
            implicitHeight: expandIconInner.implicitHeight - Tokens.padding.small

            MaterialIcon {
                id: expandIconInner

                anchors.centerIn: parent
                text: root.isHorizontal ? "chevron_left" : "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
