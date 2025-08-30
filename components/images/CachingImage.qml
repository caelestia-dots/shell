import qs.utils
import Caelestia
import Quickshell
import QtQuick

Image {
    id: root

    property alias path: manager.path

    property int sourceWidth
    property int sourceHeight

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: sourceWidth
    sourceSize.height: sourceHeight

    Connections {
        target: QsWindow.window

        function onDevicePixelRatioChanged(): void {
            manager.updateSource();
        }
    }

    CachingImageManager {
        id: manager

        item: root
        cacheDir: Paths.imagecache
    }
}
