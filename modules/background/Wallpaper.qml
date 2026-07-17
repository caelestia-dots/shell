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
    property Item current
    property bool completed
    readonly property bool isPaused: (Hypr.focusedWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false) || GameMode.enabled // qmllint disable unqualified

    function thumbPathFor(videoSource) {
        var dir = videoSource.substring(0, videoSource.lastIndexOf("/"));
        var name = videoSource.substring(videoSource.lastIndexOf("/") + 1);
        var stem = name.substring(0, name.lastIndexOf("."));
        return dir + "/.thumbs/" + stem + ".jpg";
    }

    onSourceChanged: {
        if (!source)
            current = null;
        else if (Images.isVideoFile(source)) {
            if (isPaused)
                current = imgComp.createObject(this, {
                    path: thumbPathFor(source)
                });
            else
                current = videoComp.createObject(this, {
                    path: source
                });
        } else
            current = imgComp.createObject(this, {
                path: source
            });
    }

    onIsPausedChanged: {
        if (!source || !Images.isVideoFile(source))
            return;
        if (current)
            current.destroy();
        if (isPaused)
            current = imgComp.createObject(root, {
                path: thumbPathFor(source)
            });
        else
            current = videoComp.createObject(root, {
                path: source
            });
    }

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                if (Images.isVideoFile(source)) {
                    if (isPaused)
                        current = imgComp.createObject(this, {
                            path: thumbPathFor(source)
                        });
                    else
                        current = videoComp.createObject(this, {
                            path: source
                        });
                } else
                    current = imgComp.createObject(this, {
                        path: source
                    });
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

    Component {
        id: imgComp

        CachingImage {
            id: img

            anchors.fill: parent

            opacity: 0

            onStatusChanged: {
                if (status === Image.Ready)
                    anim.start();
            }

            Anim on opacity {
                id: anim

                type: Anim.SlowEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== img && (root.current?.status === Image.Ready || root.current?.status === undefined) // qmllint disable missing-property
                interval: anim.duration
                onTriggered: img.destroy()
            }
        }
    }

    Component {
        id: videoComp

        Item {
            id: videoContainer

            property string path

            anchors.fill: root
            opacity: 0

            MediaPlayer {
                id: player

                source: videoContainer.path ? "file://" + videoContainer.path : ""
                videoOutput: output
                loops: MediaPlayer.Infinite
                autoPlay: true

                onPlaybackStateChanged: function (playbackState) {
                    if (playbackState === MediaPlayer.PlayingState)
                        videoAnim.start();
                }

                onErrorOccurred: function (error, errorString) {
                    console.warn("Video wallpaper error:", errorString);
                }
            }

            VideoOutput {
                id: output

                anchors.fill: videoContainer
                fillMode: VideoOutput.PreserveAspectCrop
            }

            Anim on opacity {
                id: videoAnim

                type: Anim.SlowEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== videoContainer // qmllint disable missing-property
                interval: videoAnim.duration
                onTriggered: videoContainer.destroy()
            }
        }
    }
}
