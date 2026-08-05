pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus.common

DialogRowButton {
    id: root

    required property var model
    property var selectedItem

    function keyFor(item: var): string {
        return item.id;
    }

    function labelFor(item: var): string {
        return item.label;
    }

    onOpenChanged: {
        if (open)
            selectedItem = null;
    }

    acceptAllowed: !!selectedItem
    separateContent: true
    horizontalContentMargin: -Tokens.padding.small

    content: Component {
        VerticalFadeListView {
            spacing: 0
            topMargin: Tokens.padding.large
            bottomMargin: Tokens.padding.large

            model: root.model

            delegate: StyledRect {
                id: item

                required property var modelData
                readonly property bool selected: root.selectedItem === root.keyFor(modelData)

                anchors.left: ListView.view.contentItem.left
                anchors.right: ListView.view.contentItem.right
                anchors.margins: 1 // Gets cut off for some reason without this
                implicitHeight: label.implicitHeight + Tokens.padding.medium * 2

                radius: stateLayer.pressed ? Tokens.rounding.extraSmall : selected ? Tokens.rounding.largeIncreased : Tokens.rounding.medium
                color: Qt.alpha(Colours.palette.m3tertiaryContainer, selected ? 1 : 0)

                Behavior on radius {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                StateLayer {
                    id: stateLayer

                    onClicked: root.selectedItem = root.keyFor(item.modelData)
                }

                StyledText {
                    id: label

                    anchors.left: parent.left
                    anchors.right: item.selected ? checkIcon.left : parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.large
                    anchors.rightMargin: item.selected ? Tokens.spacing.medium : anchors.margins

                    text: root.labelFor(item.modelData)
                    color: item.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                MaterialIcon {
                    id: checkIcon

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.large

                    text: "check"
                    color: Colours.palette.m3onTertiaryContainer
                    fontStyle: Tokens.font.icon.medium
                    opacity: item.selected ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }
                }
            }
        }
    }
}
