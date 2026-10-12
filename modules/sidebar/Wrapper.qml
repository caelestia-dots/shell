pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property bool mirrored
    readonly property Props props: Props {}

    readonly property real slideOffset: (-implicitWidth - 5) * offsetScale
    readonly property bool shouldBeActive: screenState.sidebar && Config.sidebar.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1

    implicitWidth: Tokens.sizes.sidebar.width
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large)
        anchors.leftMargin: root.mirrored ? anchors.margins : Tokens.padding.large
        anchors.rightMargin: root.mirrored ? Tokens.padding.large : anchors.margins
        anchors.bottomMargin: 0

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: Tokens.sizes.sidebar.width - content.anchors.leftMargin - content.anchors.rightMargin
            props: root.props
            screenState: root.screenState
        }
    }
}
