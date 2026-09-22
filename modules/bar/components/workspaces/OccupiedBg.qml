pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var workspaces
    required property int wsSpacing

    readonly property color colour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property color colourAnimated: colour

    readonly property bool isHorizontal: Config.bar.alignment === "top" || Config.bar.alignment === "bottom"

    Behavior on colourAnimated {
        CAnim {}
    }

    // Item wrappers because `layer.enabled` clips the content, and the rects extend 1px outside the parent
    Item {
        anchors.fill: parent
        anchors.margins: -1

        opacity: root.colourAnimated.a
        layer.enabled: opacity < 1 // Forces opacity to apply to children as a single layer

        Item {
            anchors.fill: parent
            anchors.margins: 1

            AnimatedRepeater {
                model: ScriptModel {
                    values: root.workspaces
                }

                removeDuration: Tokens.anim.durations.expressiveDefaultEffects
                delegate: OccupiedRect {}
            }
        }
    }

    component OccupiedRect: StyledRect {
        required property int index
        required property Workspace modelData

        readonly property bool isValid: modelData !== undefined && modelData !== null
        readonly property bool isOccupied: isValid ? modelData.isOccupied : false

        property real topRadius: ifAdjacent(0, -1, 0, root.isHorizontal ? height / 2 : width / 2)
        property real bottomRadius: ifAdjacent(root.workspaces.length - 1, 1, 0, root.isHorizontal ? height / 2 : width / 2)
        property real topPadding: ifAdjacent(0, -1, root.wsSpacing, 0)
        property real bottomPadding: ifAdjacent(root.workspaces.length - 1, 1, root.wsSpacing, 0)

        function ifAdjacent(exclIdx: int, adj: int, yes: real, no: real): real {
            if (AnimatedRepeater.adding || AnimatedRepeater.removing || !isOccupied || index === exclIdx)
                return no;
                
            const nextItem = root.workspaces[index + adj];
            return (nextItem && nextItem.isOccupied) ? yes : no;
        }

        anchors.left: root.isHorizontal ? undefined : parent?.left
        anchors.right: root.isHorizontal ? undefined : parent?.right
        anchors.top: root.isHorizontal ? parent?.top : undefined
        anchors.bottom: root.isHorizontal ? parent?.bottom : undefined
        anchors.margins: -1

        x: root.isHorizontal ? (isValid ? modelData.x + anchors.margins - topPadding : 0) : 0
        y: root.isHorizontal ? 0.0 : (isValid ? modelData.y + anchors.margins - topPadding : 0)

        implicitWidth: root.isHorizontal ? (isValid ? modelData.width - anchors.margins * 2 + topPadding + bottomPadding : 0) : 0
        implicitHeight: root.isHorizontal ? 0 : (isValid ? modelData.height - anchors.margins * 2 + topPadding + bottomPadding : 0)

        color: Qt.alpha(root.colour, 1)
        topLeftRadius: topRadius
        topRightRadius: root.isHorizontal ? bottomRadius : topRadius
        bottomLeftRadius: root.isHorizontal ? topRadius : bottomRadius
        bottomRightRadius: bottomRadius

        opacity: isOccupied ? 1 : 0

        Behavior on topRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on topPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
