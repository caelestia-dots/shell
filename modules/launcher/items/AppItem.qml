pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property ScreenState screenState

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        id: layer

        radius: Tokens.rounding.large
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                // Menus.activate closes any other open menu first
                contextMenu.expanded = true;
                event.accepted = true;
                return;
            }
            Apps.launch(root.modelData);
            root.screenState.launcher = false;
        }
    }

    Menu {
        id: contextMenu

        attachTo: root
        attachSideX: Menu.Left
        attachSideY: Menu.Bottom
        thisSideX: Menu.Left
        thisSideY: Menu.Top
        marginX: Tokens.padding.medium
        marginY: Tokens.padding.extraSmall

        items: [
            MenuItem {
                icon: "edit"
                text: Tr.tr("Edit application…")
                onClicked: Apps.requestEdit(root.modelData)
            },
            MenuItem {
                icon: Apps.isFavourite(root.modelData?.id ?? "") ? "star" : "star_outline"
                text: Apps.isFavourite(root.modelData?.id ?? "") ? Tr.tr("Remove from favourites") : Tr.tr("Add to favourites")
                onClicked: Apps.toggleFavourite(root.modelData.id)
            },
            MenuItem {
                icon: "visibility_off"
                text: Tr.tr("Hide from launcher")
                onClicked: Apps.hideFromLauncher(root.modelData.id)
            },
            MenuItem {
                icon: "restart_alt"
                text: Tr.tr("Reset customization")
                onClicked: Apps.resetDesktopOverride(root.modelData.id)
            }
        ]
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        Item {
            id: icon

            implicitWidth: parent.height * 0.8
            implicitHeight: parent.height * 0.8
            anchors.verticalCenter: parent.verticalCenter

            readonly property string iconSource: Icons.resolveThemeIcon(root.modelData?.icon || "", "application-x-executable")

            IconImage {
                id: iconImage

                anchors.fill: parent
                asynchronous: true
                source: icon.iconSource
                visible: icon.iconSource.length > 0 && status === Image.Ready
            }

            StyledRect {
                anchors.fill: parent
                radius: width * 0.22
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                visible: !iconImage.visible

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "apps"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.extraLarge
                }
            }
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
                font: Tokens.font.body.medium
            }

            StyledText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

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

            sourceComponent: MaterialIcon {
                text: "favorite"
                fill: 1
                color: Colours.palette.m3primary
            }
        }
    }
}
