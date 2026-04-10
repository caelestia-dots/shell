import QtQuick
import Quickshell.Widgets

ClippingRectangle {
    id: root

    color: "transparent"

    Behavior on color {
        CAnim {}
    }
}
