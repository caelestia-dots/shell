pragma NativeMethodBehavior: AcceptThisObject

import "../services"
import qs.components
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property DesktopEntry modelData
    required property PersistentProperties visibilities
    property var showContextMenuAt: null
    property Item wrapperRoot: null
    
    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        id: stateLayer
        radius: Appearance.rounding.normal
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        function onClicked(event): void {
            if (event.button === Qt.LeftButton) {
                Apps.launch(root.modelData);
                root.visibilities.launcher = false;
            } else if (event.button === Qt.RightButton) {
                if (!root.showContextMenuAt || !root.wrapperRoot || !root.modelData) {
                    return;
                }
                
                try {
                    const pos = stateLayer.mapToItem(root.wrapperRoot, event.x, event.y);
                    if (pos && typeof pos.x === 'number' && typeof pos.y === 'number') {
                        root.showContextMenuAt(root.modelData, pos.x, pos.y);
                    }
                } catch (error) {
                    console.error("Failed to show context menu:", error);
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.larger
        anchors.rightMargin: Appearance.padding.larger
        anchors.margins: Appearance.padding.smaller

        IconImage {
            id: icon

            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Appearance.spacing.normal
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteIcon.width
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteIcon.width - Appearance.rounding.normal * 2

                anchors.top: name.bottom
            }
        }

        Loader {
            id: favouriteIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            active: modelData && Strings.testRegexList(Config.launcher.favouriteApps, modelData.id)

            sourceComponent: MaterialIcon {
                text: "favorite"
                fill: 1
                color: Colours.palette.m3primary
            }
        }
    }
}
