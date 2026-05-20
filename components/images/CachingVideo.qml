import QtQuick
import QtMultimedia
import Quickshell
import Caelestia.Config
import qs.services

Item {
    id: root

    property string path
    property bool isFirstInstance: false

    property alias playing: mediaPlayer.playing
    property alias playbackState: mediaPlayer.playbackState

    AudioOutput {
        id: audioOutput
    }

    Binding {
        target: audioOutput
        property: "muted"
        value: !root.isFirstInstance || !Config.background.videoWallpaperSoundEnabled
    }

    MediaPlayer {
        id: mediaPlayer

        source: path || ""
        videoOutput: videoOutput
        loops: MediaPlayer.Infinite
        autoPlay: true
        audioOutput: audioOutput
    }

    VideoOutput {
        id: videoOutput

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop

        Component.onDestruction: {
            mediaPlayer.stop();
        }
    }

    Component.onCompleted: {
        isFirstInstance = (VideoWallpaperPlayer.firstInstance === null);
        VideoWallpaperPlayer.firstInstance = root;
    }

    Connections {
        target: Config.background

        function onVideoWallpaperSoundEnabledChanged() {
            updateMute();
        }
    }

    function updateMute() {
        audioOutput.muted = !isFirstInstance || !Config.background.videoWallpaperSoundEnabled;
    }

    Component.onDestruction: {
        if (VideoWallpaperPlayer.firstInstance === root) {
            VideoWallpaperPlayer.firstInstance = null;
        }
    }

    onPathChanged: {
        mediaPlayer.source = path || "";
        if (path)
            mediaPlayer.play();
    }
}