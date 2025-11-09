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

    property string source: ""
    property bool isCurrent: false
    signal ready
    signal failed

    function update(explicitSource) {
        const target = explicitSource || source;
        if (!target || target.trim() === "")
            return;

        root.source = target;
        img.source = target;

        if (img.status === Image.Ready)
            Qt.callLater(() => root.ready());
    }

    Component.onCompleted: {
        if (isCurrent && img.status === Image.Ready)
            Qt.callLater(() => root.ready());
    }

    CachingImage {
        id: img
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        path: root.source
        opacity: root.isCurrent ? 1 : 0
        scale: Wallpapers.showPreview ? 1 : 0.8

        onStatusChanged: {
            if (status === Image.Ready && root.source)
                Qt.callLater(() => root.ready());
            else if (status === Image.Error)
                Qt.callLater(() => root.failed());
        }

        states: State {
            name: "visible"
            when: root.isCurrent
            PropertyChanges {
                target: img
                opacity: 1
                scale: 1
            }
        }

        transitions: Transition {
            Anim {
                target: img
                properties: "opacity,scale"
            }
        }
    }
}
