pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Caelestia.Services
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property ShellScreen screen
    required property Wallpaper wallpaper

    ServiceRef {
        service: Audio.cava
    }

    MultiEffect {
        anchors.fill: parent
        source: root.wallpaper
        maskSource: wrapper
        maskEnabled: true
        blurEnabled: true
        blur: 1
        blurMax: 32
        autoPaddingEnabled: false
    }

    Item {
        id: wrapper

        anchors.fill: parent
        layer.enabled: true

        Item {
            id: content

            anchors.fill: parent
            anchors.margins: Visibilities.getBorderThickness(root.screen)
            anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Appearance.spacing.small * Config.background.visualiser.spacing

            Side {}
            Side {
                isRight: true
            }

            Behavior on anchors.leftMargin {
                Anim {}
            }
        }
    }

    component Side: Repeater {
        id: side

        property bool isRight

        model: Config.services.visualiserBars

        ClippingRectangle {
            id: bar

            required property int modelData
            property real value: Math.max(0, Math.min(1, Audio.cava.values[side.isRight ? modelData : side.count - modelData - 1]))

            clip: true

            x: modelData * ((content.width * 0.4) / Config.services.visualiserBars) + (side.isRight ? content.width * 0.6 : 0)
            implicitWidth: (content.width * 0.4) / Config.services.visualiserBars - Appearance.spacing.small * Config.background.visualiser.spacing

            y: content.height - height
            implicitHeight: bar.value * content.height * 0.4

            color: "transparent"
            topLeftRadius: Appearance.rounding.small * Config.background.visualiser.rounding
            topRightRadius: Appearance.rounding.small * Config.background.visualiser.rounding

            Rectangle {
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius

                gradient: Gradient {
                    orientation: Gradient.Vertical

                    GradientStop {
                        position: 0
                        color: Qt.alpha(Colours.palette.m3primary, 0.7)

                        Behavior on color {
                            CAnim {}
                        }
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Colours.palette.m3inversePrimary, 0.7)

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }

                anchors.left: parent.left
                anchors.right: parent.right
                y: parent.height - height
                implicitHeight: content.height * 0.4
            }

            Behavior on value {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }
        }
    }
}
