pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components.hallownest
import qs.services

// Resting at a bench: the edges darken, light rays fall on the bench (bottom centre) with
// floating motes, and a Soul flash bursts from it. Purely visual, takes no input.
Item {
    id: root

    property real progress // darkness and rays, 0..1
    property real rays: progress
    property real flash // Soul burst from the bench, 0..1
    property real breath
    readonly property real benchY: height * 0.93

    SequentialAnimation on breath {
        running: root.visible && root.rays > 0
        loops: Animation.Infinite

        NumberAnimation {
            to: 1
            duration: 3600
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 0
            duration: 3600
            easing.type: Easing.InOutSine
        }
    }

    Shape {
        anchors.fill: parent
        opacity: root.progress
        visible: opacity > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.width / 2
                centerY: root.benchY
                centerRadius: Math.max(root.width, root.height) * 0.75
                focalX: centerX
                focalY: centerY

                GradientStop {
                    position: 0
                    color: Qt.alpha(Hallownest.void_, 0.15)
                }
                GradientStop {
                    position: 0.45
                    color: Qt.alpha(Hallownest.void_, 0.7)
                }
                GradientStop {
                    position: 1
                    color: Hallownest.void_
                }
            }

            PathRectangle {
                width: root.width
                height: root.height
            }
        }
    }

    // Light rays falling from above onto the bench
    Item {
        anchors.fill: parent
        opacity: root.rays
        visible: opacity > 0

        Item {
            anchors.fill: parent
            layer.enabled: root.visible && root.rays > 0
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.75
                blurMax: 32
            }

            Repeater {
                model: 5

                Rectangle {
                    required property int index
                    readonly property real spread: (index - 2) * 9

                    x: root.width / 2 - width / 2 + (index - 2) * root.width * 0.02
                    y: -root.height * 0.15
                    width: root.width * (0.04 + (index % 2) * 0.02)
                    height: root.benchY + root.height * 0.25
                    rotation: -spread
                    transformOrigin: Item.Top
                    opacity: 0.09 + (index === 2 ? 0.05 : 0) + (index % 2 === 0 ? root.breath : 1 - root.breath) * 0.035
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "transparent"
                        }
                        GradientStop {
                            position: 0.7
                            color: Hallownest.soul
                        }
                        GradientStop {
                            position: 1
                            color: "transparent"
                        }
                    }
                }
            }
        }

        SoulParticles {
            x: root.width / 2 - width / 2
            y: root.benchY - height
            width: root.width * 0.3
            height: root.benchY * 0.8
            count: 18
            size: 3
            duration: 7000
            running: visible
        }
    }

    // Soul flash from the bench
    Shape {
        anchors.fill: parent
        opacity: root.flash
        visible: opacity > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.width / 2
                centerY: root.benchY
                centerRadius: root.height * (0.15 + root.flash * 0.45)
                focalX: centerX
                focalY: centerY

                GradientStop {
                    position: 0
                    color: Qt.alpha(Hallownest.soul, 0.85)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }

            PathRectangle {
                width: root.width
                height: root.height
            }
        }
    }
}
