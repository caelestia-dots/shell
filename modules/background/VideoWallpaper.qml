pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtMultimedia

Item {
    id: root
    anchors.fill: parent

    property string source: ""
    property bool isCurrent: false

    signal ready
    signal failed

    property string activePath: ""

    function update(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return;

        root.source = path;
        player.source = path;

        player.onMediaStatusChanged.connect(function handler() {
            if (player.mediaStatus === MediaPlayer.BufferedMedia || player.mediaStatus === MediaPlayer.LoadedMedia) {
                if (root.source === path) {
                    Qt.callLater(() => root.ready());
                    player.onMediaStatusChanged.disconnect(handler);
                }
            }
        });

        player.play();
    }

    MediaPlayer {
        id: player

        autoPlay: false
        loops: MediaPlayer.Infinite

        videoOutput: video
        audioOutput: AudioOutput {
            muted: Config.background.wallpaper.muteAudio
            volume: Config.background.wallpaper.volume
        }
        onErrorOccurred: root.failed()

        function tryPlayVideo() {
            if (root.isCurrent) {
                if (source && mediaStatus !== MediaPlayer.PlayingState) {
                    play();
                }
            } else {
                if (mediaStatus !== MediaPlayer.NoMedia) {
                    stop();
                }
            }
        }
    }

    VideoOutput {
        id: video
        anchors.fill: parent
        opacity: root.isCurrent ? 1 : 0
        scale: Wallpapers.showPreview ? 1 : 0.8
        fillMode: VideoOutput.PreserveAspectCrop
    }

    states: State {
        name: "visible"
        when: root.isCurrent
        PropertyChanges {
            target: video
            opacity: 1
            scale: 1
        }
    }

    transitions: Transition {
        Anim {
            target: video
            properties: "opacity,scale"
        }
    }

    Connections {
        target: root
        function onIsCurrentChanged() {
            player.tryPlayVideo();
        }
    }
}
