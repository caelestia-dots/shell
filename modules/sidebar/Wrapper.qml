pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    property bool onLeft: false
    property bool docked: false
    property bool dockedAbove: false
    readonly property Props props: Props {}

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

        property real activePadding: Tokens.padding.large
        property real clampedPadding: CUtils.clamp(activePadding - Config.border.thickness, 0, activePadding)

        width: implicitWidth

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: root.onLeft ? clampedPadding : activePadding

        anchors.topMargin: root.docked && root.dockedAbove ? 0 : clampedPadding
        anchors.bottomMargin: root.docked && !root.dockedAbove ? 0 : clampedPadding

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: Tokens.sizes.sidebar.width - content.activePadding - content.clampedPadding
            props: root.props
            screenState: root.screenState
            docked: root.docked
            dockedAbove: root.dockedAbove
        }
    }
}
