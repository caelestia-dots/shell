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

    signal itemsCommitted(items: list<var>)

    function iconFor(item: var): string {
        return item.icon;
    }

    function labelFor(item: var): string {
        return item.label;
    }

    function commitItems(): void {
        const items = contentItem.children.filter(c => c instanceof ListRow);
        items.sort((a, b) => a.DelegateModel.itemsIndex - b.DelegateModel.itemsIndex);
        itemsCommitted(items.map(i => i.modelData));
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

    component ListRow: Item {
        id: item

        required property var modelData
        required property int index
        property bool held
        property point pressPos
        property real lastMoveY

        anchors.left: root?.contentItem.left
        anchors.right: root?.contentItem.right
        implicitHeight: row.implicitHeight + row.anchors.margins * 2
        z: held || returnAnim.running ? 1 : 0

        state: held ? "held" : ""

        states: State {
            name: "held"

            PropertyChanges {
                placeholder.opacity: 0.1
                elevation.opacity: 1
                itemBg.color: Colours.palette.m3tertiaryContainer
                itemBg.radius: item.Tokens.rounding.large
                stateLayer.color: Colours.palette.m3onTertiaryContainer
                leadingIcon.color: Colours.palette.m3onTertiaryContainer
                label.color: Colours.palette.m3onTertiaryContainer
                dragHandle.color: Colours.palette.m3onTertiaryContainer
                deleteButton.inactiveOnColour: Colours.palette.m3onError
            }
        }

        transitions: Transition {
            Anim {
                properties: "opacity,radius"
                type: Anim.SlowEffects
            }
            PropertyAction {
                properties: "color,inactiveOnColour"
            }
        }

        StyledRect {
            id: placeholder

            anchors.fill: parent
            color: Colours.palette.m3tertiaryContainer
            radius: Tokens.rounding.extraSmall
            opacity: 0
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            preventStealing: true

            onPressed: e => {
                returnAnim.stop();
                stateLayer.press(e.x, e.y);
                item.pressPos = Qt.point(e.x, e.y);
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

                root.commitItems();
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
                level: 3
                opacity: 0
            }

            StyledRect {
                id: itemBg

                anchors.fill: parent
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraSmall
            }

            StateLayer {
                id: stateLayer

                enabled: false
                hoverEnabled: false
                radius: itemBg.radius
                cursorShape: mouse.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                manualPressOverride: mouse.pressed
                manualHoverOverride: mouse.containsMouse || mouse.pressed
            }

            RowLayout {
                id: row

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.large

                spacing: Tokens.spacing.medium

                MaterialIcon {
                    id: leadingIcon

                    text: root.iconFor(item.modelData)
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    id: label

                    Layout.fillWidth: true
                    text: root.labelFor(item.modelData)
                    elide: Text.ElideRight
                }

                MaterialIcon {
                    id: dragHandle

                    text: "drag_handle"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                IconButton {
                    id: deleteButton

                    type: IconButton.Text
                    isRound: true
                    icon: "delete"
                    inactiveOnColour: Colours.palette.m3error
                    font: Tokens.font.icon.medium
                    label.fill: 0

                    onClicked: {
                        visualModel.items.remove(item.DelegateModel.itemsIndex);
                        root.commitItems();
                    }
                }
            }
        }
    }
}
