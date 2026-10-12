import QtQuick
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property Item sidebarPanel
    required property bool utilitiesOnTop
    required property bool mirrored
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property alias utilitiesPanel: content.utilitiesPanel

    visible: height > 0
    anchors.topMargin: -5
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
        availableHeight: Math.max(0, root.parent.height - (root.utilitiesOnTop ? Math.max(0, root.utilitiesPanel.y + root.utilitiesPanel.height) : 0))
        utilitiesOnTop: root.utilitiesOnTop
        mirrored: root.mirrored
    }
}
