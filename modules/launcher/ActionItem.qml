import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick

Item {
    id: root

    required property Actions.Action modelData
    required property var list

    implicitHeight: LauncherConfig.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Appearance.rounding.full

        function onClicked(): void {
            root.modelData?.onClicked(root.list);
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.larger
        anchors.rightMargin: Appearance.padding.larger
        anchors.margins: Appearance.padding.smaller

        MaterialIcon {
            id: icon

            text: root.modelData?.disabled
                ? "disabled_by_default"
                : (root.modelData?.icon ?? "")
            font.pointSize: Appearance.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Appearance.spacing.larger
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.disabled
                    ? (root.modelData?.name ?? "") + " - Disabled"
                    : (root.modelData?.name ?? "")
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                id: desc

                text: root.modelData?.disabled
                    ? (root.modelData?.disabledReason ?? "")
                    : (root.modelData?.desc ?? "")
                font.pointSize: Appearance.font.size.small
                color: Colours.alpha(Colours.palette.m3outline, true)

                elide: Text.ElideRight
                width: root.width - icon.width - Appearance.rounding.normal * 2

                anchors.top: name.bottom
            }
        }
    }
}
