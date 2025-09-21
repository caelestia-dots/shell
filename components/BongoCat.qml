pragma ComponentBehavior: Bound

import qs.services
import qs.config
import Caelestia.Services
import QtQuick

Item {
    id: root

    property bool isPlaying: Players.active?.isPlaying ?? false
    property real bpm: Audio.beatTracker.bpm || 120
    property int minInterval: 200
    property real scale: 1.0

    property bool showFrame1: true

    Timer {
        running: root.isPlaying
        interval: Math.max(60000 / root.bpm, root.minInterval)
        repeat: true
        onTriggered: root.showFrame1 = !root.showFrame1
    }

    Image {
        anchors.fill: parent
        source: Config.paths.mediaGif.f1
        visible: root.showFrame1
        fillMode: Image.PreserveAspectFit
    }

    Image {
        anchors.fill: parent
        source: Config.paths.mediaGif.f2
        visible: !root.showFrame1
        fillMode: Image.PreserveAspectFit
    }
}
