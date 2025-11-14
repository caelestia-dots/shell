pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import QtQuick

Item {
    id: root
    anchors.fill: parent

    property string source: Wallpapers.current
    property bool initialized: false
    property int loadersReady: 0
    property int previousCurrent: 2
    property bool initStart: false

    function isVideo(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return false;
        const videoExtensions = [".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".wmv", ".gif"];
        const lowerPath = path.toLowerCase();
        for (let i = 0; i < videoExtensions.length; i++) {
            if (lowerPath.endsWith(videoExtensions[i]))
                return true;
        }
        return false;
    }

    function waitForItem(loader, callback) {
        if (loader.item !== null) {
            callback();
            return;
        }

        // Wait for next frame until item exists
        Qt.callLater(function () {
            waitForItem(loader, callback);
        });
    }

    function switchWallpaper() {
        if (oneLoader.item.isCurrent)
            previousCurrent = 1;
        else if (twoLoader.item.isCurrent)
            previousCurrent = 2;
        if (oneLoader.item.isCurrent) {
            twoLoader.sourceComponent = isVideo(source) ? videoComponent : imageComponent;

            waitForItem(twoLoader, function () {
                twoLoader.item.update(source);
                twoLoader.item.ready.connect(function handler() {
                    oneLoader.item.isCurrent = false;
                    twoLoader.item.isCurrent = true;
                    console.log("source changed from two -> one:", oneLoader.item.isCurrent, "two:", twoLoader.item.isCurrent);
                    twoLoader.item.ready.disconnect(handler);
                });
            });
        } else if (twoLoader.item.isCurrent) {
            oneLoader.sourceComponent = isVideo(source) ? videoComponent : imageComponent;

            waitForItem(oneLoader, function () {
                oneLoader.item.update(source);
                oneLoader.item.ready.connect(function handler() {
                    twoLoader.item.isCurrent = false;
                    oneLoader.item.isCurrent = true;
                    console.log("source changed from one -> one:", oneLoader.item.isCurrent, "two:", twoLoader.item.isCurrent);
                    oneLoader.item.ready.disconnect(handler);
                });
            });
        }
    }

    function tryInitialize(from) {
        loadersReady += 1;

        if (loadersReady < 2)
            return;

        if (previousCurrent === 1) {
            oneLoader.item.isCurrent = true;
            twoLoader.item.isCurrent = false;
        } else {
            oneLoader.item.isCurrent = false;
            twoLoader.item.isCurrent = true;
        }

        initialized = true;
        if (!initStart) {
            switchWallpaper();
            initStart = true;
        }
    }

    Loader {
        id: oneLoader
        asynchronous: true
        anchors.fill: parent
        sourceComponent: isVideo(root.source) ? videoComponent : imageComponent
        onLoaded: tryInitialize("oneLoader")
    }

    Loader {
        id: twoLoader
        asynchronous: true
        anchors.fill: parent
        sourceComponent: isVideo(root.source) ? videoComponent : imageComponent
        onLoaded: tryInitialize("twoLoader")
    }

    onSourceChanged: {
        if (!initialized || !source) {
            return;
        }

        switchWallpaper();
    }

    Component {
        id: imageComponent
        ImageWallpaper {}
    }
    Component {
        id: videoComponent
        VideoWallpaper {}
    }
}
