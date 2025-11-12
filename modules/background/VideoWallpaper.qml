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

    // Track the currently active path to prevent old handlers from firing
    property string activePath: ""

    function update(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return;

        root.source = path;
        player.source = path;

        console.log("update ⚠️ Switching video to:", path);

        player.onMediaStatusChanged.connect(function handler() {
            switch (player.mediaStatus) {
            case MediaPlayer.LoadedMedia:
                if (root.source === path) {
                    console.log("Media loaded LoadedMedia, emitting ready:", path);
                    Qt.callLater(() => root.ready());
                    player.onMediaStatusChanged.disconnect(handler);
                }
                break;
            default:
                break;
            }
        });

        player.play();
    }

    MediaPlayer {
        id: player

        autoPlay: false
        loops: MediaPlayer.Infinite

        videoOutput: video
        audioOutput: AudioOutput {}

        onErrorOccurred: root.failed()

        function updateEnabled() {
            if (root.isCurrent) {
                if (source && mediaStatus !== MediaPlayer.PlayingState) {
                    console.log("Starting video:", source);
                    play();
                }
            } else {
                if (mediaStatus !== MediaPlayer.NoMedia) {
                    console.log("Stopping video:", source);
                    stop();
                    source = "";
                }
            }
        }
    }

    VideoOutput {
        id: video
        anchors.fill: parent
        opacity: root.isCurrent ? 1 : 0
        scale: Wallpapers.showPreview ? 1 : 0.8
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
            player.updateEnabled();
        }
    }
}
