import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var list
    required property var modelData

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.normal
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.margins: Tokens.padding.smaller

        MaterialIcon {
            id: icon

            text: "keyboard"
            font.pointSize: Tokens.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
        }

        ColumnLayout {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.normal
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: 0

            StyledText {
                text: (modelData && modelData.bind) ? modelData.bind : qsTr("No keybinds")
                font.weight: 500
                font.family: Config.appearance.font.family.mono || "monospace"
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            StyledText {
                text: (modelData && modelData.action) ? modelData.action : ""
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }
        }
    }
}