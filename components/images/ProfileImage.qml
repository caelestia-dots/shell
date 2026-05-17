pragma ComponentBehavior: Bound

import QtQuick
import Caelestia

Item {
    id: root

    property string path
    property string _format: CUtils.imageFormat(path)

    readonly property int status: (loader.item as Image)?.status ?? Image.Null

    function reload(): void {
        _format = Qt.binding(() => CUtils.imageFormat(path));
        loader.active = false;
        loader.active = true;
    }

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: root._format === "gif" ? animatedComponent : cachingComponent
    }

    Component {
        id: animatedComponent

        AnimatedImage {
            anchors.fill: parent
            fillMode: AnimatedImage.PreserveAspectCrop
            asynchronous: true
            cache: false
            playing: true
            source: Qt.resolvedUrl(root.path)
        }
    }

    Component {
        id: cachingComponent

        CachingImage {
            anchors.fill: parent
            cache: false
            path: root.path
        }
    }
}
