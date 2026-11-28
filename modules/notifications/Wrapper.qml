import QtQuick
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property alias utilitiesPanel: content.utilitiesPanel

    // Width cap applied by the LayoutManager
    property real layoutMaxWidth: 0
    property real layoutShiftX: 0
    property real layoutShiftY: 0
    property bool layoutHidden: false
    readonly property real naturalWidth: Math.max(sidebarPanel.width, content.naturalWidth)

    visible: height > 0 && !layoutHidden
    anchors.topMargin: -5 + layoutShiftY
    anchors.rightMargin: -layoutShiftX
    implicitWidth: layoutMaxWidth > 0 ? Math.min(naturalWidth, layoutMaxWidth) : naturalWidth
    implicitHeight: content.implicitHeight

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
        layoutMaxWidth: root.layoutMaxWidth
    }
}
