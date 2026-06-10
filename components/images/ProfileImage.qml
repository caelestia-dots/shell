pragma ComponentBehavior: Bound

import QtQuick
import Caelestia

Item {
    id: root

    property string path
    property int _reloadToken
    readonly property string _format: {
        _reloadToken;
        return CUtils.imageFormat(path);
    }

    readonly property int status: loader.item?.status ?? Image.Null // qmllint disable missing-property

    function reload(): void {
        _reloadToken++;
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
