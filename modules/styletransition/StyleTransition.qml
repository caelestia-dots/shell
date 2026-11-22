pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.components.containers
import qs.components.hallownest
import qs.services

// Veils every screen while Hallownest switches style, like the title card of a new area
Scope {
    id: root

    property bool running
    property real veil
    property real drawn
    property real card

    // Per-style biome emblem (20x20 coordinate space, centred at 10,10)
    function emblemPath(styleName: string): string {
        switch (styleName) {
        case "cityoftears":
            // Falling raindrop
            return "M 10 2 C 10 2 15.5 9.2 15.5 13 A 5.5 5.5 0 1 1 4.5 13 C 4.5 9.2 10 2 10 2 Z";
        case "grimm":
            // Scarlet flame
            return "M 10 1.5 C 12.8 5.5 16 8.5 15.2 13.2 C 14.6 16.5 12.2 18.2 10 18.5 C 7.8 18.2 5.4 16.5 4.8 13.2 C 4 8.5 7.2 5.5 10 1.5 Z M 10 8.5 C 8.5 10.8 8 12.5 8.6 14.3 C 9 15.3 9.5 15.8 10 16 C 10.5 15.8 11 15.3 11.4 14.3 C 12 12.5 11.5 10.8 10 8.5 Z";
        case "beezone":
            // Honeycomb hexagon
            return "M 10 2 L 17 6 L 17 14 L 10 18 L 3 14 L 3 6 Z";
        case "queensgardens":
            // Four-petal delicate flower
            return "M 10 2 Q 13 6.5 10 10 Q 7 6.5 10 2 Z M 18 10 Q 13.5 13 10 10 Q 13.5 7 18 10 Z M 10 18 Q 7 13.5 10 10 Q 13 13.5 10 18 Z M 2 10 Q 6.5 7 10 10 Q 6.5 13 2 10 Z";
        case "pale":
            // Pale King's three-spired crown
            return "M 4 15 L 3 6 L 7.5 10.5 L 10 3 L 12.5 10.5 L 17 6 L 16 15 Z";
        case "kingdomsedge":
            // Sharp nail/ash diamond
            return "M 10 1.5 L 13 10 L 10 18.5 L 7 10 Z M 4.5 10 L 10 8.2 L 15.5 10 L 10 11.8 Z";
        case "void":
            // Hollow twin-void diamond
            return "M 10 2 L 18 10 L 10 18 L 2 10 Z M 10 5.5 L 5.5 10 L 10 14.5 L 14.5 10 Z";
        default:
            // Hallownest horned vessel silhouette
            return "M 5 3 L 7 8 Q 10 7 13 8 L 15 3 L 15.5 11.5 Q 15 16.5 10 17.5 Q 5 16.5 4.5 11.5 Z";
        }
    }

    Connections {
        function onTransitioningChanged(): void {
            if (Hallownest.transitioning && !timeline.running) {
                root.running = true;
                timeline.start();
            }
        }

        target: Hallownest
    }

    SequentialAnimation {
        id: timeline

        // Covers the screen in the old colours before Hallownest applies the new ones (300 ms)
        NumberAnimation {
            target: root
            property: "veil"
            from: 0
            to: 0.96
            duration: 280
            easing.type: Easing.OutCubic
        }
        PauseAnimation {
            duration: 60
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "drawn"
                from: 0
                to: 1
                duration: 800
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: root
                property: "card"
                from: 0
                to: 1
                duration: 450
                easing.type: Easing.OutCubic
            }
        }
        PauseAnimation {
            duration: 450
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "drawn"
                to: 0
                duration: 480
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "veil"
                to: 0
                duration: 550
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: root
                property: "card"
                to: 0
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }
        ScriptAction {
            script: {
                root.running = false;
                root.drawn = 0;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: loader

            required property ShellScreen modelData

            active: root.running

            StyledWindow {
                screen: loader.modelData
                name: "style-transition"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                mask: Region {}

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Rectangle {
                    anchors.fill: parent
                    color: Hallownest.void_
                    opacity: root.veil

                    Behavior on color {
                        CAnim {}
                    }

                    HkGrain {
                        anchors.fill: parent
                    }

                    // Biome-specific ambient particles: rain in City of Tears, falling ash in
                    // Kingdom's Edge, embers in Grimm, drifting spores in Queen's Gardens, honey
                    // motes in Beezone, Soul motes elsewhere
                    Item {
                        id: biomeParticles

                        readonly property string mode: Hallownest.style
                        readonly property bool falling: mode === "cityoftears" || mode === "kingdomsedge"
                        readonly property bool rain: mode === "cityoftears"
                        readonly property color tint: mode === "grimm" ? Hallownest.grimm : mode === "beezone" ? Hallownest.gold : mode === "queensgardens" ? Hallownest.unn : mode === "cityoftears" ? Hallownest.lifeblood : Hallownest.soul
                        readonly property int baseDur: rain ? 1200 : mode === "grimm" ? 2200 : mode === "kingdomsedge" ? 5600 : 4200

                        anchors.fill: parent
                        opacity: root.card * (rain ? 0.55 : 0.72)

                        Repeater {
                            model: root.running ? (biomeParticles.rain ? 34 : 26) : 0

                            Rectangle {
                                id: mote

                                required property int index
                                readonly property real xSeed: Math.random()
                                readonly property real phaseSeed: Math.random()
                                readonly property real sizeSeed: Math.random()
                                property real t
                                readonly property real p: (t + phaseSeed) % 1
                                readonly property real drift: biomeParticles.rain ? -p * 70 : Math.sin(p * 6.28 + phaseSeed * 10) * (biomeParticles.mode === "kingdomsedge" ? 26 : biomeParticles.mode === "queensgardens" ? 18 : 6)

                                x: xSeed * (biomeParticles.width - width) + drift
                                y: biomeParticles.falling ? (p * biomeParticles.height) : (biomeParticles.height - height - p * biomeParticles.height)
                                width: biomeParticles.rain ? 1.5 : (2.2 + sizeSeed * 2.6)
                                height: biomeParticles.rain ? (14 + sizeSeed * 14) : width
                                radius: biomeParticles.rain ? 1 : width / 2
                                rotation: biomeParticles.rain ? 10 : (biomeParticles.mode === "kingdomsedge" ? p * 90 : 0)
                                color: biomeParticles.tint
                                opacity: Math.sin(p * Math.PI) * (biomeParticles.rain ? 0.65 : 0.85)

                                NumberAnimation on t {
                                    running: root.running
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 1
                                    duration: biomeParticles.baseDur * (0.7 + mote.sizeSeed * 0.7)
                                }
                            }
                        }
                    }

                    // Bottom corners, then the same frame turned over for the top ones
                    Repeater {
                        model: 2

                        Filigree {
                            required property int index

                            anchors.fill: parent
                            anchors.margins: 36
                            rotation: index * 180
                            radius: 56
                            inset: 10
                            colour: Hallownest.steel
                            drawn: root.drawn
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        opacity: root.card
                        scale: 0.96 + root.card * 0.04

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (Hallownest.styleData.name ?? "").toUpperCase()
                            color: Hallownest.text
                            font.family: Hallownest.serif
                            font.pointSize: 28
                            font.letterSpacing: 6
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 12

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 120 * root.drawn
                                height: 1
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal

                                    GradientStop {
                                        position: 0
                                        color: "transparent"
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Qt.alpha(Hallownest.steel, 0.65)
                                    }
                                }
                            }

                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 22
                                layer.enabled: root.running
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: Hallownest.soul
                                    shadowBlur: 0.75
                                    shadowHorizontalOffset: 0
                                    shadowVerticalOffset: 0
                                    blurMax: 12
                                }

                                Shape {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    preferredRendererType: Shape.CurveRenderer

                                    ShapePath {
                                        fillColor: Hallownest.soul
                                        strokeWidth: -1

                                        PathSvg {
                                            path: root.emblemPath(Hallownest.style)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 120 * root.drawn
                                height: 1
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal

                                    GradientStop {
                                        position: 0
                                        color: Qt.alpha(Hallownest.steel, 0.65)
                                    }
                                    GradientStop {
                                        position: 1
                                        color: "transparent"
                                    }
                                }
                            }
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Hallownest.flavour.toUpperCase()
                            color: Hallownest.steel
                            font.family: Hallownest.serif
                            font.pointSize: 11
                            font.letterSpacing: 4
                        }
                    }
                }
            }
        }
    }
}
