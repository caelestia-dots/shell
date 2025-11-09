pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import qs.config
import qs.utils
import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services

Item {
    id: root
    anchors.fill: parent

    // You can reuse the same source property that Wallpaper.qml uses
    property string source

    onSourceChanged: {
        player.source = root.source;
    }

    // Automatically play and loop
    MediaPlayer {
        id: player
        loops: MediaPlayer.Infinite
        autoPlay: true
        source: root.source
        videoOutput: vout
        // muted: true
        Component.onCompleted: {
            console.log("source: " + root.source);
        }
    }

    VideoOutput {
        id: vout
        anchors.fill: parent
        // source: player
        fillMode: VideoOutput.PreserveAspectCrop
        opacity: player.playbackState === MediaPlayer.PlayingState ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }
    }

    // optional: show an error message overlay if something fails
    Text {
        anchors.centerIn: parent
        color: "white"
        text: player.error !== MediaPlayer.NoError ? player.errorString : ""
    }
}
