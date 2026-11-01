import QtQuick
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property PanelGeometry osdGeometry
    required property PanelGeometry sessionGeometry
    required property real sidebarWidth
    required property real utilitiesHeight

    readonly property PanelGeometry geometry: PanelGeometry {
        x: root.x
        y: root.y
        width: root.width
        height: root.height
    }

    visible: height > 0
    implicitWidth: Math.max(sidebarWidth, content.implicitWidth)
    implicitHeight: content.implicitHeight

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
        osdGeometry: root.osdGeometry
        sessionGeometry: root.sessionGeometry
        utilitiesHeight: root.utilitiesHeight
    }
}
