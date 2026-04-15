import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property M3Variants.Variant modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        function onClicked(): void {
            root.modelData?.onClicked(root.list);
        }

        radius: Tokens.rounding.normal
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.margins: Tokens.padding.smaller

        MaterialIcon {
            id: icon

            text: root.modelData?.icon ?? ""
            font.pointSize: Tokens.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.larger
            anchors.verticalCenter: icon.verticalCenter

            width: parent.width - icon.width - anchors.leftMargin - (current.active ? current.width + Tokens.spacing.normal : 0)
            spacing: 0

            StyledText {
                text: root.modelData?.name ?? ""
                font.pointSize: Tokens.font.size.normal
            }

            StyledText {
                text: root.modelData?.description ?? ""
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        Loader {
            id: current

            asynchronous: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            active: root.modelData?.variant === Schemes.currentVariant

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.large
            }
        }
    }
}
