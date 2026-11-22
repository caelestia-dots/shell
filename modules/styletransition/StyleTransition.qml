pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
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

                    SoulParticles {
                        anchors.fill: parent
                        count: 24
                        size: 3
                        colour: Hallownest.soul
                        duration: 4200
                        running: root.running
                        opacity: root.card * 0.65
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
                            spacing: 10

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 120 * root.drawn
                                height: 1
                                color: Qt.alpha(Hallownest.steel, 0.6)
                            }

                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                layer.enabled: root.running
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: Hallownest.soul
                                    shadowBlur: 0.75
                                    shadowHorizontalOffset: 0
                                    shadowVerticalOffset: 0
                                    blurMax: 12
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 7
                                    height: 7
                                    rotation: 45
                                    color: Hallownest.soul
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 120 * root.drawn
                                height: 1
                                color: Qt.alpha(Hallownest.steel, 0.6)
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
