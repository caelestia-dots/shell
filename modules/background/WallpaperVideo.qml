import QtQuick
import QtMultimedia
import Quickshell
import qs.services

VideoOutput {
    id: root

    required property string path
    readonly property bool ready: player.mediaStatus === MediaPlayer.LoadedMedia || player.mediaStatus === MediaPlayer.BufferingMedia || player.mediaStatus === MediaPlayer.BufferedMedia // qmllint disable unqualified
    readonly property bool shouldPlay: Wallpapers.animationsActiveOn((QsWindow.window as QsWindow)?.screen ?? null)

    function syncPlayback(): void {
        if (!ready)
            return;

        if (shouldPlay)
            player.play();
        else
            player.pause();
    }

    fillMode: VideoOutput.PreserveAspectCrop // qmllint disable unqualified

    onReadyChanged: syncPlayback()
    onShouldPlayChanged: syncPlayback()

    MediaPlayer {
        id: player

        source: root.path
        videoOutput: root
        loops: MediaPlayer.Infinite // qmllint disable unqualified
    }
}
