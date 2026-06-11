pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    readonly property alias shape: shape

    property bool hadPrevious
    property color fallbackColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

    // Slight glow to separate from bg
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 1
        shadowColor: Colours.palette.m3outline
        shadowOpacity: 0.3
    }

    Behavior on fallbackColour {
        CAnim {}
    }

    Item {
        id: shapeWrapper

        anchors.fill: parent
        layer.enabled: true
        opacity: root.fallbackColour.a

        MaterialShape {
            id: shape

            implicitSize: root.width
            shape: MaterialShape.Cookie12Sided
            color: Qt.alpha(root.fallbackColour, 1)

            Anim on rotation {
                running: true
                paused: !Players.active?.isPlaying
                from: 360
                to: 0
                duration: 23500
                easing.type: Easing.Linear
                loops: Animation.Infinite
            }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent

        grade: 200
        text: image.status === Image.Error ? "broken_image" : "art_track"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.size((parent.width * 0.35) || 1).build()
        opacity: image.status === Image.Null || image.status === Image.Error ? 1 : 0
        animate: true

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: image.status === Image.Loading ? 1 : 0

        sourceComponent: LoadingIndicator {
            implicitSize: root.width * 0.3
            color: Colours.palette.m3primaryContainer
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    FadeImage {
        id: image

        anchors.fill: parent

        source: Players.getArtUrl(Players.active)

        layer.enabled: true
        layer.effect: Mask {
            maskSource: shapeWrapper
        }
    }
}
