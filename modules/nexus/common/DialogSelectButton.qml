pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.nexus.common

DialogRowButton {
    id: root

    required property var model
    property var selectedItem
    property bool searchable
    property string searchQuery
    property string searchPlaceholder: Tr.tr("Search")
    // When true (list mode), show a MaterialIcon beside each row label
    property bool showIcons: false
    // Icon-only grid (search still matches label/id)
    property bool iconGrid: false
    property int iconGridColumns: 6

    function keyFor(item: var): string {
        return item.id;
    }

    function labelFor(item: var): string {
        return item.label;
    }

    function iconFor(item: var): string {
        return item.icon || root.keyFor(item) || "";
    }

    readonly property var filteredModel: {
        const items = root.model ?? [];
        if (!root.searchable)
            return items;
        const q = (root.searchQuery || "").trim().toLowerCase();
        if (!q)
            return items;
        return items.filter(item => {
            const label = String(root.labelFor(item) || "").toLowerCase();
            const key = String(root.keyFor(item) || "").toLowerCase();
            return label.includes(q) || key.includes(q);
        });
    }

    onOpenChanged: {
        if (open) {
            selectedItem = null;
            searchQuery = "";
        }
    }

    acceptAllowed: !!selectedItem
    separateContent: true
    horizontalContentMargin: -Tokens.padding.small

    content: Component {
        ColumnLayout {
            spacing: Tokens.spacing.small

            SearchBar {
                id: searchField

                // Match spacing used around the dialog separators
                Layout.topMargin: Tokens.spacing.medium
                Layout.fillWidth: true
                visible: root.searchable
                height: visible ? implicitHeight : 0
                placeholderText: root.searchPlaceholder
                font: Tokens.font.body.medium
                text: root.searchQuery
                onTextChanged: root.searchQuery = text

                Component.onCompleted: {
                    if (root.searchable)
                        forceActiveFocus();
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.iconGrid ? 0 : 1

                // 0 — icon-only grid
                Item {
                    clip: true

                    GridView {
                        id: grid

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        clip: true
                        cellWidth: Math.max(1, Math.floor(width / Math.max(1, root.iconGridColumns)))
                        cellHeight: cellWidth
                        model: root.filteredModel

                        delegate: Item {
                            id: cell

                            required property var modelData
                            required property int index

                            width: grid.cellWidth
                            height: grid.cellHeight

                            readonly property bool selected: root.selectedItem === root.keyFor(modelData)

                            StyledRect {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - Tokens.padding.extraSmall
                                height: width
                                radius: Tokens.rounding.large
                                color: Qt.alpha(Colours.palette.m3tertiaryContainer, cell.selected ? 1 : 0)

                                Behavior on color {
                                    CAnim {}
                                }

                                StateLayer {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    onClicked: root.selectedItem = root.keyFor(cell.modelData)
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: root.iconFor(cell.modelData)
                                    color: cell.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                    fontStyle: Tokens.font.icon.large
                                }
                            }
                        }
                    }
                }

                // 1 — text list
                VerticalFadeListView {
                    spacing: 0
                    topMargin: Tokens.padding.small
                    bottomMargin: Tokens.padding.large
                    model: root.filteredModel

                    delegate: StyledRect {
                        id: item

                        required property var modelData
                        readonly property bool selected: root.selectedItem === root.keyFor(modelData)

                        anchors.left: ListView.view.contentItem.left
                        anchors.right: ListView.view.contentItem.right
                        anchors.margins: 1
                        implicitHeight: Math.max(label.implicitHeight, itemIcon.implicitHeight) + Tokens.padding.medium * 2

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

                        MaterialIcon {
                            id: itemIcon

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Tokens.padding.large
                            visible: root.showIcons
                            width: visible ? implicitWidth : 0
                            text: root.iconFor(item.modelData)
                            color: item.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            id: label

                            anchors.left: root.showIcons ? itemIcon.right : parent.left
                            anchors.right: item.selected ? checkIcon.left : parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: root.showIcons ? Tokens.spacing.medium : Tokens.padding.large
                            anchors.rightMargin: item.selected ? Tokens.spacing.medium : Tokens.padding.large

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
    }
}
