import QtQuick
import Quickshell
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
        onClicked: {
            if (!root.modelData) return;
            root.list.visibilities.launcher = false;
            Quickshell.execDetached(["sh", "-c", "cliphist decode " + root.modelData.id + " | wl-copy"]);
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.margins: Tokens.padding.smaller

        MaterialIcon {
            id: icon

            text: "content_paste"
            font.pointSize: Tokens.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            id: preview

            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.normal
            anchors.right: parent.right
            anchors.verticalCenter: icon.verticalCenter

            text: root.modelData?.preview ?? ""
            font.pointSize: Tokens.font.size.normal
            elide: Text.ElideRight
        }
    }
}
