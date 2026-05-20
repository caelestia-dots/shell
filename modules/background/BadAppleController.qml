pragma Singleton

import QtQuick
import QtMultimedia

QtObject {
    function play(): void {
        video.play();
    }

    function stop(): void {
        video.stop();
    }

    readonly property bool playing: video.playing

    property var video: null
}