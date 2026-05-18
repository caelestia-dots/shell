import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property DrawerVisibilities visibilities

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        id: stateLayer
        radius: Tokens.rounding.normal
        acceptedButtons: Qt.LeftButton
        onClicked: {
            Apps.launch(root.modelData);
            root.visibilities.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.margins: Tokens.padding.smaller

        IconImage {
            id: icon

            asynchronous: true
            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.normal
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - 80
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font.pointSize: Tokens.font.size.normal
            }

            StyledText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - 80 - Tokens.rounding.normal * 2

                anchors.top: name.bottom
            }
        }

        MouseArea {
            id: hideIcon
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            hoverEnabled: true
            onClicked: {
                const appId = root.modelData?.id;
                if (!appId) return;
                const hiddenApps = GlobalConfig.launcher.hiddenApps ? [...GlobalConfig.launcher.hiddenApps] : [];
                if (Strings.testRegexList(hiddenApps, appId)) {
                    const idx = hiddenApps.indexOf(appId);
                    if (idx !== -1) hiddenApps.splice(idx, 1);
                } else {
                    hiddenApps.push(appId);
                }
                GlobalConfig.launcher.hiddenApps = hiddenApps;
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: Strings.testRegexList(GlobalConfig.launcher.hiddenApps, root.modelData?.id) ? "visibility_off" : "visibility"
                color: hideIcon.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outline
            }
        }

        MouseArea {
            id: favIcon
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: hideIcon.left
            anchors.rightMargin: Tokens.padding.small
            hoverEnabled: true
            onClicked: {
                const appId = root.modelData?.id;
                if (!appId) return;
                const favApps = GlobalConfig.launcher.favouriteApps ? [...GlobalConfig.launcher.favouriteApps] : [];
                if (Strings.testRegexList(favApps, appId)) {
                    const idx = favApps.indexOf(appId);
                    if (idx !== -1) favApps.splice(idx, 1);
                } else {
                    favApps.push(appId);
                }
                GlobalConfig.launcher.favouriteApps = favApps;
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData?.id) ? "favorite" : "favorite_border"
                fill: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData?.id) ? 1 : 0
                color: favIcon.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
