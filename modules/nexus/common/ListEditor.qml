pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

ListView {
    id: root

    property alias values: valuesModel.values
    property bool first

    signal itemMoved(from: int, to: int)
    signal itemRemoved(index: int)
    signal editItem(item: var)

    function labelFor(item: var): string {
        return item.label;
    }

    function canEdit(item: var): bool {
        return false;
    }

    function dampOvershoot(overshoot: real, maxOvershoot: real): real {
        return overshoot / (1 + overshoot / maxOvershoot);
    }

    Layout.fillWidth: true
    implicitHeight: contentHeight

    spacing: Tokens.spacing.extraSmall / 2
    interactive: false

    model: DelegateModel {
        id: visualModel

        model: ScriptModel {
            id: valuesModel
        }

        delegate: ListRow {}
    }

    add: Transition {
        Anim {
            properties: "opacity"
            type: Anim.DefaultEffects
            from: 0
            to: 1
        }
    }

    remove: Transition {
        Anim {
            properties: "opacity"
            type: Anim.DefaultEffects
            to: 0
        }
    }

    move: Transition {
        Anim {
            properties: "opacity"
            type: Anim.DefaultEffects
            to: 1
        }
        Anim {
            properties: "y"
        }
    }

    displaced: Transition {
        Anim {
            properties: "opacity"
            type: Anim.DefaultEffects
            to: 1
        }
        Anim {
            properties: "y"
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component ListRow: Item {
        id: item

        required property var modelData
        property bool held
        property point pressPos
        property int pressIndex
        property real lastMoveY

        property real topRadius: root?.first && DelegateModel.itemsIndex === 0 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
        property real radiusLerpProg

        function lerpRadius(a: real, b: real): real {
            return a + (b - a) * radiusLerpProg;
        }

        anchors.left: root?.contentItem.left
        anchors.right: root?.contentItem.right
        implicitHeight: row.implicitHeight + row.anchors.margins * 2
        z: held || returnAnim.running ? 1 : 0

        state: held ? "held" : ""

        states: State {
            name: "held"

            PropertyChanges {
                item.radiusLerpProg: 1
                placeholder.opacity: 0.1
                elevation.opacity: 1
                itemBg.color: Colours.palette.m3tertiaryContainer
                dragIcon.color: Colours.palette.m3onTertiaryContainer
                label.color: Colours.palette.m3onTertiaryContainer
                editButton.inactiveOnColour: Colours.palette.m3onTertiaryContainer
                deleteButton.inactiveOnColour: Colours.palette.m3onError
            }
        }

        transitions: Transition {
            Anim {
                properties: "opacity,radiusLerpProg"
                type: Anim.SlowEffects
            }
            PropertyAction {
                properties: "color,inactiveOnColour"
            }
        }

        Behavior on topRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        StyledRect {
            id: placeholder

            anchors.fill: parent
            color: Colours.palette.m3tertiaryContainer
            radius: Tokens.rounding.extraSmall
            topLeftRadius: item.topRadius
            topRightRadius: item.topRadius
            opacity: 0
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            preventStealing: true

            onPressed: e => {
                returnAnim.stop();
                item.pressPos = Qt.point(e.x, e.y);
                item.pressIndex = item.DelegateModel.itemsIndex;
                item.lastMoveY = item.y;
                item.held = true;

                itemContent.x = Qt.binding(() => {
                    if (!root)
                        return 0;

                    const maxOvershoot = Tokens.padding.extraExtraLarge;
                    const x = mouse.mouseX - item.pressPos.x;
                    return root.dampOvershoot(Math.abs(x), maxOvershoot) * Math.sign(x);
                });
                itemContent.y = Qt.binding(() => {
                    if (!root)
                        return 0;

                    const maxOvershoot = Tokens.padding.extraLarge;
                    const yDiff = item.y - item.lastMoveY; // Extra offset if the y of the item changed between mouseY updates
                    const y = mouse.mouseY - item.pressPos.y - yDiff;
                    const absY = item.mapToItem(root.contentItem, 0, y).y;
                    const maxY = root.implicitHeight - item.implicitHeight;
                    if (absY < 0)
                        return y - absY - root.dampOvershoot(-absY, maxOvershoot);
                    if (absY > maxY)
                        return y - absY + maxY + root.dampOvershoot(absY - maxY, maxOvershoot);
                    return y;
                });
            }

            onPositionChanged: e => {
                item.lastMoveY = item.y;
                const absY = item.mapToItem(root.contentItem, 0, e.y).y;

                const swap = root.itemAt(0, absY);
                if (!swap || swap === item)
                    return;

                const idx = item.DelegateModel.itemsIndex;
                const swapIdx = swap.DelegateModel.itemsIndex;
                visualModel.items.move(idx, swapIdx);
            }

            onReleased: e => {
                // Break bindings
                itemContent.x = itemContent.x;
                itemContent.y = itemContent.y;
                returnAnim.start();
                item.held = false;

                const idx = item.DelegateModel.itemsIndex;
                if (idx !== item.pressIndex)
                    root.itemMoved(item.pressIndex, idx);
            }
        }

        Anim {
            id: returnAnim

            target: itemContent
            properties: "x,y"
            to: 0
        }

        Item {
            id: itemContent

            implicitWidth: item.width
            implicitHeight: item.implicitHeight

            Elevation {
                id: elevation

                anchors.fill: parent
                radius: itemBg.radius
                topLeftRadius: itemBg.topLeftRadius
                topRightRadius: itemBg.topRightRadius
                level: 3
                opacity: 0
            }

            StyledRect {
                id: itemBg

                anchors.fill: parent
                color: Colours.tPalette.m3surfaceContainer
                radius: item.lerpRadius(Tokens.rounding.extraSmall, Tokens.rounding.large)
                topLeftRadius: item.lerpRadius(item.topRadius, Tokens.rounding.large)
                topRightRadius: item.lerpRadius(item.topRadius, Tokens.rounding.large)
            }

            MouseArea {
                id: stateLayer

                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                cursorShape: mouse.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                StyledRect {
                    anchors.fill: parent
                    radius: itemBg.radius
                    topLeftRadius: itemBg.topLeftRadius
                    topRightRadius: itemBg.topRightRadius
                    color: Colours.palette.m3onSurface
                    opacity: parent.containsMouse && !item.held ? 0.08 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }

            RowLayout {
                id: row

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.large

                spacing: Tokens.spacing.medium

                MaterialIcon {
                    id: dragIcon

                    text: "drag_indicator"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    id: label

                    Layout.fillWidth: true
                    text: root.labelFor(item.modelData)
                    elide: Text.ElideRight
                }

                IconButton {
                    id: editButton

                    visible: root.canEdit(item.modelData)
                    type: IconButton.Text
                    isRound: true
                    icon: "edit"
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                    label.fill: 0

                    onClicked: root.editItem(item.modelData)
                }

                IconButton {
                    id: deleteButton

                    type: IconButton.Text
                    isRound: true
                    icon: "delete"
                    inactiveOnColour: Colours.palette.m3error
                    font: Tokens.font.icon.medium
                    label.fill: 0

                    onClicked: root.itemRemoved(item.DelegateModel.itemsIndex)
                }
            }
        }
    }
}
