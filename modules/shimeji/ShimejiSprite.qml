import QtQuick
import Caelestia.Config
import qs.services

Item {
    id: root

    required property var screenSize
    required property var borderThickness
    required property string imgPath

    readonly property real floorY: screenSize.height - 128 - borderThickness
    readonly property real minX: 0
    readonly property real maxX: screenSize.width - 128
    readonly property real maxY: screenSize.height - 128

    property real vx: 0
    property real vy: 0
    readonly property real gravity: 2
    readonly property real friction: 0.85

    property bool onGround: false
    property bool dragging: false
    property point dragOffset
    property int walkTarget: -1

    property string currentAnim: "idle"
    property int frameIndex: 0
    property bool facingRight: true

    x: 0
    y: floorY
    width: 128
    height: 128

    Component.onCompleted: {
        const margin = 50;
        x = margin + Math.random() * (screenSize.width - 128 - margin * 2);
        y = floorY;
        onGround = true;
        pickIdle();
    }

    function pickIdle() {
        const roll = Math.random();
        if (roll < 0.35)
            currentAnim = "idle";
        else if (roll < 0.55)
            currentAnim = "lookUp";
        else if (roll < 0.75)
            currentAnim = "dangle";
        else
            currentAnim = "sleep";
        frameIndex = 0;
    }

    function walkRandom() {
        const margin = 100;
        walkTarget = margin + Math.random() * (screenSize.width - 128 - margin * 2);
        currentAnim = "walk";
        facingRight = walkTarget > root.x;
        frameIndex = 0;
    }

    function animFrame(anim, index) {
        const frames = {
            idle: ["shime11.png"],
            lookUp: ["shime26.png"],
            dangle: ["shime31.png", "shime32.png", "shime31.png", "shime33.png"],
            layDown: ["shime21.png"],
            sleep: ["shime20.png"],
            walk: ["shime1.png", "shime2.png", "shime1.png", "shime3.png"],
            stand: ["shime1.png"],
            fall: ["shime4.png"],
        };
        const list = frames[anim];
        return list ? list[index % list.length] : "";
    }

    function tick() {
        if (dragging) return;

        if (!onGround) {
            vy += gravity;
            vx *= 0.98;
        } else if (Math.abs(vx) > 0.1) {
            vx *= friction;
            if (Math.abs(vx) < 0.5)
                vx = 0;
        }

        if (walkTarget >= 0) {
            const dx = walkTarget - root.x;
            if (Math.abs(dx) < 5) {
                walkTarget = -1;
                vx = 0;
                pickIdle();
            } else {
                vx = Math.sign(dx) * 2.5;
                facingRight = vx > 0;
                currentAnim = "walk";
            }
        }

        root.x += vx;
        root.y += vy;

        if (root.x < minX) {
            root.x = minX;
            vx = Math.abs(vx) * 0.5;
            onGround = true;
        } else if (root.x > maxX) {
            root.x = maxX;
            vx = -Math.abs(vx) * 0.5;
            onGround = true;
        }

        if (root.y > floorY) {
            root.y = floorY;
            vy = -vy * 0.35;
            if (Math.abs(vy) < 1) {
                vy = 0;
                onGround = true;
                if (walkTarget < 0 && Math.random() < 0.02) {
                    walkRandom();
                }
            }
        } else if (root.y < 0) {
            root.y = 0;
            vy = Math.abs(vy) * 0.5;
        }
    }

    MouseArea {
        id: grabArea
        x: 0
        y: 0
        width: 128
        height: 128
        hoverEnabled: false
        propagateComposedEvents: true
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        acceptedButtons: Qt.LeftButton

        onPressed: mouse => {
            dragging = true;
            currentAnim = "idle";
            dragOffset = Qt.point(mouse.x, mouse.y);
            vx = 0;
            vy = 0;
        }

        onPositionChanged: mouse => {
            if (dragging) {
                root.x = Math.max(minX, Math.min(maxX, root.x + mouse.x - dragOffset.x));
                root.y = Math.max(0, Math.min(maxY, root.y + mouse.y - dragOffset.y));
            }
        }

        onReleased: dragging = false;
    }

    Image {
        anchors.fill: parent
        source: {
            const fn = root.animFrame(currentAnim, frameIndex);
            return fn ? "file://" + imgPath + fn : "";
        }
        sourceSize.width: 128
        sourceSize.height: 128
        fillMode: Image.PreserveAspectFit
        mirror: facingRight
    }

    Timer {
        id: physicsTimer
        interval: 30
        repeat: true
        running: true
        onTriggered: tick()
    }

    Timer {
        id: animTimer
        interval: 200
        repeat: true
        running: true
        onTriggered: {
            if (!dragging)
                frameIndex++;
        }
    }

    Timer {
        interval: 3000 + Math.random() * 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!dragging && onGround && Math.abs(vx) < 0.5 && walkTarget < 0) {
                const roll = Math.random();
                if (roll < 0.3) {
                    pickIdle();
                } else if (roll < 0.55) {
                    walkRandom();
                } else if (roll < 0.75) {
                    currentAnim = "dangle";
                    frameIndex = 0;
                } else {
                    currentAnim = "layDown";
                    frameIndex = 0;
                }
            }
        }
    }

    onDraggingChanged: {
        if (!dragging) {
            vy = 5;
            onGround = false;
            pickIdle();
        }
    }
}