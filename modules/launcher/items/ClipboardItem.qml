pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import qs.components
import qs.components.controls
import qs.services
import qs.config

Item {
    id: root

    required property var modelData
    required property int index
    required property PersistentProperties visibilities

    property bool isItemHovered: itemHoverHandler.hovered
    readonly property bool isHovered: root.isItemHovered
    readonly property bool isCurrent: ListView.isCurrentItem && root.ListView.view?.lastInteraction === "keyboard" // qmllint disable missing-property

    implicitHeight: Config.launcher.sizes.itemHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    onIsItemHoveredChanged: {
        if (isItemHovered) {
            root.ListView.view.hoveredItem = root;
            root.ListView.view.lastInteraction = "hover";
        }
    }

    HoverHandler {
        id: itemHoverHandler
    }

    StyledRect {
        id: rect

        anchors.fill: parent
        implicitHeight: content.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.normal
        color: {
            if (root.isHovered || root.isCurrent)
                return Qt.alpha(Colours.palette.m3onSurface, 0.08);
            return "transparent";
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            onClicked: {
                root.ListView.view.currentIndex = root.index;
                Clipboard.copyToClipboard(root.modelData); // qmllint disable missing-property
                root.visibilities.launcher = false;
            }
        }

        RowLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: {
                    if (root.modelData.isPinned)
                        return "push_pin";
                    if (root.modelData.isImage)
                        return "image";
                    return "description";
                }
                color: root.modelData.isPinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.large
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.smaller

                StyledText {
                    Layout.fillWidth: true
                    text: root.modelData.content
                    color: root.isCurrent ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    text: {
                        const content = root.modelData.content;
                        const words = content.split(/\s+/).length;
                        const chars = content.length;
                        return qsTr("%1 characters, %2 words").arg(chars).arg(words);
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                }
            }

            Row {
                id: buttonsRow

                spacing: Appearance.spacing.small

                IconButton {
                    id: pinButton

                    icon: root.modelData.isPinned ? "push_pin" : "keep"
                    type: root.modelData.isPinned ? IconButton.Filled : IconButton.Text
                    radius: Appearance.rounding.small
                    padding: Appearance.padding.small
                    onClicked: {
                        Clipboard.togglePin(root.modelData); // qmllint disable missing-property
                    }
                }

                IconButton {
                    id: deleteButton

                    icon: "delete"
                    type: IconButton.Text
                    radius: Appearance.rounding.small
                    padding: Appearance.padding.small
                    onClicked: {
                        root.ListView.view.deletedItemIndex = root.index;
                        Clipboard.deleteItem(root.modelData); // qmllint disable missing-property
                    }
                }
            }
        }
    }
}
