import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.normal
        onClicked: root.clicked()
    }

    function clicked() {
        if (!root.modelData) return;
        root.list.visibilities.launcher = false;
        Quickshell.execDetached(["wl-copy", root.modelData.char]);
        Emojis.recordUsage(root.modelData.char);
        Toaster.toast(qsTr("Copied to clipboard"), root.modelData.char + " " + root.modelData.name, "emoji_emotions");
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.margins: Tokens.padding.smaller

        StyledText {
            id: emojiChar

            text: root.modelData?.char ?? ""
            font.pointSize: Tokens.font.size.title

            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            id: name

            anchors.left: emojiChar.right
            anchors.leftMargin: Tokens.spacing.normal
            anchors.right: parent.right
            anchors.rightMargin: 80
            anchors.verticalCenter: emojiChar.verticalCenter

            text: root.modelData?.name ?? ""
            font.pointSize: Tokens.font.size.normal
            elide: Text.ElideRight
        }

        MouseArea {
            id: favIcon
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            hoverEnabled: true
            onClicked: {
                const emojiChar = root.modelData?.char;
                if (!emojiChar) return;
                const favEmojis = GlobalConfig.launcher.favouriteEmojis ? [...GlobalConfig.launcher.favouriteEmojis] : [];
                if (favEmojis.includes(emojiChar)) {
                    const idx = favEmojis.indexOf(emojiChar);
                    if (idx !== -1) favEmojis.splice(idx, 1);
                } else {
                    favEmojis.push(emojiChar);
                }
                GlobalConfig.launcher.favouriteEmojis = favEmojis;
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: GlobalConfig.launcher.favouriteEmojis && GlobalConfig.launcher.favouriteEmojis.includes(root.modelData?.char) ? "favorite" : "favorite_border"
                fill: GlobalConfig.launcher.favouriteEmojis && GlobalConfig.launcher.favouriteEmojis.includes(root.modelData?.char) ? 1 : 0
                color: favIcon.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
