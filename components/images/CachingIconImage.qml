pragma ComponentBehavior: Bound

import qs.utils
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    readonly property int status: loader.item?.status ?? Image.Null
    readonly property real actualSize: Math.min(width, height)
    property real implicitSize
    property url source

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: root.source ? root.source.toString().startsWith("image://icon/") ? iconImage : cachingImage : null
    }

    Component {
        id: cachingImage

        CachingImage {
            path: Paths.toLocalFile(root.source)
            fillMode: Image.PreserveAspectFit
        }
    }

    Component {
        id: iconImage

        IconImage {
            source: root.source
            asynchronous: true
        }
    }
}
