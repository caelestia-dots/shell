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

    // Currently visible wallpaper. When `source` changes, the previous media
    // is destroyed once the new one signals ready, so the old stays visible
    // until the new fades in. Mirrors the upstream caelestia engine: simple
    // one-item-at-a-time replacement, no A/B preloading.
    property var current

    property string source: Wallpapers.current
    property bool completed: false

    function _createMedia(path: string): var {
        const ft = Wallpapers.getFileType(path);
        if (ft === "gif") return gifMedia.createObject(root, { sourceFile: path });
        if (ft === "video") return videoMedia.createObject(root, { sourceFile: path });
        return imageMedia.createObject(root, { sourceFile: path });
    }

    onSourceChanged: {
        if (!source) {
            if (current) { current.destroy(); current = null; }
        } else {
            current = _createMedia(source);
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            if (source) current = _createMedia(source);
            completed = true;
        });
    }

    // ── Placeholder when no wallpaper is set ────────────────────────────

    Loader {
        asynchronous: true
        anchors.fill: parent

        active: root.completed && !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

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
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    // ── Media components ───────────────────────────────────────────────
    //
    // Each wrapper carries the source path, paints itself full-bleed via an
    // inner Image/AnimatedImage/Video, and exposes two things to the engine:
    //
    //   1. `ready` flips to true on the first frame being decodable / playable
    //   2. An `Anim on opacity` ramp from 0 → 1 once that happens
    //
    // The Timer at the bottom watches `root.current` and self-destructs once
    // it's no longer the active media and the new one is ready, so the old
    // layer stays visible for the full duration of the new layer's ramp.

    Component {
        id: imageMedia

        Item {
            id: wrapItem

            anchors.fill: parent
            property string sourceFile: ""
            property bool ready: false
            opacity: 0

            CachingImage {
                anchors.fill: parent
                path: wrapItem.sourceFile
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true

                onStatusChanged: {
                    if (status === Image.Ready && !wrapItem.ready) {
                        wrapItem.ready = true;
                        anim.restart();
                    }
                }
            }

            Anim on opacity {
                id: anim

                type: Anim.DefaultEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== wrapItem && root.current?.ready === true
                interval: anim.duration + 50
                onTriggered: wrapItem.destroy()
            }
        }
    }

    Component {
        id: gifMedia

        Item {
            id: wrapItem

            anchors.fill: parent
            property string sourceFile: ""
            property bool ready: false
            opacity: 0

            AnimatedImage {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                playing: true
                asynchronous: true
                source: wrapItem.sourceFile ? "file://" + wrapItem.sourceFile : ""

                onStatusChanged: {
                    if (status === AnimatedImage.Ready && !wrapItem.ready) {
                        wrapItem.ready = true;
                        anim.restart();
                    }
                }
            }

            Anim on opacity {
                id: anim

                type: Anim.DefaultEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== wrapItem && root.current?.ready === true
                interval: anim.duration + 50
                onTriggered: wrapItem.destroy()
            }
        }
    }

    Component {
        id: videoMedia

        Item {
            id: wrapItem

            anchors.fill: parent
            property string sourceFile: ""
            property bool ready: false
            opacity: 0

            Video {
                id: video

                anchors.fill: parent
                loops: MediaPlayer.Infinite
                autoPlay: true
                muted: true
                fillMode: VideoOutput.PreserveAspectCrop
                source: wrapItem.sourceFile ? "file://" + wrapItem.sourceFile : ""

                onPlaybackStateChanged: {
                    if (wrapItem.ready) return;
                    if (playbackState === MediaPlayer.PlayingState
                        || playbackState === MediaPlayer.Loaded) {
                        wrapItem.ready = true;
                        anim.restart();
                    }
                }

                onErrorOccurred: (error, errorString) => {
                    console.warn("Wallpaper video error:", errorString);
                    if (!wrapItem.ready) {
                        wrapItem.ready = true;
                        anim.restart();
                    }
                }
            }

            Anim on opacity {
                id: anim

                type: Anim.DefaultEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== wrapItem && root.current?.ready === true
                interval: anim.duration + 50
                onTriggered: wrapItem.destroy()
            }
        }
    }
}
