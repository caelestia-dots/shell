pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// Pac-Man with the arcade maze and ghost targeting. Positions are in tiles, speeds in tiles per second
Item {
    id: root

    // "#"/"=" wall, "." dot, "o" power pellet, "-" ghost door, "_" ghost house, " " empty
    readonly property var maze: ["############################", "#............##............#", "#.####.#####.##.#####.####.#", "#o####.#####.##.#####.####o#", "#.####.#####.##.#####.####.#", "#..........................#", "#.####.##.########.##.####.#", "#.####.##.########.##.####.#", "#......##....##....##......#", "######.##### ## #####.######", "#####=.##### ## #####.=#####", "#####=.##          ##.=#####", "#####=.## ###--### ##.=#####", "######.## #______# ##.######", "      .   #______#   .      ", "######.## #______# ##.######", "#####=.## ######## ##.=#####", "#####=.##          ##.=#####", "#####=.## ######## ##.=#####", "######.## ######## ##.######", "#............##............#", "#.####.#####.##.#####.####.#", "#.####.#####.##.#####.####.#", "#o..##.......  .......##..o#", "###.##.##.########.##.##.###", "###.##.##.########.##.##.###", "#......##....##....##......#", "#.##########.##.##########.#", "#.##########.##.##########.#", "#..........................#", "############################"]
    readonly property int cols: 28
    readonly property int rows: 31
    readonly property real hudHeight: hud.implicitHeight + Tokens.spacing.small
    readonly property real cell: Math.max(4, Math.floor(Math.min(width / cols, (height - hudHeight) / rows)))
    readonly property var pellets: [[1, 3], [26, 3], [1, 23], [26, 23]]
    readonly property var modeSchedule: [7, 20, 7, 20, 5, 20, 5, 1e9]
    readonly property real baseSpeed: Math.min(10, 7.5 * (1 + 0.05 * (level - 1)))

    property string phase: "waiting" // waiting, ready, running, dying, cleared, over
    property real phaseTime
    property real gameTime
    property real modeTime
    property bool scatter: true
    property real frightenedUntil
    property int combo
    property var dots: []
    property int dotsLeft
    property int dotsVersion
    property var pelletsLeft: [true, true, true, true]
    property int score
    property int highScore
    property int lives: 3
    property int level: 1
    property real chomp
    property real overAt

    function tileAt(x: int, y: int): string {
        if (y < 0 || y >= rows)
            return "#";
        if (x < 0 || x >= cols)
            return y === 14 ? " " : "#";
        return maze[y][x];
    }

    function walkable(x: int, y: int): bool {
        return " .o".includes(tileAt(x, y));
    }

    function wrap(a: Item): void {
        if (a.tileX < 0)
            a.tileX = cols - 1;
        else if (a.tileX >= cols)
            a.tileX = 0;
    }

    function resetDots(): void {
        const d = [];
        let left = 0;
        for (let y = 0; y < rows; y++)
            for (let x = 0; x < cols; x++) {
                const dot = maze[y][x] === ".";
                d.push(dot);
                if (dot)
                    left++;
            }
        dots = d;
        dotsLeft = left + 4;
        pelletsLeft = [true, true, true, true];
        dotsVersion++;
    }

    function resetActors(): void {
        pac.place(13, 23, -1, 0);
        pac.wantX = -1;
        pac.wantY = 0;
        for (let i = 0; i < ghosts.count; i++)
            (ghosts.itemAt(i) as Ghost).reset();
        gameTime = 0;
        modeTime = 0;
        scatter = true;
        frightenedUntil = 0;
        chomp = 0;
    }

    function start(): void {
        score = 0;
        lives = 3;
        level = 1;
        resetDots();
        resetActors();
        setPhase("ready");
    }

    function setPhase(p: string): void {
        phase = p;
        phaseTime = 0;
    }

    function gameOver(): void {
        setPhase("over");
        overAt = Date.now();
        if (score > highScore) {
            highScore = score;
            highScoreFile.setText(String(score));
        }
    }

    function canStart(): bool {
        return phase === "waiting" || (phase === "over" && Date.now() - overAt > 500);
    }

    function steer(dx: int, dy: int): void {
        if (canStart())
            start();
        pac.wantX = dx;
        pac.wantY = dy;
    }

    function keyPressed(key: int, isRepeat: bool): void {
        if (key === Qt.Key_Left)
            steer(-1, 0);
        else if (key === Qt.Key_Right)
            steer(1, 0);
        else if (key === Qt.Key_Up)
            steer(0, -1);
        else if (key === Qt.Key_Down)
            steer(0, 1);
    }

    function keyReleased(key: int): void {
    }

    function step(dt: real): void {
        phaseTime += dt;

        if (phase === "ready") {
            if (phaseTime > 2)
                setPhase("running");
            return;
        }
        if (phase === "dying") {
            if (phaseTime > 1.6) {
                lives--;
                if (lives <= 0) {
                    gameOver();
                } else {
                    resetActors();
                    setPhase("ready");
                }
            }
            return;
        }
        if (phase === "cleared") {
            if (phaseTime > 2) {
                level++;
                resetDots();
                resetActors();
                setPhase("ready");
            }
            return;
        }
        if (phase !== "running")
            return;

        gameTime += dt;
        const frightened = gameTime < frightenedUntil;
        if (!frightened) {
            modeTime += dt;
            let t = modeTime;
            let i = 0;
            while (t >= modeSchedule[i]) {
                t -= modeSchedule[i];
                i++;
            }
            if ((i % 2 === 0) !== scatter) {
                scatter = i % 2 === 0;
                for (let g = 0; g < ghosts.count; g++)
                    (ghosts.itemAt(g) as Ghost).reverse();
            }
        }

        movePac(baseSpeed * (frightened ? 1.1 : 1) * dt);
        eat();

        for (let i = 0; i < ghosts.count; i++) {
            const g = ghosts.itemAt(i) as Ghost;
            if (!frightened)
                g.frightened = false;
            if (g.mode === "house") {
                if (gameTime >= g.releaseAt)
                    g.release();
                continue;
            }
            let speed = baseSpeed * 0.93;
            if (g.mode === "eyes")
                speed = baseSpeed * 2;
            else if (g.frightened)
                speed = baseSpeed * 0.5;
            else if (g.tileY === 14 && (g.tileX < 6 || g.tileX > 21))
                speed = baseSpeed * 0.5;
            moveGhost(g, speed * dt);
        }

        collide();
        if (dotsLeft === 0)
            setPhase("cleared");
    }

    function movePac(dist: real): void {
        const a = pac;
        const wantOpen = (a.wantX || a.wantY) && walkable(a.tileX + a.wantX, a.tileY + a.wantY);
        if (a.dirX === -a.wantX && a.dirY === -a.wantY && (a.dirX || a.dirY)) {
            a.tileX += a.dirX;
            a.tileY += a.dirY;
            wrap(a);
            a.dirX = a.wantX;
            a.dirY = a.wantY;
            a.prog = 1 - a.prog;
        } else if (!a.dirX && !a.dirY) {
            if (!wantOpen)
                return;
            a.dirX = a.wantX;
            a.dirY = a.wantY;
        }

        chomp += dist;
        a.prog += dist;
        while (a.prog >= 1) {
            a.prog -= 1;
            a.tileX += a.dirX;
            a.tileY += a.dirY;
            wrap(a);
            if ((a.wantX || a.wantY) && walkable(a.tileX + a.wantX, a.tileY + a.wantY)) {
                a.dirX = a.wantX;
                a.dirY = a.wantY;
            } else if (!walkable(a.tileX + a.dirX, a.tileY + a.dirY)) {
                a.dirX = 0;
                a.dirY = 0;
                a.prog = 0;
            }
        }
        if (a.dirX || a.dirY)
            a.facing = a.dirY ? (a.dirY > 0 ? 90 : 270) : (a.dirX < 0 ? 180 : 0);
    }

    function moveGhost(g: Ghost, dist: real): void {
        g.prog += dist;
        while (g.prog >= 1) {
            g.prog -= 1;
            g.tileX += g.dirX;
            g.tileY += g.dirY;
            wrap(g);
            if (g.mode === "eyes" && g.tileX === 13 && g.tileY === 11) {
                g.mode = "active";
                g.prog = 0;
            }
            chooseDir(g);
        }
    }

    function chooseDir(g: Ghost): void {
        const options = [[0, -1], [-1, 0], [0, 1], [1, 0]].filter(([dx, dy]) => !(dx === -g.dirX && dy === -g.dirY) && walkable(g.tileX + dx, g.tileY + dy));
        if (options.length === 0) {
            g.dirX = -g.dirX;
            g.dirY = -g.dirY;
            return;
        }
        if (g.frightened) {
            const o = options[Math.floor(Math.random() * options.length)];
            g.dirX = o[0];
            g.dirY = o[1];
            return;
        }

        const [tx, ty] = ghostTarget(g);
        let best = options[0];
        let bestDist = Infinity;
        for (const o of options) {
            const d = (g.tileX + o[0] - tx) ** 2 + (g.tileY + o[1] - ty) ** 2;
            if (d < bestDist) {
                bestDist = d;
                best = o;
            }
        }
        g.dirX = best[0];
        g.dirY = best[1];
    }

    function ghostTarget(g: Ghost): var {
        if (g.mode === "eyes")
            return [13, 11];
        if (scatter)
            return g.corner;
        const px = pac.tileX;
        const py = pac.tileY;
        if (g.index === 0)
            return [px, py];
        if (g.index === 1)
            return [px + pac.dirX * 4, py + pac.dirY * 4];
        if (g.index === 2) {
            const b = ghosts.itemAt(0) as Ghost;
            return [(px + pac.dirX * 2) * 2 - b.tileX, (py + pac.dirY * 2) * 2 - b.tileY];
        }
        return (px - g.tileX) ** 2 + (py - g.tileY) ** 2 > 64 ? [px, py] : g.corner;
    }

    function eat(): void {
        const x = Math.round(pac.posX);
        const y = Math.round(pac.posY);
        if (x < 0 || x >= cols)
            return;
        const i = y * cols + x;
        if (dots[i]) {
            dots[i] = false;
            dotsLeft--;
            score += 10;
            dotsVersion++;
            return;
        }
        for (let p = 0; p < pellets.length; p++) {
            if (pelletsLeft[p] && pellets[p][0] === x && pellets[p][1] === y) {
                const left = pelletsLeft.slice();
                left[p] = false;
                pelletsLeft = left;
                dotsLeft--;
                score += 50;
                combo = 0;
                frightenedUntil = gameTime + Math.max(1, 7 - level);
                for (let g = 0; g < ghosts.count; g++) {
                    const ghost = ghosts.itemAt(g) as Ghost;
                    if (ghost.mode === "active") {
                        ghost.frightened = true;
                        ghost.reverse();
                    }
                }
            }
        }
    }

    function collide(): void {
        for (let i = 0; i < ghosts.count; i++) {
            const g = ghosts.itemAt(i) as Ghost;
            if (g.mode !== "active" || Math.abs(g.posX - pac.posX) + Math.abs(g.posY - pac.posY) > 0.7)
                continue;
            if (g.frightened) {
                g.frightened = false;
                g.mode = "eyes";
                score += 200 * 2 ** combo;
                combo = Math.min(combo + 1, 3);
            } else {
                setPhase("dying");
                return;
            }
        }
    }

    FileView {
        id: highScoreFile

        path: `${Paths.state}/pacman-hi`
        printErrors: false
        onLoaded: root.highScore = parseInt(text()) || 0
    }

    FrameAnimation {
        running: ["ready", "running", "dying", "cleared"].includes(root.phase) && root.visible
        onTriggered: root.step(Math.min(frameTime, 0.05))
    }

    Timer {
        id: blink

        property bool on: true

        interval: 250
        repeat: true
        running: root.visible && root.phase !== "waiting"
        onTriggered: on = !on
    }

    MouseArea {
        anchors.fill: parent
        onPressed: event => {
            const dx = event.x - board.x - (pac.posX + 0.5) * root.cell;
            const dy = event.y - board.y - (pac.posY + 0.5) * root.cell;
            if (Math.abs(dx) > Math.abs(dy))
                root.steer(Math.sign(dx), 0);
            else
                root.steer(0, Math.sign(dy));
        }
    }

    RowLayout {
        id: hud

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: board.top
        anchors.bottomMargin: Tokens.spacing.small
        width: board.width
        spacing: Tokens.spacing.small

        StyledText {
            text: String(root.score).padStart(5, "0")
            color: Hallownest.subtext
            font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
        }

        Row {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.cell * 0.4
            layoutDirection: Qt.RightToLeft

            Repeater {
                model: Math.max(0, root.lives - (root.phase === "waiting" ? 0 : 1))

                PacShape {
                    width: root.cell * 1.4
                    height: width
                    mouth: 35
                    rotation: 180
                }
            }
        }

        StyledText {
            text: `HI ${String(root.highScore).padStart(5, "0")}`
            color: Hallownest.faint
            font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
        }
    }

    Item {
        id: board

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.hudHeight + (parent.height - root.hudHeight - height) / 2
        width: root.cell * root.cols
        height: root.cell * root.rows
        clip: true

        Canvas {
            id: walls

            readonly property color colour: root.phase === "cleared" && blink.on ? Hallownest.text : Hallownest.soul

            anchors.fill: parent
            onColourChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                const c = root.cell;
                const isWall = (x, y) => "#=".includes(root.tileAt(x, y)) && !(y === 14 && (x < 0 || x >= root.cols));
                ctx.reset();
                ctx.fillStyle = colour;
                ctx.globalAlpha = 0.12;
                for (let y = 0; y < root.rows; y++)
                    for (let x = 0; x < root.cols; x++)
                        if (isWall(x, y))
                            ctx.fillRect(x * c, y * c, c, c);

                ctx.globalAlpha = 1;
                ctx.strokeStyle = colour;
                ctx.lineWidth = Math.max(1, c / 6);
                ctx.beginPath();
                for (let y = 0; y < root.rows; y++)
                    for (let x = 0; x < root.cols; x++) {
                        if (!isWall(x, y))
                            continue;
                        const inside = (nx, ny) => nx >= 0 && nx < root.cols && ny >= 0 && ny < root.rows;
                        if (inside(x, y - 1) && !isWall(x, y - 1)) {
                            ctx.moveTo(x * c, y * c);
                            ctx.lineTo((x + 1) * c, y * c);
                        }
                        if (inside(x, y + 1) && !isWall(x, y + 1)) {
                            ctx.moveTo(x * c, (y + 1) * c);
                            ctx.lineTo((x + 1) * c, (y + 1) * c);
                        }
                        if (inside(x - 1, y) && !isWall(x - 1, y)) {
                            ctx.moveTo(x * c, y * c);
                            ctx.lineTo(x * c, (y + 1) * c);
                        }
                        if (inside(x + 1, y) && !isWall(x + 1, y)) {
                            ctx.moveTo((x + 1) * c, y * c);
                            ctx.lineTo((x + 1) * c, (y + 1) * c);
                        }
                    }
                ctx.stroke();
            }
        }

        Rectangle {
            x: 13 * root.cell
            y: 12.4 * root.cell
            width: 2 * root.cell
            height: Math.max(1, root.cell / 5)
            color: "#ffb8de"
        }

        Canvas {
            id: dotsCanvas

            readonly property int version: root.dotsVersion

            anchors.fill: parent
            onVersionChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                const c = root.cell;
                const s = Math.max(2, Math.round(c / 4));
                ctx.reset();
                ctx.fillStyle = Hallownest.subtext;
                for (let i = 0; i < root.dots.length; i++)
                    if (root.dots[i])
                        ctx.fillRect(i % root.cols * c + (c - s) / 2, Math.floor(i / root.cols) * c + (c - s) / 2, s, s);
            }
        }

        Repeater {
            model: root.pellets

            Rectangle {
                required property var modelData
                required property int index

                x: (modelData[0] + 0.2) * root.cell
                y: (modelData[1] + 0.2) * root.cell
                width: root.cell * 0.6
                height: width
                radius: width / 2
                color: Hallownest.soul
                visible: root.pelletsLeft[index] && (blink.on || root.phase !== "running")
            }
        }

        Repeater {
            id: ghosts

            model: 4

            Ghost {}
        }

        PacShape {
            id: pac

            property int tileX
            property int tileY
            property int dirX
            property int dirY
            property real prog
            property int wantX
            property int wantY
            property real facing: 180
            readonly property real posX: tileX + dirX * prog
            readonly property real posY: tileY + dirY * prog

            function place(x: int, y: int, dx: int, dy: int): void {
                tileX = x;
                tileY = y;
                dirX = dx;
                dirY = dy;
                prog = 0;
                facing = 180;
            }

            x: (posX + 0.5) * root.cell - width / 2
            y: (posY + 0.5) * root.cell - height / 2
            width: root.cell * 1.6
            height: width
            visible: root.phase !== "waiting" && (root.phase !== "dying" || root.phaseTime < 1.4)
            mouth: {
                if (root.phase === "dying")
                    return Math.min(180, 30 + root.phaseTime * 140);
                if (root.phase !== "running")
                    return 30;
                return 4 + 36 * Math.abs(Math.sin(root.chomp * Math.PI));
            }
            rotation: root.phase === "dying" ? 270 : facing
        }
    }

    StyledText {
        anchors.horizontalCenter: board.horizontalCenter
        y: board.y + 16.85 * root.cell - height / 2
        visible: root.phase === "ready" || root.phase === "over" || root.phase === "waiting"
        text: {
            if (root.phase === "over")
                return Tr.tr("GAME OVER");
            if (root.phase === "ready")
                return Tr.tr("READY!");
            return Tr.tr("Press an arrow");
        }
        color: root.phase === "over" ? "#ff5c5c" : "#ffd93b"
        font: Tokens.font.mono.builders.small.weight(Font.Bold).build()
    }

    component Actor: Item {
        property int tileX
        property int tileY
        property int dirX
        property int dirY
        property real prog
    }

    component PacShape: Shape {
        id: pacShape

        property real mouth: 30

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "#ffd93b"
            strokeColor: "transparent"
            strokeWidth: 0
            startX: pacShape.width / 2
            startY: pacShape.height / 2

            PathAngleArc {
                centerX: pacShape.width / 2
                centerY: pacShape.height / 2
                radiusX: pacShape.width / 2
                radiusY: pacShape.height / 2
                startAngle: pacShape.mouth
                sweepAngle: 360 - pacShape.mouth * 2
            }

            PathLine {
                x: pacShape.width / 2
                y: pacShape.height / 2
            }
        }
    }

    component Ghost: Actor {
        id: ghost

        required property int index
        readonly property var corner: [[25, -3], [2, -3], [27, 31], [0, 31]][index]
        readonly property real releaseAt: [0, 1, 4, 7][index]
        readonly property color colour: ["#ff4d4d", "#ffa3d7", "#3fe0f0", "#ffb04d"][index]
        property string mode: "house" // house, active, eyes
        property bool frightened
        readonly property real feet: Math.floor(root.chomp * 2) % 2 ? 0.85 : 0.9
        readonly property real houseX: [13, 13, 11, 15][index]
        readonly property real posX: mode === "house" ? houseX : tileX + dirX * prog
        readonly property real posY: mode === "house" ? 14 + Math.sin(root.gameTime * 6 + index) * 0.25 : tileY + dirY * prog

        function reset(): void {
            frightened = false;
            prog = 0;
            if (index === 0) {
                mode = "active";
                tileX = 13;
                tileY = 11;
                dirX = -1;
                dirY = 0;
            } else {
                mode = "house";
                dirX = 0;
                dirY = -1;
            }
        }

        function release(): void {
            mode = "active";
            tileX = 13;
            tileY = 11;
            dirX = index % 2 ? -1 : 1;
            dirY = 0;
            prog = 0;
        }

        function reverse(): void {
            if (mode !== "active" || (!dirX && !dirY))
                return;
            tileX += dirX;
            tileY += dirY;
            root.wrap(ghost);
            dirX = -dirX;
            dirY = -dirY;
            prog = 1 - prog;
        }

        x: (posX + 0.5 + (mode === "house" ? 0.5 : 0)) * root.cell - width / 2
        y: (posY + 0.5) * root.cell - height / 2
        width: root.cell * 1.6
        height: width
        visible: root.phase !== "waiting" && root.phase !== "cleared" && (root.phase !== "dying" || root.phaseTime < 0.5)

        Shape {
            anchors.fill: parent
            visible: ghost.mode !== "eyes"
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: {
                    if (!ghost.frightened)
                        return ghost.colour;
                    return root.frightenedUntil - root.gameTime < 2 && blink.on ? "#e8e8ff" : "#3346ff";
                }
                strokeColor: "transparent"
                strokeWidth: 0
                startX: 0
                startY: ghost.width

                PathLine {
                    x: 0
                    y: ghost.width * 0.45
                }
                PathArc {
                    x: ghost.width
                    y: ghost.width * 0.45
                    radiusX: ghost.width / 2
                    radiusY: ghost.width * 0.45
                }
                PathLine {
                    x: ghost.width
                    y: ghost.width
                }
                PathLine {
                    x: ghost.width * 0.83
                    y: ghost.width * ghost.feet
                }
                PathLine {
                    x: ghost.width * 0.67
                    y: ghost.width
                }
                PathLine {
                    x: ghost.width * 0.5
                    y: ghost.width * ghost.feet
                }
                PathLine {
                    x: ghost.width * 0.33
                    y: ghost.width
                }
                PathLine {
                    x: ghost.width * 0.17
                    y: ghost.width * ghost.feet
                }
                PathLine {
                    x: 0
                    y: ghost.width
                }
            }
        }

        Repeater {
            model: 2

            Rectangle {
                id: eye

                required property int index

                x: ghost.width * (eye.index ? 0.55 : 0.15) + (ghost.frightened ? 0 : ghost.dirX * ghost.width * 0.05)
                y: ghost.width * 0.28 + (ghost.frightened ? 0 : ghost.dirY * ghost.width * 0.05)
                width: ghost.width * 0.3
                height: ghost.width * 0.34
                radius: width / 2
                color: ghost.frightened ? "transparent" : "white"

                Rectangle {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: ghost.frightened ? 0 : ghost.dirX * parent.width * 0.25
                    anchors.verticalCenterOffset: ghost.frightened ? 0 : ghost.dirY * parent.height * 0.25
                    width: parent.width * (ghost.frightened ? 0.5 : 0.55)
                    height: width
                    radius: width / 2
                    color: ghost.frightened ? "#ffd0a0" : "#2a3bd0"
                }
            }
        }
    }
}
