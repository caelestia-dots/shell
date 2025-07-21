import "../services"
import qs.widgets
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property DesktopEntry modelData
    required property PersistentProperties visibilities

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Appearance.rounding.full

        function onClicked(): void {
            Apps.launch(root.modelData);
            root.visibilities.launcher = false;
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

            implicitWidth: parent.width - icon.width
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
                color: Colours.alpha(Colours.palette.m3outline, true)

                elide: Text.ElideRight
                width: root.width - icon.width - Appearance.rounding.normal * 2

                anchors.top: name.bottom
            }
        }
    }
}
