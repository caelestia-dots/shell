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
    required property bool horizontal

    readonly property color colour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property color colourAnimated: colour

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

                OccupiedRect {}
            }
        }
    }

    component OccupiedRect: StyledRect {
        required property int index
        required property Workspace modelData

        // Leading edge is top (vertical) or left (horizontal), trailing is bottom/right.
        // Padded edges flow into the gap to the neighbouring workspace.
        property real leadRadius: ifAdjacent(0, -1, 0, armRadius)
        property real trailRadius: ifAdjacent(root.workspaces.length - 1, 1, 0, armRadius)
        property real leadPadding: ifAdjacent(0, -1, root.wsSpacing, 0)
        property real trailPadding: ifAdjacent(root.workspaces.length - 1, 1, root.wsSpacing, 0)
        readonly property real armRadius: root.horizontal ? height / 2 : width / 2

        function ifAdjacent(exclIdx: int, adj: int, yes: real, no: real): real {
            if (AnimatedRepeater.adding || AnimatedRepeater.removing || !modelData?.isOccupied || index === exclIdx)
                return no;
            return root.workspaces[index + adj]?.isOccupied ? yes : no;
        }

        x: root.horizontal ? modelData.x - 1 - leadPadding : -1
        y: root.horizontal ? -1 : modelData.y - 1 - leadPadding
        width: root.horizontal ? modelData.LazyListView.visibleWidth + 2 + leadPadding + trailPadding : parent.width + 2
        implicitHeight: root.horizontal ? parent.height + 2 : modelData.LazyListView.visibleHeight + 2 + leadPadding + trailPadding

        color: Qt.alpha(root.colour, 1)
        topLeftRadius: leadRadius
        topRightRadius: trailRadius
        bottomLeftRadius: leadRadius
        bottomRightRadius: trailRadius

        opacity: modelData?.isOccupied ? 1 : 0

        Behavior on topLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on topRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on leadPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on trailPadding {
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