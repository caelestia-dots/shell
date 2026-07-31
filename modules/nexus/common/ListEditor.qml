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

    signal itemDeleted(index: int)

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
        required property int index
        property bool held
        property point pressPos

        anchors.left: root.contentItem.left
        anchors.right: root.contentItem.right
        implicitHeight: row.implicitHeight + row.anchors.margins * 2
        z: Math.abs(itemContent.y) >= root.spacing ? 1 : 0

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
                stateLayer.press(e.x, e.y);
                item.pressPos = Qt.point(e.x, e.y);
                yAnim.enabled = false;
                item.held = true;
            }
            onPositionChanged: yAnim.enabled = false
            onReleased: e => {
                yAnim.enabled = true;
                item.held = false;
                itemContent.y = 0; // Manually reset to 0 in case move anim is running

            // TODO
            }
        }

        Item {
            id: itemContent

            implicitWidth: item.width
            implicitHeight: item.implicitHeight

            Binding on y {
                value: {
                    const y = mouse.mouseY - item.pressPos.y;
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

                    text: item.modelData.icon
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    id: label

                    Layout.fillWidth: true
                    text: item.modelData.label
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

                    onClicked: root.itemDeleted(item.index)
                }
            }
        }
    }
}
