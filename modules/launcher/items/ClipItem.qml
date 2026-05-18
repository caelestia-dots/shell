import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components.images
import qs.components
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: (root.modelData?.isImage ?? false) ? Tokens.sizes.launcher.itemHeight * 2 : Tokens.sizes.launcher.itemHeight

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

            text: (root.modelData?.isImage ?? false) ? "image" : "content_paste"
            font.pointSize: Tokens.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.smaller
        }

        Item {
            id: imagePreview

            width: (root.modelData?.isImage ?? false) ? 120 : 0
            height: (root.modelData?.isImage ?? false) ? 80 : 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: icon.right
            anchors.leftMargin: (root.modelData?.isImage ?? false) ? Tokens.spacing.normal : 0
            visible: root.modelData?.isImage ?? false

            property string imagePath: (root.modelData?.isImage ?? false) ? "/tmp/caelestia-clipboard/" + (root.modelData?.id ?? "") + ".png" : ""

            Image {
                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                source: imagePreview.imagePath.length > 0 ? "file://" + imagePreview.imagePath : ""
            }
        }

        StyledText {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.normal
            anchors.right: favIcon.left
            anchors.rightMargin: Tokens.spacing.small
            anchors.verticalCenter: parent.verticalCenter

            text: root.modelData?.preview ?? ""
            font.pointSize: Tokens.font.size.normal
elide: Text.ElideRight
            visible: !(root.modelData?.isImage ?? false)
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

    Component.onCompleted: {
        if (root.modelData?.isImage) {
            Clipboard.ensureImageCached(root.modelData.id);
        }
    }
}