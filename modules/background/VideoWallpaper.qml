import QtQuick
import QtMultimedia

Item {
    id: root

    property url videoSource
    property bool autoStart: true
    readonly property var validVideoExtensions: ["mp4", "webm", "mkv"]

    // Expose active player state
    property alias playbackState: player.playbackState
    property alias mediaStatus: player.mediaStatus
    property alias error: player.error
    property alias errorString: player.errorString

    function play() {
        if (videoSource.toString())
            player.play();
    }

    function pause() {
        player.pause();
    }

    function stop() {
        player.stop();
    }

    anchors.fill: parent

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    AudioOutput {
        id: mutedOutput
        muted: true
        volume: 0
    }

    MediaPlayer {
        id: player

        videoOutput: output
        audioOutput: mutedOutput
        loops: MediaPlayer.Infinite
        autoPlay: false

        onErrorOccurred: (error, errorString) => {
            if (error !== MediaPlayer.NoError)
                console.warn("VideoPlayer: error:", errorString);
        }

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia)
                console.warn("VideoPlayer: invalid media:", player.source, player.errorString);

            if (mediaStatus === MediaPlayer.LoadedMedia && root.autoStart) {
                player.play();
            }
        }
    }

    onVideoSourceChanged: {
        if (!videoSource.toString()) {
            player.source = "";
            return;
        }
        player.source = videoSource;
    }

    Component.onCompleted: {
        if (videoSource.toString()) {
            player.source = videoSource;
        }
    }
}
