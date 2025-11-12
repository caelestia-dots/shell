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

    function isVideo(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return false;
        const videoExtensions = [".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".wmv"];
        const lowerPath = path.toLowerCase();
        for (let i = 0; i < videoExtensions.length; i++) {
            if (lowerPath.endsWith(videoExtensions[i]))
                return true;
        }
        return false;
    }

    function switchWallpaper() {
        if (oneLoader.item.isCurrent) {
            twoLoader.item.update(source);
            twoLoader.item.ready.connect(function handler() {
                oneLoader.item.isCurrent = false;
                twoLoader.item.isCurrent = true;
                console.log("source changed -> one:", oneLoader.item.isCurrent, "two:", twoLoader.item.isCurrent);
                twoLoader.item.ready.disconnect(handler);
            });
        } else if (twoLoader.item.isCurrent) {
            oneLoader.item.update(source);
            oneLoader.item.ready.connect(function handler() {
                twoLoader.item.isCurrent = false;
                oneLoader.item.isCurrent = true;
                console.log("source changed -> one:", oneLoader.item.isCurrent, "two:", twoLoader.item.isCurrent);
                oneLoader.item.ready.disconnect(handler);
            });
        }
    }

    function tryInitialize(from) {
        initialized: false;
        console.log("got init from: ", from);
        if (!oneLoader.item || !twoLoader.item)
            return;

        oneLoader.item.isCurrent = true;

        switchWallpaper();

        console.log("from init: ", "one: ", oneLoader.item.isCurrent, " two: ", twoLoader.item.isCurrent);

        initialized = true;
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

    // --- Alternation logic ---
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
