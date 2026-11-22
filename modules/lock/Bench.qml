pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services

// The Knight resting on a bench (the user's drawing, split by scripts/hallownest-bench.py).
// Coordinates are those of the 320x220 SVG canvas; `canvasScale` sizes it.
Item {
    id: root

    property real canvasScale: 1
    property real breath
    property real lookX
    property real lookY
    property real raise // head lifted towards the password, 0..1
    property real blink
    property real shake
    property bool typing
    property bool following

    // Look up at the password field for a moment
    function look(): void {
        typing = true;
        lookX = 0;
        lookY = -5;
        raise = 1;
        lookReset.restart();
    }

    // Eyes follow a point given in this item's coordinates
    function follow(x: real, y: real): void {
        if (typing)
            return;
        const dx = x / canvasScale - 160;
        const dy = y / canvasScale - 99;
        const d = Math.max(Math.hypot(dx, dy), 1);
        const reach = Math.min(d / 40, 1);
        lookX = dx / d * 7 * reach;
        lookY = dy / d * 5.5 * reach;
        following = true;
        followReset.restart();
    }

    function refuse(): void {
        refuseAnim.restart();
    }


    implicitWidth: 320 * canvasScale
    implicitHeight: 220 * canvasScale

    SequentialAnimation on breath {
        loops: Animation.Infinite

        NumberAnimation {
            to: 1
            duration: 2200
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 0
            duration: 2600
            easing.type: Easing.InOutSine
        }
    }

    Behavior on lookX {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuad
        }
    }

    Behavior on lookY {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuad
        }
    }

    Behavior on raise {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: lookReset

        interval: 2500
        onTriggered: {
            root.typing = false;
            root.raise = 0;
            root.lookY = 0;
        }
    }

    Timer {
        id: followReset

        interval: 2000
        onTriggered: {
            root.following = false;
            if (!root.typing) {
                root.lookX = 0;
                root.lookY = 0;
            }
        }
    }

    // Idle glances to the sides
    Timer {
        running: root.visible && !root.typing && !root.following
        interval: 3500
        repeat: true
        onTriggered: {
            interval = 2500 + Math.random() * 4000;
            root.lookX = Math.random() < 0.5 ? 0 : (Math.random() < 0.5 ? -2 : 2);
        }
    }

    Timer {
        running: root.visible
        interval: 4000
        repeat: true
        onTriggered: {
            interval = 2500 + Math.random() * 4000;
            blinkAnim.restart();
        }
    }

    SequentialAnimation {
        id: blinkAnim

        NumberAnimation {
            target: root
            property: "blink"
            to: 1
            duration: 70
        }
        NumberAnimation {
            target: root
            property: "blink"
            to: 0
            duration: 110
        }
    }

    // "No": shake the head slowly
    SequentialAnimation {
        id: refuseAnim

        NumberAnimation {
            target: root
            property: "shake"
            to: -1
            duration: 260
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 1
            duration: 480
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: -0.7
            duration: 440
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 0
            duration: 340
            easing.type: Easing.InOutSine
        }
    }


    Item {
        width: 320
        height: 220
        scale: root.canvasScale
        transformOrigin: Item.TopLeft

        BenchLayer {
            name: "banco"
        }

        Item {
            anchors.fill: parent

            BenchLayer {
                name: "cuerpo"
                transform: Scale {
                    origin.x: 160
                    origin.y: 150
                    yScale: 1 + root.breath * 0.025
                }
            }

            // Head and eyes ride on top of the breathing body and turn around the neck
            Item {
                anchors.fill: parent
                transform: [
                    Rotation {
                        origin.x: 160
                        origin.y: 112
                        angle: root.shake * 6
                    },
                    Translate {
                        y: -root.breath * 0.9 - root.raise * 4
                    }
                ]

                BenchLayer {
                    name: "cabeza"
                }

                BenchLayer {
                    name: "ojos"
                    layer.enabled: root.raise > 0.05
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Hallownest.soul
                        shadowOpacity: root.raise * 0.65
                        shadowBlur: 0.8
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                        blurMax: 14
                    }
                    transform: [
                        Scale {
                            origin.y: 99
                            yScale: 1 - root.blink * 0.9
                        },
                        Translate {
                            x: root.lookX
                            y: root.lookY
                        }
                    ]
                }
            }
        }
    }

    component BenchLayer: Image {
        required property string name

        width: 320
        height: 220
        source: Quickshell.shellPath(`assets/hallownest/bench/${name}.png`)
        sourceSize: Qt.size(1280, 880)
        smooth: true
        mipmap: true
    }
}
