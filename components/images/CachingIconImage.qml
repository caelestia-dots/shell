pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.utils

Item {
    id: root

    // Easier (and more efficient) to ignore it than to check type and cast
    readonly property int status: loader.item?.status ?? Image.Null // qmllint disable missing-property
    readonly property real actualSize: Math.min(width, height)
    property real implicitSize
    property url source

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Loader {
        id: loader

        asynchronous: true
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
