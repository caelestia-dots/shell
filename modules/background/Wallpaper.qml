pragma ComponentBehavior: Bound
import Caelestia.Config

import QtQuick
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property bool completed
    property Image current: one
    property string source: Wallpapers.current
    readonly property bool sourceIsVideo: isVideoFile(source)
    readonly property var validVideoExtensions: ["mp4", "webm", "mkv"]
    readonly property url videoSource: sourceIsVideo ? toFileUrl(source) : ""

    function fileExtension(path) {
        const clean = String(path || "").split(/[?#]/)[0].toLowerCase();
        const index = clean.lastIndexOf(".");
        return index >= 0 ? clean.slice(index + 1) : "";
    }
    function isVideoFile(path) {
        return validVideoExtensions.indexOf(fileExtension(path)) !== -1;
    }
    function toFileUrl(path) {
        const clean = String(path || "").trim();

        if (!clean)
            return "";
        if (clean.indexOf("file://") === 0)
            return clean;
        if (clean[0] === "/")
            return "file://" + clean;

        return Qt.resolvedUrl(clean);
    }

    Component.onCompleted: {
        if (sourceIsVideo) {
            completed = true;
        } else if (source) {
            Qt.callLater(() => {
                one.update();
                completed = true;
            });
        }
    }
    onSourceChanged: {
        if (sourceIsVideo) {
            current = null;
            videoUpdateTimer.restart();
            if (current === one)
                two.update();
            else
                one.update();
        } else if (!source) {
            current = null;
        } else if (current === one) {
            two.update();
        } else {
            one.update();
        }
    }

    Timer {
        id: videoUpdateTimer

        interval: 50
        repeat: false

        onTriggered: {
            if (videoLoader.item && root.sourceIsVideo) {
                videoLoader.item.videoSource = root.videoSource;
                videoLoader.item.autoStart = !WallpaperPauser.paused;
            }
        }
    }

    // Listens to WallpaperPauser singleton to physically halt video playback.
    Connections {
        function onPausedChanged() {
            if (videoLoader.item && root.sourceIsVideo) {
                videoLoader.item.autoStart = !WallpaperPauser.paused;
                if (WallpaperPauser.paused) {
                    videoLoader.item.pause();
                } else {
                    videoLoader.item.play();
                }
            }
        }

        ignoreUnknownSignals: true
        target: WallpaperPauser
    }
    Loader {
        active: root.completed && !root.source
        anchors.fill: parent
        asynchronous: true

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.large

                MaterialIcon {
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.extraLarge * 5
                    text: "sentiment_stressed"
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        color: Colours.palette.m3onSurfaceVariant
                        font.bold: true
                        font.pointSize: Tokens.font.size.extraLarge * 2
                        text: qsTr("Wallpaper missing?")
                    }
                    StyledRect {
                        color: Colours.palette.m3primary
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small * 2
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.large * 2
                        radius: Tokens.rounding.full

                        FileDialog {
                            id: dialog

                            filterLabel: qsTr("Image files")
                            filters: Images.validImageExtensions
                            title: qsTr("Select a wallpaper")

                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }
                        StateLayer {
                            color: Colours.palette.m3onPrimary
                            radius: parent.radius

                            onClicked: dialog.open()
                        }
                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Tokens.font.size.large
                            text: qsTr("Set it now!")
                        }
                    }
                }
            }
        }
    }
    Img {
        id: one
    }
    Img {
        id: two
    }

    // Asynchronous Loader that injects the QtMultimedia video player into the background layer only when a video is selected.
    Loader {
        id: videoLoader

        active: root.sourceIsVideo
        anchors.fill: parent
        source: "VideoWallpaper.qml"

        onLoaded: {
            item.autoStart = true;
            item.videoSource = root.videoSource;
        }
    }

    component Img: CachingImage {
        id: img

        function update(): void {
            const newPath = root.sourceIsVideo ? Wallpapers.getWallpaperThumb(root.source, Wallpapers.cacheBuster) : root.source;
            if (path === newPath && source === newPath)
                root.current = this;
            else {
                path = root.source; // Keep IUtils happy for static images
                source = newPath;   // Override source directly
            }
        }

        anchors.fill: parent
        opacity: 0
        scale: Wallpapers.showPreview ? 1 : 0.8

        // Keep thumbnail visible until the video has actual frames to render,
        // OR whenever the video is paused (to prevent black blank screens).
        visible: !root.sourceIsVideo || WallpaperPauser.paused || (videoLoader.item && videoLoader.item.mediaStatus < 2)

        states: State {
            name: "visible"
            when: root.current === img

            PropertyChanges {
                img.opacity: 1
                img.scale: 1
            }
        }
        transitions: Transition {
            Anim {
                properties: "opacity,scale"
                target: img
            }
        }

        onStatusChanged: {
            if (status === Image.Ready)
                root.current = this;
        }
    }
}
