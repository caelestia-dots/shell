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

    readonly property bool shouldBeActive: Config.background.visualiser.enabled && (!Config.background.visualiser.autoHide || Hypr.monitorFor(screen).activeWorkspace.toplevels.values.every(t => t.lastIpcObject.floating))
    property real offset: shouldBeActive ? 0 : screen.height * 0.2

    opacity: shouldBeActive ? 1 : 0

    Loader {
        anchors.fill: parent
        active: root.opacity > 0 && Config.background.visualiser.blur

        sourceComponent: MultiEffect {
            source: root.wallpaper
            maskSource: wrapper
            maskEnabled: true
            blurEnabled: true
            blur: 1
            blurMax: 32
            autoPaddingEnabled: false
        }
    }

    Item {
        id: wrapper

        anchors.fill: parent
        layer.enabled: true

        Loader {
            anchors.fill: parent
            anchors.topMargin: root.offset
            anchors.bottomMargin: -root.offset

            active: root.opacity > 0

            sourceComponent: Item {
                ServiceRef {
                    service: Audio.cava
                }

                Item {
                    id: content

                    anchors.fill: parent
                    anchors.margins: Config.border.thickness
                    anchors.leftMargin: Visibilities.bars.get(root.screen).exclusiveZone + Appearance.spacing.small * Config.background.visualiser.spacing

                    Side {
                        content: content
                    }
                    Side {
                        content: content
                        isRight: true
                    }

                    Behavior on anchors.leftMargin {
                        Anim {}
                    }
                }
            }
        }
    }

    Behavior on offset {
        Anim {}
    }

    Behavior on opacity {
        Anim {}
    }

    component Side: Repeater {
        id: side

        required property Item content
        property bool isRight

        model: Config.services.visualiserBars

        ClippingRectangle {
            id: bar

            required property int modelData
            property real value: Math.max(0, Math.min(1, Audio.cava.values[side.isRight ? modelData : side.count - modelData - 1]))

            clip: true

            x: modelData * ((side.content.width * 0.4) / Config.services.visualiserBars) + (side.isRight ? side.content.width * 0.6 : 0)
            implicitWidth: (side.content.width * 0.4) / Config.services.visualiserBars - Appearance.spacing.small * Config.background.visualiser.spacing

            y: side.content.height - height
            implicitHeight: bar.value * side.content.height * 0.4

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
                implicitHeight: side.content.height * 0.4
            }

            Behavior on value {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }
        }
    }
}
