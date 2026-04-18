import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.normal
        onClicked: root.modelData?.onClicked(root.list)
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

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.normal
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font.pointSize: Tokens.font.size.normal
            }

            StyledText {
                id: desc

                text: root.modelData?.desc ?? ""
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - Tokens.rounding.normal * 2

                anchors.top: name.bottom
            }
        }
    }
}
