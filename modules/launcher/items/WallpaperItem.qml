import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import Caelestia.Models
import Quickshell
import QtQuick
import QtMultimedia

Item {
    id: root

    required property FileSystemEntry modelData
    required property PersistentProperties visibilities

    function isVideo(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return false;
        const videoExtensions = [".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".wmv", ".gif"];
        const lower = path.toLowerCase();
        for (let i = 0; i < videoExtensions.length; i++) {
            if (lower.endsWith(videoExtensions[i]))
                return true;
        }
        return false;
    }

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Appearance.padding.larger * 2
    implicitHeight: image.height + label.height + Appearance.spacing.small / 2 + Appearance.padding.large + Appearance.padding.normal

    StateLayer {
        radius: Appearance.rounding.normal

        function onClicked(): void {
            Wallpapers.setWallpaper(root.modelData.path);
            root.visibilities.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {}
        }
    }

    StyledClippingRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Appearance.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.normal

        implicitWidth: Config.launcher.sizes.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Colours.tPalette.m3outline
            font.pointSize: Appearance.font.size.extraLarge * 2
            font.weight: 600
            visible: !isVideo(root.modelData.path)
        }

        Loader {
            anchors.fill: parent
            active: isVideo(root.modelData.path)

            sourceComponent: Component {
                Item {
                    anchors.fill: parent

                    MediaPlayer {
                        id: player
                        source: root.modelData.path
                        autoPlay: false
                        videoOutput: vidThumb

                        onMediaStatusChanged: {
                            if (mediaStatus === MediaPlayer.LoadedMedia) {
                                play();
                                position = 1;
                            }
                        }

                        onPositionChanged: {
                            if (position >= 1)
                                pause();
                        }
                    }

                    VideoOutput {
                        id: vidThumb
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectCrop
                    }
                }
            }
        }

        Loader {
            anchors.fill: parent
            active: !isVideo(root.modelData.path)

            sourceComponent: Component {
                CachingImage {
                    path: root.modelData.path
                    smooth: !root.PathView.view.moving
                    anchors.fill: parent
                }
            }
        }
    }
    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Appearance.spacing.small / 2
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Appearance.padding.normal * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
	text: root.modelData.relativePath.replace(/\.[^/.]+$/, "")
        font.pointSize: Appearance.font.size.normal
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {}
    }
}
