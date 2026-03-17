pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.services
import QtQuick

Item {
    id: root
    anchors.fill: parent

    property bool isCurrent: false

    signal ready

    function update(explicitSource) {
        explicitSource = explicitSource.toString();
        const target = explicitSource;

        if (img.path === target && img.status === Image.Ready) {
            Qt.callLater(() => root.ready());
            return;
        }

        img.path = target;

        img.onStatusChanged.connect(function handler() {
            if (img.status === Image.Ready) {
                Qt.callLater(() => root.ready());
                img.onStatusChanged.disconnect(handler);
            }
        });
    }

    CachingImage {
        id: img
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        opacity: root.isCurrent ? 1 : 0
        scale: (root.isCurrent ? 1 : Wallpapers.showPreview ? 1 : 0.8)

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }
    }
}
