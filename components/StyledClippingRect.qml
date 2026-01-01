import Quickshell.Widgets
import QtQuick

ClippingRectangle {
    id: root

    color: "transparent"

    Behavior on color {
        CAnim {}
    }
}
