pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtMultimedia

Item {
    id: root
    anchors.fill: parent
    signal ready
    property bool shouldPause: false
    property bool isCurrent: false
    property string source: ""
    property bool gamemodeEnabled: GameMode.enabled
    property bool pendingUnload: false
    property string visualMode: !root.isCurrent ? "none" : gamemodeEnabled ? "placeholder" : "video"

    function update(path) {
        if (gamemodeEnabled) {
            root.source = path;
            Qt.callLater(root.ready);
            return;
        }
        path = path.toString();
        if (!path || path.trim() === "")
            return;

        player.source = path;
        root.source = path;

        player.onMediaStatusChanged.connect(function handler() {
            if (player.mediaStatus === MediaPlayer.BufferedMedia || player.mediaStatus === MediaPlayer.LoadedMedia) {
                pausePlayVideo(root.shouldPause);
                Qt.callLater(root.ready);
                player.onMediaStatusChanged.disconnect(handler);
            }
        });
    }

    function pausePlayVideo(shouldPause) {
        if (gamemodeEnabled)
            return;
        if (isCurrent === false)
            return;
        if (player.mediaStatus === MediaPlayer.NoMedia)
            return;

        if (shouldPause || root.shouldPause) {
            if (player && player.mediaStatus !== MediaPlayer.NoMedia) {
                player.pause();
            }
        } else {
            if (player.source && player.mediaStatus !== MediaPlayer.PlayingState) {
                player.play();
            }
        }
    }

    onShouldPauseChanged: {
        pausePlayVideo(root.shouldPause);
    }

    onGamemodeEnabledChanged: {
        if (gamemodeEnabled) {
            player.pause();
            pendingUnload = true;
        } else if (root.isCurrent) {
            update(root.source);
            pausePlayVideo(root.shouldPause);
        }
    }

    MediaPlayer {
        id: player
        autoPlay: false
        loops: MediaPlayer.Infinite
        videoOutput: video
        audioOutput: AudioOutput {
            muted: Config.background.wallpaper.audio.muteAudio
            volume: Config.background.wallpaper.audio.volume
        }

        function tryPlayVideo() {
            if (root.isCurrent) {
                if (source && mediaStatus !== MediaPlayer.PlayingState) {
                    root.pausePlayVideo(root.shouldPause);
                }
            } else {
                if (mediaStatus !== MediaPlayer.NoMedia) {
                    player.pause();
                    root.pendingUnload = true;
                }
            }
        }
    }

    VideoOutput {
        id: video
        anchors.fill: parent
        opacity: root.visualMode === "video" ? 1 : 0
        scale: (root.isCurrent ? 1 : Wallpapers.showPreview ? 1 : 0.8)
        fillMode: VideoOutput.PreserveAspectCrop

        Behavior on opacity {
            Anim {
                onRunningChanged: {
                    if (running)
                        return;
                    if (root.pendingUnload && video.opacity === 0) {
                        player.stop();
                        Qt.callLater(() => {
                            if (root.gamemodeEnabled) {
                                player.source = "";
                                return;
                            }

                            if (!root.isCurrent) {
                                player.source = "";
                            }
                        });

                        root.pendingUnload = false;
                    }
                }
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    StyledRect {
        id: gameModePlaceholder
        opacity: root.visualMode === "placeholder" ? 1 : 0
        anchors.fill: parent
        color: Colours.palette.m3surfaceContainer

        Behavior on opacity {
            Anim {}
        }

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spacing.large

            MaterialIcon {
                text: "stadia_controller"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.extraLarge * 5
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.small

                StyledText {
                    text: qsTr("Video wallpapers are disabled in game mode")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                }
            }
        }
    }

    Connections {
        target: root
        function onIsCurrentChanged() {
            pausePlayVideo(root.shouldPause);
        }
    }
}
