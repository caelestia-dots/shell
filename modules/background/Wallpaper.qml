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
    property ImageWallpaper current: null
    property bool switching: false
    property bool initialized: false

    function finalizeSwitch(candidate) {
        console.log("[Wallpaper.qml] finalizeSwitch:", candidate === one ? "one" : "two");

        if (!candidate || root.current === candidate || root.switching)
            return;

        root.switching = true;

        const old = root.current;
        root.current = candidate;

        Qt.callLater(() => {
            candidate.isCurrent = true;

            if (old && old !== candidate) {
                Qt.callLater(() => {
                    old.isCurrent = false;
                    root.switching = false;
                });
            } else {
                root.switching = false;
            }
        });
    }

    function onLoadFailed(candidate) {
        console.warn("Wallpaper failed to load:", candidate.source);
    }

    onSourceChanged: {
        console.log("[Wallpaper.qml] Wallpaper source changed to:", source);
        if (!source)
            return;

        if (!initialized) {
            console.log("[Wallpaper.qml] Ignoring initial change");
            return;
        }

        const inactive = (root.current === one) ? two : one;
        console.log("[Wallpaper.qml] Preparing inactive:", inactive === one ? "one" : "two");

        const handler = function () {
            if (!inactive.source || inactive.source.trim() === "") {
                console.warn("[Wallpaper.qml] Skipping ready() — empty source");
                return;
            }
            console.log("[Wallpaper.qml] Inactive wallpaper ready:", inactive.source);
            Qt.callLater(() => finalizeSwitch(inactive));
            inactive.ready.disconnect(handler);
        };

        inactive.ready.connect(handler);
        inactive.update(source);
    }

    Component.onCompleted: {
        if (source) {
            one.update(source);
            one.ready.connect(function handler() {
                console.log("[Wallpaper.qml] First wallpaper ready:", one.source);
                one.isCurrent = true;
                root.current = one;
                root.initialized = true;
                one.ready.disconnect(handler);
            });
        }
    }

    // Double-buffered wallpapers
    ImageWallpaper {
        id: one
        anchors.fill: parent
        z: 0
        isCurrent: true
        onFailed: onLoadFailed(one)
    }

    ImageWallpaper {
        id: two
        anchors.fill: parent
        z: 1
        isCurrent: false
        onFailed: onLoadFailed(two)
    }
}
