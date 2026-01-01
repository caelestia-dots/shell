import ".."
import QtQuick
import QtQuick.Effects

MultiEffect {
    property color sourceColor: "black"

    colorization: 1
    brightness: 1 - sourceColor.hslLightness

    Behavior on colorizationColor {
        CAnim {}
    }
}
