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
    property real lastX: 0
    property real lastY: 0
    property real dragVx: 0
    property real dragVy: 0
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
        vx = 0;
        vy = 0;
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
            idle: ["shime1.png"],
            lookUp: ["shime26.png"],
            dangle: ["shime31.png", "shime32.png", "shime31.png", "shime33.png"],
            layDown: ["shime21.png"],
            sleep: ["shime20.png", "shime21.png"],
            walk: ["shime1.png", "shime2.png", "shime1.png", "shime3.png"],
            stand: ["shime1.png"],
            eat: ["shime26.png", "shime15.png", "shime27.png", "shime16.png", "shime28.png", "shime17.png", "shime29.png", "shime11.png"],
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
            vx *= 0.3;
            if (Math.abs(vx) < 0.5) vx = 0;
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
            vx = Math.abs(vx) * 0.9;
        } else if (root.x > maxX) {
            root.x = maxX;
            vx = -Math.abs(vx) * 0.9;
        }

        if (root.y > floorY) {
            root.y = floorY;
            vy = -vy * 0.6;
            if (vy >= 0 && Math.abs(vy) < 2) {
                vy = 0;
                onGround = true;
                vx = 0;
                currentAnim = "idle";
                if (walkTarget < 0 && Math.random() < 0.1) {
                    walkRandom();
                }
            } else if (vy < 0) {
                onGround = false;
            }
        } else if (root.y < 0) {
            root.y = 0;
            vy = Math.abs(vy) * 0.6;
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
            walkTarget = -1;
            dragOffset = Qt.point(mouse.x, mouse.y);
            lastX = root.x;
            lastY = root.y;
            dragVx = 0;
            dragVy = 0;
            vx = 0;
            vy = 0;
        }

        onPositionChanged: mouse => {
            if (dragging) {
                const newX = Math.max(minX, Math.min(maxX, root.x + mouse.x - dragOffset.x));
                const newY = Math.max(0, Math.min(maxY, root.y + mouse.y - dragOffset.y));
                dragVx = newX - lastX;
                dragVy = newY - lastY;
                lastX = newX;
                lastY = newY;
                root.x = newX;
                root.y = newY;
            }
        }

        onReleased: dragging = false;
    }

    Image {
        id: spriteImage
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
            if (!dragging && onGround && walkTarget < 0 && currentAnim !== "ground") {
                if (Math.abs(vx) < 0.5) {
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
    }

    onDraggingChanged: {
        if (!dragging) {
            vx = dragVx * 2;
            vy = dragVy > 0 ? dragVy * 2 : dragVy * 2;
            if (Math.abs(vx) < 1) vx = 0;
            if (Math.abs(vy) < 1) vy = 0;
            onGround = false;
            pickIdle();
        }
    }
}