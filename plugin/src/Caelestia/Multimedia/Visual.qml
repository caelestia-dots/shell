import QtQuick
import QtMultimedia
import Caelestia.Config
import Caelestia.Multimedia

Item {
    id: root

    property alias source: vis.source
    readonly property bool ready: vis.videoReady || image.status === Image.Ready

    opacity: ready ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.anim.durations.expressiveDefaultEffects
            easing: Tokens.anim.expressiveDefaultEffects
        }
    }

    VisualSource {
        id: vis

        sourceSize: Qt.size(root.width, root.height)
        videoOutput: videoOut.item
    }

    Loader {
        id: videoOut

        anchors.fill: parent
        active: vis.type === VisualSource.Live
        sourceComponent: VideoOutput {}
    }

    Image {
        id: image

        anchors.fill: parent
        source: vis.imagePath
        asynchronous: true
    }
}
