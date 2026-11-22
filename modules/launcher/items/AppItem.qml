import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property ScreenState screenState
    readonly property var openGroup: modelData ? Dock.openGroup(modelData.id) : null

    // An app that is already open is focused instead of launched again
    function open(): void {
        if (openGroup)
            Dock.activate(openGroup);
        else
            Apps.launch(modelData);
        screenState.launcher = false;
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.open()
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium + 16
        anchors.rightMargin: Tokens.padding.medium + 16
        anchors.margins: Tokens.padding.small

        IconImage {
            id: icon

            asynchronous: true
            source: Icons.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteIcon.width
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                color: Hallownest.soul
                font.pointSize: Tokens.font.body.medium.pointSize
                font.weight: Font.Medium
            }

            StyledText {
                id: comment

                text: root.openGroup ? Tr.tr("Open · switch to its window") : (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font: Tokens.font.body.small
                color: root.openGroup ? Hallownest.lifeblood : Hallownest.subtext

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteIcon.width - Tokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }

        Loader {
            id: favouriteIcon

            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            active: root.modelData && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData.id)

            sourceComponent: Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                rotation: 45
                color: Hallownest.gold
            }
        }
    }
}
