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
    clip: true

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

        x: vis.imageRect.x
        y: vis.imageRect.y
        width: vis.imageRect.width
        height: vis.imageRect.height

        active: vis.type === VisualSource.Live
        sourceComponent: VideoOutput {
            fillMode: vis.fillMode
            endOfStreamPolicy: VideoOutput.KeepLastFrame
        }
    }

    Image {
        id: image

        x: vis.imageRect.x
        y: vis.imageRect.y
        width: vis.imageRect.width
        height: vis.imageRect.height

        source: vis.imagePath
        sourceSize: vis.sourceSize
        asynchronous: true
        autoTransform: true
        fillMode: vis.fillMode
    }
}
