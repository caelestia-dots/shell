pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    readonly property Props props: Props {}

    readonly property bool shouldBeActive: screenState.sidebar && Config.sidebar.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    // Width cap applied by the LayoutManager
    property real layoutMaxWidth: 0
    property real layoutShiftX: 0
    property real layoutShiftY: 0
    property bool layoutHidden: false
    readonly property real naturalWidth: Tokens.sizes.sidebar.width

    visible: offsetScale < 1 && !layoutHidden
    anchors.rightMargin: (-implicitWidth - 5) * offsetScale - layoutShiftX
    implicitWidth: layoutMaxWidth > 0 ? Math.min(naturalWidth, layoutMaxWidth) : naturalWidth
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Tokens.padding.large
        anchors.margins: CUtils.clamp(anchors.leftMargin - Config.border.thickness, 0, anchors.leftMargin)
        anchors.bottomMargin: 0

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: root.implicitWidth - content.anchors.leftMargin - content.anchors.margins
            props: root.props
            screenState: root.screenState
        }
    }
}
