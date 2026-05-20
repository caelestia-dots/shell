import QtQuick
import QtMultimedia
import Quickshell

Item {
    id: root
    objectName: "badapple"

    property var screenModel: null

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    MediaPlayer {
        id: mediaPlayer
        source: `${Quickshell.shellDir}/assets/badapple.mp4`
        videoOutput: videoOutput
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
    }

    AudioOutput {
        id: audioOutput
    }

    Component.onCompleted: {
        mediaPlayer.audioOutput = audioOutput;
        root.isFirstInstance = (BadApplePlayer.firstInstance === null);
        BadApplePlayer.firstInstance = root;
    }

    property bool isFirstInstance: false

    function play() {
        BadApplePlayer.play();
    }

    function stop() {
        BadApplePlayer.stop();
    }

    readonly property bool playing: BadApplePlayer.shouldPlay

    visible: BadApplePlayer.shouldPlay

    onVisibleChanged: {
        if (visible) {
            mediaPlayer.play();
            audioOutput.muted = !isFirstInstance;
        } else {
            mediaPlayer.stop();
        }
    }

    Connections {
        target: BadApplePlayer

        function onToggleRequested() {
            root.visible = BadApplePlayer.shouldPlay;
            if (BadApplePlayer.shouldPlay) {
                mediaPlayer.play();
                audioOutput.muted = !isFirstInstance;
            } else {
                mediaPlayer.stop();
            }
        }
    }

    Component.onDestruction: {
        if (BadApplePlayer.firstInstance === root) {
            BadApplePlayer.firstInstance = null;
        }
    }
}