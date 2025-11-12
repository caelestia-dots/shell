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

    function update(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return;

        // If same path and already ready, emit ready manually
        // if (player.source === path && player.playbackState === MediaPlayer.PlayingState) {
        //     console.log("Same video, emitting ready manually for:", path);
        //     Qt.callLater(() => root.ready());
        //     return;
        // }
        player.stop();
        root.source = path;
        player.source = path;

        // Connect to status changes
        player.onMediaStatusChanged.connect(function handler() {
            if (player.mediaStatus === MediaPlayer.LoadedMedia) {
                Qt.callLater(() => root.ready());
                console.log("Called ready for video:", path);
                player.onMediaStatusChanged.disconnect(handler);
            }
        });

        // Optionally start playback (loops infinitely)
        player.play();
    }

    MediaPlayer {
        id: player
        autoPlay: false
        loops: MediaPlayer.Infinite

        videoOutput: video
        audioOutput: AudioOutput {}

        onErrorOccurred: root.failed()
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
}
