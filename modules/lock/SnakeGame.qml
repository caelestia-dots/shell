pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// Snake on a walled board; it speeds up a little with every bite
Item {
    id: root

    readonly property int cols: 20
    readonly property int rows: 15
    readonly property real cell: Math.max(6, Math.floor(Math.min(width / cols, (height - hud.height - Tokens.spacing.small) / rows)))

    property string phase: "waiting" // waiting, running, over
    property var snake: [] // cell indices, head first
    property var dir: [1, 0]
    property var queued: [] // up to two pending turns, so quick double taps aren't lost
    property int food: -1
    property int score
    property int highScore
    property real overAt

    function start(): void {
        const y = Math.floor(rows / 2);
        snake = [y * cols + 6, y * cols + 5, y * cols + 4];
        dir = [1, 0];
        queued = [];
        score = 0;
        placeFood();
        phase = "running";
    }

    function placeFood(): void {
        const free = [];
        for (let i = 0; i < cols * rows; i++)
            if (!snake.includes(i))
                free.push(i);
        food = free.length ? free[Math.floor(Math.random() * free.length)] : -1;
    }

    function turn(dx: int, dy: int): void {
        const last = queued.length ? queued[queued.length - 1] : dir;
        // No reversing into yourself, and no repeating the current heading
        if ((dx === -last[0] && dy === -last[1]) || (dx === last[0] && dy === last[1]) || queued.length >= 2)
            return;
        queued = queued.concat([[dx, dy]]);
    }

    function step(): void {
        if (queued.length) {
            dir = queued[0];
            queued = queued.slice(1);
        }
        const hx = snake[0] % cols + dir[0];
        const hy = Math.floor(snake[0] / cols) + dir[1];
        const head = hy * cols + hx;
        const eats = head === food;
        // The tail moves out of the way this tick unless the snake grows
        const body = eats ? snake : snake.slice(0, -1);
        if (hx < 0 || hx >= cols || hy < 0 || hy >= rows || body.includes(head))
            return gameOver();
        snake = [head].concat(body);
        if (eats) {
            score++;
            placeFood();
            if (food < 0)
                gameOver();
        }
    }

    function gameOver(): void {
        phase = "over";
        overAt = Date.now();
        if (score > highScore) {
            highScore = score;
            highScoreFile.setText(String(score));
        }
    }

    function canStart(): bool {
        return phase === "waiting" || (phase === "over" && Date.now() - overAt > 500);
    }

    function keyPressed(key: int, isRepeat: bool): void {
        if (phase !== "running") {
            if (!isRepeat && canStart())
                start();
            return;
        }
        if (key === Qt.Key_Left)
            turn(-1, 0);
        else if (key === Qt.Key_Right)
            turn(1, 0);
        else if (key === Qt.Key_Up)
            turn(0, -1);
        else if (key === Qt.Key_Down)
            turn(0, 1);
    }

    function keyReleased(key: int): void {
    }

    FileView {
        id: highScoreFile

        path: `${Paths.state}/snake-hi`
        printErrors: false
        onLoaded: root.highScore = parseInt(text()) || 0
    }

    Timer {
        interval: Math.max(60, 150 - root.score * 3)
        repeat: true
        running: root.phase === "running" && root.visible
        onTriggered: root.step()
    }

    MouseArea {
        anchors.fill: parent
        onPressed: {
            if (root.phase !== "running" && root.canStart())
                root.start();
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        RowLayout {
            id: hud

            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "nutrition"
                color: Hallownest.grimm
                fill: 1
            }

            StyledText {
                Layout.fillWidth: true
                text: String(root.score).padStart(3, "0")
                color: Hallownest.subtext
                font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
            }

            StyledText {
                text: Tr.tr("Best %1").arg(root.highScore)
                color: Hallownest.faint
                font: Tokens.font.mono.small
            }
        }

        StyledRect {
            implicitWidth: root.cell * root.cols
            implicitHeight: root.cell * root.rows
            radius: Tokens.rounding.small
            color: Qt.alpha(Hallownest.text, 0.05)

            Rectangle {
                visible: root.food >= 0 && root.phase !== "waiting"
                x: root.food % root.cols * root.cell + root.cell * 0.2
                y: Math.floor(root.food / root.cols) * root.cell + root.cell * 0.2
                width: root.cell * 0.6
                height: width
                radius: width / 2
                color: Hallownest.grimm
            }

            Repeater {
                model: root.snake

                Rectangle {
                    required property int modelData
                    required property int index

                    x: modelData % root.cols * root.cell + 1
                    y: Math.floor(modelData / root.cols) * root.cell + 1
                    width: root.cell - 2
                    height: root.cell - 2
                    radius: index === 0 ? root.cell / 3 : 2
                    color: Hallownest.unn
                    opacity: root.phase === "over" ? 0.5 : 1 - Math.min(0.5, index / (root.snake.length * 2))
                }
            }

            StyledText {
                anchors.centerIn: parent
                width: parent.width - Tokens.padding.small * 2
                visible: root.phase !== "running"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.phase === "over" ? Tr.tr("GAME OVER") : Tr.tr("Click or press an arrow to play")
                color: Hallownest.subtext
                font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
            }
        }
    }
}
