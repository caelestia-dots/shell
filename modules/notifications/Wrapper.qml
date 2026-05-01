import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel

    visible: height > 0
    anchors.topMargin: Tokens.sizes.bar.innerHeight + Math.max(Tokens.padding.smaller, Config.border.thickness) * 2
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: content.implicitHeight

    Content {
        id: content

        visibilities: root.visibilities
    }
}
