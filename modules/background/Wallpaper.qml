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
    property int loadedCount: 0
    property bool itemsReady: false
    property bool initStarted: false

    function isVideo(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return false;
        const videoExtensions = [".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".wmv", ".gif"];
        const lower = path.toLowerCase();
        for (let i = 0; i < videoExtensions.length; i++) {
            if (lower.endsWith(videoExtensions[i]))
                return true;
        }
        return false;
    }

    function waitForBothItems() {
        if (oneLoader.item && twoLoader.item) {
            itemsReady = true;
            initialize();
            return;
        }

        Qt.callLater(waitForBothItems);
    }

    function initialize() {
        if (initStarted)
            return;
        if (loadedCount < 2)
            return;
        if (!itemsReady)
            return;
        initStarted = true;

        oneLoader.item.isCurrent = true;
        twoLoader.item.isCurrent = false;

        initialized = true;

        Qt.callLater(() => switchWallpaper());
    }

    function switchWallpaper() {
        if (!initialized || !source)
            return;
        let active, inactive;

        if (oneLoader.item.isCurrent) {
            active = oneLoader;
            inactive = twoLoader;
        } else {
            active = twoLoader;
            inactive = oneLoader;
        }

        inactive.sourceComponent = isVideo(source) ? videoComponent : imageComponent;

        waitForItem(inactive, function () {
            inactive.item.update(source);
            inactive.item.ready.connect(function handler() {
                active.item.isCurrent = false;
                inactive.item.isCurrent = true;

                // console.log("wallpaper switched:", "one:", oneLoader.item.isCurrent, "two:", twoLoader.item.isCurrent);

                inactive.item.ready.disconnect(handler);
            });
        });
    }

    function waitForItem(loader, callback) {
        if (loader.item) {
            callback();
            return;
        }
        Qt.callLater(() => waitForItem(loader, callback));
    }

    Loader {
        id: oneLoader
        anchors.fill: parent
        asynchronous: true
        sourceComponent: imageComponent
        onLoaded: {
            loadedCount++;
            console.log("oneLoader loaded");
            if (loadedCount === 2)
                waitForBothItems();
        }
    }

    Loader {
        id: twoLoader
        anchors.fill: parent
        asynchronous: true
        sourceComponent: imageComponent
        onLoaded: {
            loadedCount++;
            console.log("twoLoader loaded");
            if (loadedCount === 2)
                waitForBothItems();
        }
    }

    onSourceChanged: {
        if (initialized)
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
