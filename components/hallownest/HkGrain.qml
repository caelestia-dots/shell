import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services

// Subtle hand-painted stone/paper grain overlay for hero Hallownest surfaces
ClippingRectangle {
    id: root

    property real strength: Hallownest.light ? 0.028 : 0.036

    color: "transparent"

    Image {
        anchors.fill: parent
        source: Quickshell.shellPath("assets/hallownest/grain.png")
        fillMode: Image.Tile
        opacity: root.strength
        smooth: false
    }
}
