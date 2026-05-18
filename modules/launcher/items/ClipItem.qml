import QtQuick
import Quickshell
import Caelestia
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
        onClicked: root.clicked()
    }

    function clicked() {
        if (!root.modelData) return;
        root.list.visibilities.launcher = false;
        const preview = root.modelData.preview.length > 30 ? root.modelData.preview.slice(0, 30) + "..." : root.modelData.preview;
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + root.modelData.id + " | wl-copy"]);
        Toaster.toast(qsTr("Copied to clipboard"), preview, "content_paste");
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
            anchors.rightMargin: 80
            anchors.verticalCenter: icon.verticalCenter

            text: root.modelData?.preview ?? ""
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
                const clipId = String(root.modelData?.id);
                if (!clipId) return;
                const favClips = GlobalConfig.launcher.favouriteClips ? [...GlobalConfig.launcher.favouriteClips] : [];
                if (favClips.includes(clipId)) {
                    const idx = favClips.indexOf(clipId);
                    if (idx !== -1) favClips.splice(idx, 1);
                } else {
                    favClips.push(clipId);
                }
                GlobalConfig.launcher.favouriteClips = favClips;
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: GlobalConfig.launcher.favouriteClips && GlobalConfig.launcher.favouriteClips.includes(String(root.modelData?.id)) ? "favorite" : "favorite_border"
                fill: GlobalConfig.launcher.favouriteClips && GlobalConfig.launcher.favouriteClips.includes(String(root.modelData?.id)) ? 1 : 0
                color: favIcon.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
