pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils

Item {
    id: root

    property string source: Wallpapers.current
    property Item current: one
    property bool completed

    onSourceChanged: {
        if (!source)
            current = null;
        else if (current === one)
            two.update();
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
                            filterLabel: qsTr("Image/video files")
                            filters: Images.validWallpaperExtensions
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

    Slot {
        id: one
    }

    Slot {
        id: two
    }

    component Slot: Item {
        id: slot

        property string path

        function update(): void {
            if (path === root.source)
                root.current = slot;
            else
                path = root.source;
        }

        anchors.fill: parent

        opacity: 0
        scale: Wallpapers.showPreview ? 1 : 0.8

        onPathChanged: {
            if (!path)
                loader.setSource("");
            else if (Images.isValidVideoByName(path))
                loader.setSource("WallpaperVideo.qml", {
                    path
                });
            else if (Images.isAnimatedImageByName(path))
                loader.setSource("WallpaperAnimated.qml", {
                    path
                });
            else
                loader.setSource("WallpaperImage.qml", {
                    path
                });
        }

        // Unload the hidden slot once faded out so videos/gifs stop decoding
        onOpacityChanged: {
            if (opacity === 0 && root.current !== slot)
                path = "";
        }

        states: State {
            name: "visible"
            when: root.current === slot

            PropertyChanges {
                slot.opacity: 1
                slot.scale: 1
            }
        }

        transitions: Transition {
            Anim {
                target: slot
                properties: "opacity,scale"
            }
        }

        Loader {
            id: loader

            anchors.fill: parent
            asynchronous: true

            onStatusChanged: {
                if (status === Loader.Error && Images.isValidVideoByName(slot.path)) {
                    console.warn("Wallpaper: failed to load video player (is QtMultimedia installed?), falling back to a static frame");
                    setSource("WallpaperImage.qml", {
                        path: Wallpapers.videoFramePath(slot.path)
                    });
                }
            }
        }

        Connections {
            function onReadyChanged(): void {
                if (loader.item.ready) // qmllint disable missing-property
                    root.current = slot;
            }

            target: loader.item
        }
    }
}
