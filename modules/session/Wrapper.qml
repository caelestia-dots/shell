pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property bool sidebarVisible
    readonly property real nonAnimWidth: content.implicitWidth

    required property bool mirrored
    readonly property real slideOffset: (-implicitWidth - 5 - sidebarOffset) * offsetScale
    readonly property bool shouldBeActive: screenState.session && Config.session.enabled
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarOffset: sidebarVisible ? 14 : 0

    visible: offsetScale < 1

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight || 510 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.mirrored ? undefined : parent.left
        anchors.right: root.mirrored ? parent.right : undefined

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
