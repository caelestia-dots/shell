pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property bool horizontal
    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall
    readonly property int edgeMargin: Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small

    property bool expanded

    readonly property real nonAnimWidth: {
        if (!horizontal)
            return Tokens.sizes.bar.innerWidth;
        if (!Config.bar.tray.compact)
            return layout.implicitWidth + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        if (expanded)
            return expandIcon.implicitWidth + layout.implicitWidth + spacing + pad;
        return Math.max(Config.bar.tray.background ? height : 0, expandIcon.implicitWidth + pad);
    }
    readonly property real nonAnimHeight: {
        if (horizontal)
            return Tokens.sizes.bar.innerWidth;
        if (!Config.bar.tray.compact)
            return layout.implicitHeight + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        if (expanded)
            return expandIcon.implicitHeight + layout.implicitHeight + spacing + pad;
        return Math.max(Config.bar.tray.background ? width : 0, expandIcon.implicitHeight + pad);
    }

    clip: true
    visible: horizontal ? width > 0 : height > 0

    implicitWidth: horizontal ? nonAnimWidth : Tokens.sizes.bar.innerWidth
    implicitHeight: horizontal ? Tokens.sizes.bar.innerWidth : nonAnimHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Grid {
        id: layout

        x: root.horizontal ? root.padding : (parent.width - width) / 2
        y: root.horizontal ? (parent.height - height) / 2 : root.padding

        columns: root.horizontal ? Math.max(1, items.count) : 1
        spacing: Tokens.spacing.small

        opacity: root.expanded || !Config.bar.tray.compact ? 1 : 0

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

        x: root.horizontal ? parent.width - width : (parent.width - width) / 2
        y: root.horizontal ? (parent.height - height) / 2 : parent.height - height

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: root.horizontal ? expandIconInner.implicitWidth - Tokens.padding.small : expandIconInner.implicitWidth
            implicitHeight: root.horizontal ? expandIconInner.implicitHeight : expandIconInner.implicitHeight - Tokens.padding.small

            MaterialIcon {
                id: expandIconInner

                x: root.horizontal ? parent.width - width - root.edgeMargin : (parent.width - width) / 2
                y: root.horizontal ? (parent.height - height) / 2 : parent.height - height - root.edgeMargin
                text: "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: (root.horizontal ? 270 : 0) + (root.expanded ? 180 : 0)

                Behavior on rotation {
                    Anim {}
                }

                Behavior on x {
                    enabled: root.horizontal

                    Anim {}
                }

                Behavior on y {
                    enabled: !root.horizontal

                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    Behavior on implicitWidth {
        enabled: root.horizontal

        Anim {}
    }
}
