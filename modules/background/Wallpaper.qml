pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property string source: Wallpapers.current
    property Item current: one
    property bool completed

    onSourceChanged: {
    if (!source) {
        current = null;
        return;
    }
    if (current === one)
        two.update();
    else if (current === two)
        one.update();
    else
        one.update();
    }

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                one.update();
                completed = true;
            });
    }

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: root.completed && !root.source
        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer
            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.large
                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.extraLarge * 5
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small
                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.size.extraLarge * 2
                        font.bold: true
                    }
                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.large * 2
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary
                        FileDialog {
                            id: dialog
                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }
                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }
                        StyledText {
                            id: selectWallText
                            anchors.centerIn: parent
                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Tokens.font.size.large
                        }
                    }
                }
            }
        }
    }

    Img { id: one }
    Img { id: two }

    component Img: Item {
        id: img

        readonly property bool isVideo: img.imgPath.endsWith(".mp4") || img.imgPath.endsWith(".mkv") ||
                                img.imgPath.endsWith(".webm") || img.imgPath.endsWith(".avi") ||
                                img.imgPath.endsWith(".mov")

        function update(): void {
            if (imgPath === root.source)
                root.current = this;
            else
                imgPath = root.source;
        }

        property string imgPath

        anchors.fill: parent

        CachingImage {
            anchors.fill: parent
            visible: !img.isVideo
            path: img.isVideo ? "" : img.imgPath
            onStatusChanged: {
                if (status === Image.Ready)
                    root.current = img;
            }
        }

        Video {
            anchors.fill: parent
            visible: img.isVideo
            source: img.isVideo ? ("file://" + img.imgPath) : ""
            loops: MediaPlayer.Infinite
            autoPlay: img.isVideo
            fillMode: VideoOutput.PreserveAspectCrop
            onPlaying: root.current = img
        }

        opacity: root.current === img ? 1 : 0
        scale: (root.current === img) ? 1 : (Wallpapers.showPreview ? 1 : 0.8)

        Behavior on opacity {
            Anim { properties: "opacity" }
        }

        Behavior on scale {
            Anim { properties: "scale" }
        }
    }
}