import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.services

Item {
    id: root

    property real size: 20
    property bool filled: true
    property color colour: Hallownest.soul
    property bool glow

    implicitWidth: size * 59.27 / 79.38
    implicitHeight: size

    Image {
        anchors.fill: parent
        source: Quickshell.shellPath("assets/hallownest/health-mask.svg")
        sourceSize.width: Math.ceil(width * 2)
        sourceSize.height: Math.ceil(height * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: root.filled ? 1 : (Hallownest.light ? 0.28 : 0.5)
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: Hallownest.light ? 0.85 : (root.colour === Hallownest.soul ? 0 : 0.6)
            colorizationColor: root.colour
            brightness: Hallownest.light ? -0.18 : (root.filled ? 0 : -0.35)
            saturation: Hallownest.isMono || !root.filled ? -1 : 0
            shadowEnabled: root.glow
            shadowColor: Hallownest.soul
            shadowOpacity: 0.6
            shadowBlur: 0.8
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 24
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
