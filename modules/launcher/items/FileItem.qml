import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property var list

    function onClicked(): void {
        FileSearch.open(modelData.path);
        root.list.screenState.launcher = false;
    }

    function openFolder(): void {
        FileSearch.open(modelData.dir);
        root.list.screenState.launcher = false;
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.medium + 16
        anchors.rightMargin: Tokens.padding.medium + 16

        spacing: Tokens.spacing.medium

        IconImage {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            source: Icons.iconPath(FileSearch.iconFor(root.modelData), "text-x-generic")
            implicitSize: Tokens.sizes.launcher.itemHeight * 0.6
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.name
                color: Hallownest.soul
                font.pointSize: Tokens.font.body.medium.pointSize
                font.weight: Font.Medium
                elide: Text.ElideMiddle
            }

            StyledText {
                Layout.fillWidth: true
                text: Paths.shortenHome(root.modelData.dir)
                color: Hallownest.subtext
                font: Tokens.font.body.small
                elide: Text.ElideMiddle
            }
        }
    }
}
