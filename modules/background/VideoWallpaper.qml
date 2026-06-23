import QtMultimedia
import QtQuick

Item {
    id: root

    property bool autoStart: true
    property alias error: player.error
    property alias errorString: player.errorString
    property alias mediaStatus: player.mediaStatus
    // Expose active player state
    property alias playbackState: player.playbackState
    readonly property var validVideoExtensions: ["mp4", "webm", "mkv"]
    property url videoSource

    function pause() {
        player.pause();
    }
    function play() {
        if (videoSource.toString())
            player.play();
    }
    function stop() {
        player.stop();
    }

    anchors.fill: parent

    Component.onCompleted: {
        if (videoSource.toString())
            player.source = videoSource;
    }
    onVideoSourceChanged: {
        if (!videoSource.toString()) {
            player.source = "";
            return;
        }
        player.source = videoSource;
    }

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

        audioOutput: mutedOutput
        autoPlay: false
        loops: MediaPlayer.Infinite
        videoOutput: output

        onErrorOccurred: (error, errorString) => {
            if (error !== MediaPlayer.NoError)
                console.warn("VideoPlayer: error:", errorString);
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia)
                console.warn("VideoPlayer: invalid media:", player.source, player.errorString);

            if (mediaStatus === MediaPlayer.LoadedMedia && root.autoStart)
                player.play();
        }
    }
}
