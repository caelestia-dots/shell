pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// Tetris with a 7-bag randomiser and simple wall kicks
Item {
    id: root

    readonly property int cols: 10
    readonly property int rows: 20
    readonly property real cell: Math.max(4, Math.floor(Math.min(height / rows, (width - Tokens.spacing.large) / (cols + 5))))
    // Spawn shapes as [x, y] cells inside an n x n box: I, O, T, S, Z, J, L
    readonly property var shapes: [null, {
            n: 4,
            cells: [[0, 1], [1, 1], [2, 1], [3, 1]]
        }, {
            n: 2,
            cells: [[0, 0], [1, 0], [0, 1], [1, 1]]
        }, {
            n: 3,
            cells: [[1, 0], [0, 1], [1, 1], [2, 1]]
        }, {
            n: 3,
            cells: [[1, 0], [2, 0], [0, 1], [1, 1]]
        }, {
            n: 3,
            cells: [[0, 0], [1, 0], [1, 1], [2, 1]]
        }, {
            n: 3,
            cells: [[0, 0], [0, 1], [1, 1], [2, 1]]
        }, {
            n: 3,
            cells: [[2, 0], [0, 1], [1, 1], [2, 1]]
        }]
    readonly property var colours: ["transparent", "#3fd8e8", "#f2d43a", "#b05ce6", "#5fd35a", "#ec4f4f", "#4d7cf0", "#f29a38"]

    property string phase: "waiting" // waiting, running, over
    property var board: new Array(cols * rows).fill(0)
    property var bag: []
    property int pieceType
    property int nextType
    property int rot
    property int px
    property int py
    property int score
    property int lines
    readonly property int level: 1 + Math.floor(lines / 10)
    property int highScore
    property real overAt

    readonly property var display: {
        const d = board.slice();
        if (phase === "waiting" || !pieceType)
            return d;
        let gy = py;
        while (fits(pieceType, rot, px, gy + 1))
            gy++;
        for (const [x, y] of pieceCells(pieceType, rot, px, gy))
            if (y >= 0 && !d[y * cols + x])
                d[y * cols + x] = -pieceType;
        for (const [x, y] of pieceCells(pieceType, rot, px, py))
            if (y >= 0)
                d[y * cols + x] = pieceType;
        return d;
    }

    function pieceCells(type: int, rotation: int, ox: int, oy: int): var {
        const shape = shapes[type];
        return shape.cells.map(c => {
            let [x, y] = c;
            for (let i = 0; i < rotation % 4; i++)
                [x, y] = [shape.n - 1 - y, x];
            return [ox + x, oy + y];
        });
    }

    function fits(type: int, rotation: int, ox: int, oy: int): bool {
        for (const [x, y] of pieceCells(type, rotation, ox, oy)) {
            if (x < 0 || x >= cols || y >= rows)
                return false;
            if (y >= 0 && board[y * cols + x])
                return false;
        }
        return true;
    }

    function takeFromBag(): int {
        if (bag.length === 0) {
            const b = [1, 2, 3, 4, 5, 6, 7];
            for (let i = b.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [b[i], b[j]] = [b[j], b[i]];
            }
            bag = b;
        }
        return bag.pop();
    }

    function spawn(): void {
        pieceType = nextType;
        nextType = takeFromBag();
        rot = 0;
        px = pieceType === 2 ? 4 : 3;
        py = pieceType === 1 ? -1 : 0;
        if (!fits(pieceType, rot, px, py))
            gameOver();
    }

    function start(): void {
        board = new Array(cols * rows).fill(0);
        bag = [];
        score = 0;
        lines = 0;
        nextType = takeFromBag();
        phase = "running";
        spawn();
    }

    function gameOver(): void {
        phase = "over";
        overAt = Date.now();
        if (score > highScore) {
            highScore = score;
            highScoreFile.setText(String(score));
        }
    }

    function move(dx: int): void {
        if (fits(pieceType, rot, px + dx, py))
            px += dx;
    }

    function rotate(): void {
        const r = (rot + 1) % 4;
        for (const [kx, ky] of [[0, 0], [-1, 0], [1, 0], [-2, 0], [2, 0], [0, -1]]) {
            if (fits(pieceType, r, px + kx, py + ky)) {
                px += kx;
                py += ky;
                rot = r;
                return;
            }
        }
    }

    function drop(): void {
        if (fits(pieceType, rot, px, py + 1))
            py++;
        else
            lockPiece();
    }

    function hardDrop(): void {
        while (fits(pieceType, rot, px, py + 1)) {
            py++;
            score += 2;
        }
        lockPiece();
    }

    function lockPiece(): void {
        const b = board.slice();
        for (const [x, y] of pieceCells(pieceType, rot, px, py)) {
            if (y < 0)
                return gameOver();
            b[y * cols + x] = pieceType;
        }

        let cleared = 0;
        for (let y = rows - 1; y >= 0; y--) {
            const row = b.slice(y * cols, (y + 1) * cols);
            if (row.every(c => c)) {
                b.splice(y * cols, cols);
                b.unshift(...new Array(cols).fill(0));
                cleared++;
                y++;
            }
        }
        score += [0, 100, 300, 500, 800][cleared] * level;
        lines += cleared;
        board = b;
        spawn();
        gravity.restart();
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
            move(-1);
        else if (key === Qt.Key_Right)
            move(1);
        else if (key === Qt.Key_Up && !isRepeat)
            rotate();
        else if (key === Qt.Key_Down) {
            drop();
            score++;
        }
    }

    function keyReleased(key: int): void {
    }

    FileView {
        id: highScoreFile

        path: `${Paths.state}/tetris-hi`
        printErrors: false
        onLoaded: root.highScore = parseInt(text()) || 0
    }

    Timer {
        id: gravity

        interval: Math.max(80, 800 - (root.level - 1) * 70)
        repeat: true
        running: root.phase === "running" && root.visible
        onTriggered: root.drop()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: event => {
            if (root.phase !== "running") {
                if (root.canStart())
                    root.start();
            } else if (event.button === Qt.RightButton) {
                root.hardDrop();
            } else {
                root.rotate();
            }
        }
        onWheel: event => {
            if (root.phase === "running")
                root.move(event.angleDelta.y > 0 ? -1 : 1);
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: Tokens.spacing.large

        StyledRect {
            width: root.cell * root.cols
            height: root.cell * root.rows
            radius: Tokens.rounding.small
            color: Qt.alpha(Hallownest.text, 0.05)

            Repeater {
                model: root.cols * root.rows

                Rectangle {
                    required property int index
                    readonly property int value: root.display[index]

                    x: index % root.cols * root.cell + 1
                    y: Math.floor(index / root.cols) * root.cell + 1
                    width: root.cell - 2
                    height: root.cell - 2
                    radius: 2
                    visible: value !== 0
                    color: value > 0 ? root.colours[value] : "transparent"
                    border.width: value < 0 ? 1 : 0
                    border.color: root.colours[Math.abs(value)]
                    opacity: root.phase === "over" && value > 0 ? 0.5 : 1
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

        ColumnLayout {
            width: root.cell * 4
            spacing: Tokens.spacing.small

            Info {
                label: Tr.tr("Next")
            }

            Item {
                implicitWidth: root.cell * 4
                implicitHeight: root.cell * 3

                Repeater {
                    model: root.nextType ? root.pieceCells(root.nextType, 0, 0, 0) : []

                    Rectangle {
                        required property var modelData
                        readonly property real offset: (4 - root.shapes[root.nextType].n) * root.cell / 2

                        x: offset + modelData[0] * root.cell * 0.8 + 1
                        y: root.cell / 2 + modelData[1] * root.cell * 0.8 + 1
                        width: root.cell * 0.8 - 2
                        height: root.cell * 0.8 - 2
                        radius: 2
                        color: root.colours[root.nextType]
                    }
                }
            }

            Info {
                label: Tr.tr("Score")
                value: root.score
            }

            Info {
                label: Tr.tr("Lines")
                value: root.lines
            }

            Info {
                label: Tr.tr("Level")
                value: root.level
            }

            Info {
                label: Tr.tr("Best")
                value: root.highScore
            }
        }
    }

    component Info: ColumnLayout {
        id: info

        property string label
        property var value: null

        spacing: 0

        StyledText {
            text: info.label
            color: Hallownest.faint
            font: Tokens.font.mono.small
        }

        StyledText {
            visible: info.value !== null
            text: info.value ?? ""
            color: Hallownest.subtext
            font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
        }
    }
}
