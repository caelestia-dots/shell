import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Caelestia.Config
import Caelestia.Internal
import qs.components.containers
import qs.services

StyledWindow {
    id: root

    required property ShellScreen modelData

    readonly property alias shimejiScreen: root.modelData

    readonly property bool shouldBeVisible: !GlobalConfig.forScreen(modelData.name).shimeji.autoHide || (Hypr.monitorFor(modelData)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true)

    screen: modelData
    visible: shouldBeVisible

    function getImgPath(): string {
        if (!modelData) return "";
        let path = String(contentItem.Config.shimeji.path);
        if (!path) return "";

        if (path.endsWith(".zip")) {
            const extractDir = path.replace(".zip", "/");
            if (!extractor.running && !extractedPaths.includes(path)) {
                extractedPaths.push(path);
                extractor.arguments = ["-o", "-d", extractDir, path];
                extractor.running = true;
            }
            return extractDir;
        }

        return path.replace(/\/?$/, "/");
    }

    property var extractedPaths: []
    property Process extractor: Process {
        running: false
        command: ["unzip", "-o"]
        workingDirectory: "/tmp"
    }

    readonly property real floorY: shimejiScreen.height - 128 - (modelData ? contentItem.Config.border.thickness : 0)
    readonly property real minX: 0
    readonly property real maxX: shimejiScreen.width - 128
    readonly property real maxY: shimejiScreen.height - 128

    property real vx: 0
    property real vy: 0
    readonly property real gravity: 2
    readonly property real friction: 0.85
    readonly property real bounce: 0.35

    property bool onGround: false
    property bool dragging: false
    property point dragOffset
    property int walkTarget: -1

    property string currentAnim: "idle"
    property int frameIndex: 0
    property bool facingRight: true

    name: "shimeji"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    surfaceFormat.opaque: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Component.onCompleted: {
        pickIdle();
        Qt.callLater(() => {
            grabArea.width = 128;
            grabArea.height = 128;
        });
    }

    Item {
        id: spriteContainer

        x: (shimejiScreen.width - 128) / 2
        y: floorY
        width: 128
        height: 128

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
                    spriteContainer.x = Math.max(minX, Math.min(maxX, spriteContainer.x + mouse.x - dragOffset.x));
                    spriteContainer.y = Math.max(0, Math.min(maxY, spriteContainer.y + mouse.y - dragOffset.y));
                }
            }

            onReleased: mouse => {
                dragging = false;
                vy = 5;
                onGround = false;
            }

            Image {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                source: {
                    const fn = animFrame(currentAnim, frameIndex);
                    return fn ? "file://" + getImgPath() + fn : "";
                }
                sourceSize.width: 128
                sourceSize.height: 128
                fillMode: Image.PreserveAspectFit
                mirror: facingRight
            }
        }
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
        walkTarget = margin + Math.random() * (shimejiScreen.width - 128 - margin * 2);
        currentAnim = "walk";
        facingRight = walkTarget > spriteContainer.x;
        frameIndex = 0;
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

    onDraggingChanged: {
        if (!dragging) {
            pickIdle();
        }
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
            const dx = walkTarget - spriteContainer.x;
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

        spriteContainer.x += vx;
        spriteContainer.y += vy;

        if (spriteContainer.x < minX) {
            spriteContainer.x = minX;
            vx = -vx * bounce;
        } else if (spriteContainer.x > maxX) {
            spriteContainer.x = maxX;
            vx = -vx * bounce;
        }

        if (spriteContainer.y >= floorY) {
            spriteContainer.y = floorY;
            if (vy > 3) {
                currentAnim = "stand";
            } else if (vy > 0 && !onGround) {
                pickIdle();
            }
            vy = -vy * bounce;
            if (Math.abs(vy) < 1) {
                vy = 0;
                onGround = true;
            }
        } else if (spriteContainer.y < 0) {
            spriteContainer.y = 0;
            vy = -vy * bounce;
        } else {
            onGround = false;
        }

        if (spriteContainer.y > maxY) {
            spriteContainer.y = maxY;
            vy = -vy * bounce;
        }

        if (!onGround && currentAnim !== "walk" && vx !== 0 && walkTarget < 0) {
            currentAnim = "fall";
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

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            if (!dragging && onGround && Math.abs(vx) < 0.5 && walkTarget < 0) {
                facingRight = Math.random() > 0.5;
            }
        }
    }
}