pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.effects
import qs.components.widgets
import qs.services

StyledRect {
    id: root

    readonly property real fontScale: {
        const diff = width / 391 - 1; // 391 is the width at 1080 height screen
        return 1 + Math.pow(Math.abs(diff), 0.8) * Math.sign(diff);
    }

    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.large

        Resource {
            id: cpu

            icon: "memory"
            value: Math.round(Cpu.percentage * 100) + "%"
            fillValue: Cpu.percentage
            colour: Colours.palette.m3primary
            shapeColour: Colours.palette.m3primaryContainer
            fillColour: Qt.alpha(Colours.palette.m3secondary, 0.3)
            shape: MaterialShape.Pentagon

            MaterialShape {
                x: cpu.mShape.pointAtAngle(45).x - implicitSize / 2 + Tokens.padding.medium
                y: cpu.mShape.pointAtAngle(45).y - implicitSize / 2

                shape: Cpu.temperature > 90 ? MaterialShape.SoftBurst : MaterialShape.Circle
                color: Cpu.temperature > 90 ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer
                implicitSize: {
                    const size = Math.round(tempLabel.implicitHeight * 2);
                    return size % 2 === 0 ? size : size + 1; // Ensure even size so center works properly
                }

                Behavior on color {
                    CAnim {}
                }

                StyledText {
                    id: tempLabel

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Math.round(fontInfo.pointSize * 0.04)

                    text: {
                        const temp = Cpu.temperature;
                        const useF = GlobalConfig.services.useFahrenheitPerformance;
                        return `${Math.ceil(useF ? temp * 1.8 + 32 : temp)}°${useF ? "F" : "C"}`;
                    }
                    color: Cpu.temperature > 90 ? Colours.palette.m3onErrorContainer : Colours.palette.m3secondary
                    font: Tokens.font.title.builders.medium.scale(cpu.width / 112).width(50).build()
                }
            }
        }

        Resource {
            icon: "memory_alt"
            value: Math.round(Memory.percentage * 100) + "%"
            fillValue: Memory.percentage
            colour: Colours.palette.m3tertiary
            shapeColour: Colours.palette.m3onTertiary
            fillColour: Qt.alpha(Colours.palette.m3tertiary, 0.3)
            shape: MaterialShape.Slanted
        }

        Resource {
            icon: "hard_disk"
            value: Math.round(Storage.percentage * 100) + "%"
            fillValue: Storage.percentage
            colour: Colours.palette.m3secondary
            shapeColour: Colours.palette.m3secondaryContainer
            fillColour: Qt.alpha(Colours.palette.m3secondary, 0.4)
            shape: MaterialShape.Gem
        }
    }

    component Resource: Item {
        id: res

        required property string icon
        required property string value
        required property color colour
        required property color shapeColour
        property color fillColour
        property real fillValue: -1
        property alias shape: shape.shape
        readonly property alias mShape: shape

        Layout.fillWidth: true
        implicitHeight: width

        Behavior on shapeColour {
            CAnim {}
        }

        MaterialShape {
            id: shape

            implicitSize: res.width
            color: Qt.alpha(res.shapeColour, 1)
            opacity: res.shapeColour.a
            layer.enabled: true
        }

        Loader {
            id: fillLoader

            anchors.fill: shape
            active: res.fillValue >= 0
            asynchronous: true

            layer.enabled: active
            layer.effect: Mask {
                maskSource: shape
            }

            sourceComponent: Item {
                WavyTopRect {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    implicitHeight: shape.implicitSize * res.fillValue
                    color: res.fillColour
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -Tokens.spacing.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: res.icon
                color: Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.builders.medium.scale(root.fontScale).build()
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: res.value
                color: res.colour
                font: Tokens.font.headline.builders.large.scale(root.fontScale).width(50).build()
            }
        }

        Behavior on fillValue {
            Anim {}
        }
    }
}
