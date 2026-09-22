pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property string edge: Config.bar.alignment
    readonly property bool isHorizontal: edge === "top" || edge === "bottom"

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall

    property bool expanded

    readonly property real nonAnimSize: {
        const layoutSize = isHorizontal ? layout.implicitWidth : layout.implicitHeight;
        const expandSize = isHorizontal ? expandIcon.implicitWidth : expandIcon.implicitHeight;
        
        if (!Config.bar.tray.compact)
            return layoutSize + padding * 2;
            
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        if (expanded)
            return expandSize + layoutSize + spacing + pad;
        return Math.max(Config.bar.tray.background ? (isHorizontal ? height : width) : 0, expandSize + pad);
    }

    function isExactHit(lx: real, ly: real): bool {
        if (expandIcon.visible && lx >= expandIcon.x && lx <= expandIcon.x + expandIcon.width && ly >= expandIcon.y && ly <= expandIcon.y + expandIcon.height) {
            return true;
        }
        
        const itemX = lx - layout.x;
        const itemY = ly - layout.y;
        
        if (itemX >= 0 && itemY >= 0 && itemX <= layout.implicitWidth && itemY <= layout.implicitHeight) {
            let child = layout.childAt(itemX, itemY);
            if (child) return true;
        }
        return false;
    }

    clip: true
    visible: isHorizontal ? width > 0 : height > 0

    implicitWidth: isHorizontal ? nonAnimSize : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : nonAnimSize

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Flow {
        id: layout

        x: root.isHorizontal ? root.padding : (parent.width - implicitWidth) / 2
        y: root.isHorizontal ? (parent.height - implicitHeight) / 2 : root.padding
        
        flow: root.isHorizontal ? Flow.LeftToRight : Flow.TopToBottom
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
                values: SystemTray.items.values.filter(i => !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }
            delegate: TrayItem {}
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

        x: root.isHorizontal ? parent.width - width : (parent.width - width) / 2
        y: root.isHorizontal ? (parent.height - height) / 2 : parent.height - height

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: root.isHorizontal ? expandIconInner.implicitWidth - Tokens.padding.small : expandIconInner.implicitWidth
            implicitHeight: root.isHorizontal ? expandIconInner.implicitHeight : expandIconInner.implicitHeight - Tokens.padding.small

            MaterialIcon {
                id: expandIconInner

                x: root.isHorizontal ? parent.width - width - (Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small) : (parent.width - width) / 2
                y: root.isHorizontal ? (parent.height - height) / 2 : parent.height - height - (Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small)

                text: "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                
                rotation: {
                    if (root.edge === "top") return root.expanded ? 90 : -90;
                    if (root.edge === "bottom") return root.expanded ? -90 : 90;
                    if (root.edge === "left") return root.expanded ? 180 : 0;
                    return root.expanded ? 0 : 180;
                }

                Behavior on rotation {
                    Anim {}
                    }
                Behavior on x {
			        Anim {} 
		            }
                Behavior on y {
			        Anim {}
		            }
                }
            }
         }
                Behavior on implicitHeight {
                    Anim {}
                    }
                Behavior on implicitWidth {
                   Anim {}
                   }
                }