pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils
import "DinoSprites.js" as Sprites

// Playable Chrome dino. World units follow the original 600x150 canvas, speeds are per 60 fps frame
Item {
    id: root

    readonly property real worldWidth: 600
    readonly property real worldHeight: 150
    readonly property real groundY: 140
    readonly property real cell: 2
    readonly property real dinoX: 24
    readonly property real gravity: 0.6
    readonly property real jumpVelocity: 10
    readonly property real dropVelocity: 5
    readonly property real minJumpHeight: 30
    readonly property real startSpeed: 6
    readonly property real maxSpeed: 13
    readonly property real acceleration: 0.001
    readonly property var birdHeights: [106, 83, 58]
    // Text is drawn outside the scaled world so its pixels land on whole screen pixels
    readonly property int textPixel: Math.max(2, Math.round(cell * width / worldWidth))

    property string phase: "waiting" // waiting, running, over
    property real speed: startSpeed
    property real distance
    property int score
    property int highScore
    property real dinoY // Height above the ground
    property real velocity
    property bool jumping
    property bool holdingJump
    property bool ducking
    property bool duckHeld
    property bool speedDrop
    property real animTime
    property real nextGap
    property real overAt

    function press(action: string): void {
        if (action === "jump") {
            if (phase === "waiting" || (phase === "over" && Date.now() - overAt > 500))
                start();
            if (phase !== "running")
                return;
            holdingJump = true;
            if (!jumping && !ducking) {
                jumping = true;
                velocity = jumpVelocity;
            }
        } else if (action === "duck") {
            duckHeld = true;
            if (phase !== "running")
                return;
            if (jumping) {
                speedDrop = true;
                holdingJump = false;
            } else {
                ducking = true;
            }
        }
    }

    function release(action: string): void {
        if (action === "jump") {
            holdingJump = false;
        } else if (action === "duck") {
            duckHeld = false;
            ducking = false;
            speedDrop = false;
        }
    }

    function keyPressed(key: int): void {
        if (key === Qt.Key_Up)
            press("jump");
        else if (key === Qt.Key_Down)
            press("duck");
    }

    function keyReleased(key: int): void {
        if (key === Qt.Key_Up)
            release("jump");
        else if (key === Qt.Key_Down)
            release("duck");
    }

    function start(): void {
        speed = startSpeed;
        distance = 0;
        score = 0;
        dinoY = 0;
        velocity = 0;
        jumping = false;
        ducking = duckHeld;
        speedDrop = false;
        animTime = 0;
        nextGap = 0;
        for (let i = 0; i < obstacles.count; i++)
            (obstacles.itemAt(i) as Obstacle).active = false;
        phase = "running";
    }

    function gameOver(): void {
        phase = "over";
        overAt = Date.now();
        if (score > highScore) {
            highScore = score;
            highScoreFile.setText(String(score));
        }
    }

    function step(dt: real): void {
        animTime += dt;
        speed = Math.min(maxSpeed, speed + acceleration * dt);
        distance += speed * dt;

        const newScore = Math.floor(distance * 0.025);
        if (Math.floor(newScore / 100) > Math.floor(score / 100))
            scoreBlink.restart();
        score = newScore;

        if (jumping) {
            if (!holdingJump && dinoY > minJumpHeight && velocity > dropVelocity)
                velocity = dropVelocity;
            dinoY += velocity * dt;
            velocity -= (speedDrop ? gravity * 3 : gravity) * dt;
            if (dinoY <= 0) {
                dinoY = 0;
                velocity = 0;
                jumping = false;
                speedDrop = false;
                ducking = duckHeld;
            }
        }

        let last = null;
        for (let i = 0; i < obstacles.count; i++) {
            const o = obstacles.itemAt(i) as Obstacle;
            if (!o.active)
                continue;
            o.x -= (speed + o.speedOffset) * dt;
            if (o.x + o.width < 0)
                o.active = false;
            else if (!last || o.x > last.x)
                last = o;
        }

        if (distance > 400 && (!last || last.x + last.width + nextGap < worldWidth))
            spawn();

        for (let i = 0; i < clouds.count; i++) {
            const c = clouds.itemAt(i);
            c.x -= speed * 0.2 * dt;
            if (c.x + c.width < 0) {
                c.x = worldWidth + Math.random() * 200;
                c.y = 10 + Math.random() * 60;
            }
        }

        for (let i = 0; i < specks.count; i++) {
            const s = specks.itemAt(i);
            s.x -= speed * dt;
            if (s.x + s.width < 0) {
                s.x += worldWidth + 20;
                s.y = groundY + 3 + Math.floor(Math.random() * 3) * 2;
            }
        }

        if (collides())
            gameOver();
    }

    function spawn(): void {
        let o = null;
        for (let i = 0; i < obstacles.count && !o; i++)
            if (!(obstacles.itemAt(i) as Obstacle).active)
                o = obstacles.itemAt(i) as Obstacle;
        if (!o)
            return;

        const kinds = speed > 8.5 ? ["cactusS", "cactusL", "bird"] : ["cactusS", "cactusL"];
        o.kind = kinds[Math.floor(Math.random() * kinds.length)];
        if (o.kind === "bird") {
            o.count = 1;
            o.speedOffset = Math.random() > 0.5 ? 0.8 : -0.8;
            o.y = birdHeights[Math.floor(Math.random() * birdHeights.length)];
        } else {
            const maxCount = o.kind === "cactusS" || speed > 7 ? 3 : 1;
            o.count = 1 + Math.floor(Math.random() * maxCount);
            o.speedOffset = 0;
            o.y = groundY + cell - o.height;
        }
        o.x = worldWidth;
        o.active = true;

        const minGap = Math.round(o.width * speed + (o.kind === "bird" ? 150 : 120) * 0.6);
        nextGap = minGap + Math.random() * minGap * 0.5;
    }

    function collides(): bool {
        const top = dino.y;
        const boxes = ducking ? [[dinoX + 2, top + 4, 60, 18]] : [[dinoX + 20, top, 20, 16], [dinoX + 2, top + 16, 30, 24]];

        for (let i = 0; i < obstacles.count; i++) {
            const o = obstacles.itemAt(i) as Obstacle;
            if (!o.active || o.x > dinoX + 70)
                continue;
            const box = o.kind === "bird" ? [o.x + 2, o.y + 8, 40, 16] : [o.x + 3, o.y + 2, o.width - 6, o.height - 2];
            for (const b of boxes)
                if (b[0] < box[0] + box[2] && b[0] + b[2] > box[0] && b[1] < box[1] + box[3] && b[1] + b[3] > box[1])
                    return true;
        }
        return false;
    }

    implicitHeight: width * worldHeight / worldWidth
    clip: true

    FileView {
        id: highScoreFile

        path: `${Paths.state}/dino-hi`
        printErrors: false
        onLoaded: root.highScore = parseInt(text()) || 0
    }

    FrameAnimation {
        running: root.phase === "running" && root.visible
        onTriggered: root.step(Math.min(frameTime * 60, 3))
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.press(event.button === Qt.RightButton ? "duck" : "jump")
        onReleased: event => root.release(event.button === Qt.RightButton ? "duck" : "jump")
    }

    Item {
        id: world

        width: root.worldWidth
        height: root.worldHeight
        scale: root.width / root.worldWidth
        transformOrigin: Item.TopLeft

        Repeater {
            id: clouds

            model: 3

            PixelArt {
                required property int index

                x: 120 + index * 190
                y: 15 + index * 22 % 50
                rows: Sprites.cloud
                pixelSize: root.cell
                color: Hallownest.faint
            }
        }

        Rectangle {
            y: root.groundY
            width: parent.width
            height: 1.5
            color: Hallownest.border
        }

        Repeater {
            id: specks

            model: 14

            Rectangle {
                required property int index

                x: index * 45 + index * 17 % 20
                y: root.groundY + 3 + index % 3 * 2
                width: index % 4 === 0 ? 4 : 2
                height: 1.5
                color: Hallownest.faint
            }
        }

        Repeater {
            id: obstacles

            model: 3

            Obstacle {}
        }

        PixelArt {
            id: dino

            x: root.dinoX
            y: root.groundY + root.cell - height - root.dinoY
            pixelSize: root.cell
            color: Hallownest.steel
            rows: {
                if (root.phase === "over")
                    return Sprites.dead;
                if (root.phase !== "running" || root.jumping)
                    return Sprites.stand;
                const frame = Math.floor(root.animTime / 6) % 2;
                if (root.ducking)
                    return frame ? Sprites.duck2 : Sprites.duck1;
                return frame ? Sprites.run2 : Sprites.run1;
            }
        }
    }

    PixelArt {
        id: scoreText

        x: Math.round(root.width - width - 10 * world.scale)
        y: Math.round(8 * world.scale)
        pixelSize: root.textPixel
        color: Hallownest.steel
        rows: Sprites.text((root.highScore > 0 ? `HI ${String(root.highScore).padStart(5, "0")}  ` : "") + String(root.score).padStart(5, "0"))

        SequentialAnimation {
            id: scoreBlink

            loops: 3

            PropertyAction {
                target: scoreText
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: 150
            }
            PropertyAction {
                target: scoreText
                property: "opacity"
                value: 1
            }
            PauseAnimation {
                duration: 150
            }
        }
    }

    Column {
        x: Math.round((root.width - width) / 2)
        y: Math.round(40 * world.scale)
        visible: root.phase !== "running"
        spacing: root.textPixel * 3

        PixelArt {
            x: Math.round((parent.width - width) / 2)
            pixelSize: root.textPixel
            color: Hallownest.steel
            rows: Sprites.text(root.phase === "over" ? "G A M E   O V E R" : "CLICK OR \u2191 TO PLAY")
        }

        PixelArt {
            x: Math.round((parent.width - width) / 2)
            visible: root.phase === "over"
            pixelSize: root.textPixel
            color: Hallownest.steel
            rows: Sprites.restart
        }
    }

    component Obstacle: PixelArt {
        property bool active
        property string kind: "cactusS"
        property int count: 1
        property real speedOffset

        visible: active
        pixelSize: root.cell
        color: Hallownest.steel
        rows: {
            if (kind === "bird")
                return Math.floor(root.animTime / 10) % 2 ? Sprites.bird2 : Sprites.bird1;
            const sprite = kind === "cactusL" ? Sprites.cactusL : Sprites.cactusS;
            return sprite.map(row => row.repeat(count));
        }
    }
}
