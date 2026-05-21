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
    property var screen: null

    function isVideo(path: string): bool {
        if (!path)
            return false;
        const ext = path.split('.').pop().toLowerCase();
        return ["mp4", "webm", "mkv", "avi", "mov", "wmv", "flv"].includes(ext);
    }

    onSourceChanged: {
        if (!source)
            current = null;
        else if (current !== one) {
            two.screen = screen;
            two.update();
        }
        else {
            one.screen = screen;
            one.update();
        }
    }

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                one.screen = screen;
                Qt.callLater(() => one.update());
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
                            filterLabel: qsTr("Media files")
                            filters: Images.validImageExtensions.concat(Images.validVideoExtensions)
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

    Img {
        id: one

        property var screen: null
    }

    Img {
        id: two

        property var screen: null
    }

    component Img: Item {
        id: img

        property string imagePath: ""
        property string videoPath: ""
        property bool isVideoImage: root.isVideo(root.source)
        property var screen: null

        onIsVideoImageChanged: updateContent()
        
        function update(): void {
            this.screen = root.screen;
            if (isVideoImage) {
                if (videoPath === root.source)
                    root.current = this;
                else {
                    imagePath = "";
                    videoPath = root.source;
                }
            } else {
                if (imagePath === root.source)
                    root.current = this;
                else {
                    videoPath = "";
                    imagePath = root.source;
                }
            }
        }

        function updateContent(): void {
            if (isVideoImage) {
                imagePath = "";
                videoPath = root.source;
            } else {
                videoPath = "";
                imagePath = root.source;
            }
        }

        anchors.fill: parent

        opacity: 0
        scale: Wallpapers.showPreview ? 1 : 0.8

        CachingAnimatedImage {
            anchors.fill: parent
            path: img.imagePath
            visible: !img.isVideoImage && img.imagePath !== ""
            asynchronous: true
            fillMode: AnimatedImage.PreserveAspectCrop
            source: img.imagePath || ""
            playing: true

            onStatusChanged: {
                if (status === Image.Ready && !img.isVideoImage)
                    root.current = img;
            }
        }

        CachingVideo {
            anchors.fill: parent
            path: img.videoPath
            screen: root.screen
            visible: img.isVideoImage && img.videoPath !== ""

            onPlayingChanged: {
                if (playing && img.isVideoImage)
                    root.current = img;
            }
        }

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
                target: img
                properties: "opacity,scale"
            }
        }
    }
}