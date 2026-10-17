pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Caelestia.Config
import Caelestia.Multimedia

Item {
    id: root

    property alias source: vis.source
    property alias fillMode: vis.fillMode
    property alias playing: vis.playing
    readonly property alias type: vis.type
    property bool animate: true
    readonly property bool ready: vis.videoReady || image.status === Image.Ready

    opacity: !animate || ready ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.anim.durations.expressiveDefaultEffects
            easing: Tokens.anim.expressiveDefaultEffects
        }
    }

    VisualSource {
        id: vis

        videoOutput: videoOut.item
        sizeSource: root
    }

    Loader {
        id: videoOut

        anchors.fill: parent
        active: vis.type === VisualSource.Live
        sourceComponent: VideoOutput {
            fillMode: vis.fillMode
        }
    }

    Image {
        id: image

        anchors.fill: parent
        source: vis.imagePath
        asynchronous: true
        fillMode: vis.fillMode
    }
}
