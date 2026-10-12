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
    property bool isHorizontal: false

    readonly property color colour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property color colourAnimated: colour

    Behavior on colourAnimated {
        CAnim {}
    }

    Item {
        anchors.fill: parent
        anchors.margins: -1

        opacity: root.colourAnimated.a
        layer.enabled: opacity < 1

        Item {
            anchors.fill: parent
            anchors.margins: 1

            AnimatedRepeater {
                model: ScriptModel {
                    values: root.workspaces
                }

                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

                OccupiedRect {}
            }
        }
    }

    component OccupiedRect: StyledRect {
        required property int index
        required property Workspace modelData

        property real startRadius: ifAdjacent(0, -1, 0, (root.isHorizontal ? height : width) / 2)
        property real endRadius: ifAdjacent(root.workspaces.length - 1, 1, 0, (root.isHorizontal ? height : width) / 2)
        property real startPadding: ifAdjacent(0, -1, root.wsSpacing, 0)
        property real endPadding: ifAdjacent(root.workspaces.length - 1, 1, root.wsSpacing, 0)

        function ifAdjacent(exclIdx: int, adj: int, yes: real, no: real): real {
            if (AnimatedRepeater.adding || AnimatedRepeater.removing || !modelData?.isOccupied || index === exclIdx)
                return no;
            return root.workspaces[index + adj]?.isOccupied ? yes : no;
        }

        anchors.left: root.isHorizontal ? undefined : parent?.left
        anchors.right: root.isHorizontal ? undefined : parent?.right
        anchors.top: root.isHorizontal ? parent?.top : undefined
        anchors.bottom: root.isHorizontal ? parent?.bottom : undefined
        anchors.margins: -1

        x: root.isHorizontal ? (modelData ? modelData.x + anchors.margins - startPadding : 0) : 0
        y: !root.isHorizontal ? (modelData ? modelData.y + anchors.margins - startPadding : 0) : 0

        implicitWidth: root.isHorizontal ? (modelData ? modelData.width - anchors.margins * 2 + startPadding + endPadding : 0) : 0
        implicitHeight: !root.isHorizontal ? (modelData ? modelData.visibleLength - anchors.margins * 2 + startPadding + endPadding : 0) : 0

        color: Qt.alpha(root.colour, 1)

        topLeftRadius: startRadius
        bottomLeftRadius: root.isHorizontal ? startRadius : endRadius
        topRightRadius: root.isHorizontal ? endRadius : startRadius
        bottomRightRadius: endRadius

        opacity: modelData?.isOccupied ? 1 : 0

        Behavior on startRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on endRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on startPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on endPadding {
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
