pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property DrawerVisibilities visibilities
    readonly property Props props: Props {}

    readonly property bool shouldBeActive: visibilities.sidebar && Config.sidebar.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5) * offsetScale
    implicitWidth: Tokens.sizes.sidebar.width
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: 0

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: Tokens.sizes.sidebar.width - Tokens.padding.large * 2
            props: root.props
            visibilities: root.visibilities
        }
    }
}
