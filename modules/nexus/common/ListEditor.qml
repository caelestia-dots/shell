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
    property real maxOvershoot: Tokens.spacing.extraLarge

    function dampOvershoot(overshoot: real): real {
        return overshoot / (1 + overshoot / root.maxOvershoot);
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

    component ListRow: Item {
        id: item

        required property var modelData
        property bool held

        anchors.left: root.contentItem.left
        anchors.right: root.contentItem.right
        implicitHeight: row.implicitHeight + row.anchors.margins * 2
        z: Math.abs(itemContent.y) >= root.spacing ? 1 : 0

        MouseArea {
            id: mouse

            anchors.fill: parent
            preventStealing: true

            onPressed: e => {
                stateLayer.press(e.x, e.y);
                yAnim.enabled = true;
                item.held = true;
            }
            onPositionChanged: yAnim.enabled = false
            onReleased: e => {
                yAnim.enabled = true;
                item.held = false;
                itemContent.y = 0; // Manually reset to 0 in case the initial move anim was playing

            // TODO
            }
        }

        Item {
            id: itemContent

            implicitWidth: item.width
            implicitHeight: item.implicitHeight

            Binding on y {
                value: {
                    const y = mouse.mouseY - item.implicitHeight / 2;
                    const absY = item.mapToItem(root.contentItem, 0, y).y;
                    const maxY = root.implicitHeight - item.implicitHeight;
                    if (absY < 0)
                        return y - absY - root.dampOvershoot(-absY);
                    if (absY > maxY)
                        return y - absY + maxY + root.dampOvershoot(absY - maxY);
                    return y;
                }
                when: item.held
            }

            Behavior on y {
                id: yAnim

                Anim {}
            }

            Elevation {
                anchors.fill: parent
                radius: itemBg.radius
                level: 3
                opacity: item.held ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledRect {
                id: itemBg

                anchors.fill: parent
                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, 1)
                opacity: item.held ? 1 : Colours.tPalette.m3surfaceContainer.a
                radius: item.held ? Tokens.rounding.large : Tokens.rounding.extraSmall

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Behavior on radius {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
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
                    text: item.modelData.icon
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: item.modelData.label
                    elide: Text.ElideRight
                }

                MaterialIcon {
                    text: "drag_handle"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                IconButton {
                    type: IconButton.Text
                    isRound: true
                    icon: "delete"
                    inactiveOnColour: Colours.palette.m3error
                    font: Tokens.font.icon.medium
                    label.fill: 0
                }
            }
        }
    }
}
