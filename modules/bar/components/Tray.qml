pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property var popouts

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall

    property bool expanded

    readonly property real nonAnimHeight: {
        if (items.count === 0)
            return 0;
        if (!Config.bar.tray.compact)
            return layout.implicitHeight + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        if (expanded)
            return expandIcon.implicitHeight + layout.implicitHeight + spacing + pad;
        return Math.max(Config.bar.tray.background ? width : 0, expandIcon.implicitHeight + pad);
    }

    clip: true
    visible: height > 0

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: nonAnimHeight

    color: (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer : "transparent"
    radius: Tokens.rounding.full

    Column {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.padding
        // Fixed width so differently padded tray glyphs stay horizontally centered
        width: root.width
        spacing: Config.bar.tray.background ? Tokens.spacing.medium / 2 : Tokens.spacing.small

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
                // Keep Passive items (e.g. idle Teams/Electron apps); only honour explicit hides.
                values: SystemTray.items.values.filter(i => !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {
                anchors.horizontalCenter: parent.horizontalCenter
                popouts: root.popouts
            }
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

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: expandIconInner.implicitWidth
            implicitHeight: expandIconInner.implicitHeight - Tokens.padding.small

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small
                text: "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
