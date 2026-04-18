import QtQuick
import QtQuick.Effects
import qs.components

MultiEffect {
    property color sourceColor: "black"

    colorization: 1
    brightness: 1 - sourceColor.hslLightness

    Behavior on colorizationColor {
        CAnim {}
    }
}
