pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Beginner Minesweeper. Mines are placed after the first click so it is always safe
Item {
    id: root

    readonly property int cols: 9
    readonly property int rows: 9
    readonly property int mineCount: 10
    readonly property real cell: Math.max(8, Math.floor(Math.min(width / cols, (height - hud.height - Tokens.spacing.small) / rows)))
    readonly property var numberColours: ["transparent", "#6fa8ff", "#6fd36f", "#ff6b6b", "#b88cff", "#ff9b6b", "#4fd6d6", "#e0e0e0", "#9e9e9e"]

    property string phase: "ready" // ready, playing, won, lost
    property var mines: []
    property var counts: []
    property var revealed: []
    property var flagged: []
    property int flags
    property int exploded: -1
    property real startedAt
    property int elapsed
    property int bestTime

    function reset(): void {
        const empty = new Array(cols * rows).fill(false);
        mines = empty;
        counts = new Array(cols * rows).fill(0);
        revealed = empty;
        flagged = empty;
        flags = 0;
        exploded = -1;
        elapsed = 0;
        phase = "ready";
    }

    function neighbours(i: int): var {
        const x = i % cols;
        const y = Math.floor(i / cols);
        const n = [];
        for (let dy = -1; dy <= 1; dy++)
            for (let dx = -1; dx <= 1; dx++) {
                const nx = x + dx;
                const ny = y + dy;
                if ((dx || dy) && nx >= 0 && nx < cols && ny >= 0 && ny < rows)
                    n.push(ny * cols + nx);
            }
        return n;
    }

    function placeMines(safe: int): void {
        const banned = [safe, ...neighbours(safe)];
        const m = new Array(cols * rows).fill(false);
        let placed = 0;
        while (placed < mineCount) {
            const i = Math.floor(Math.random() * cols * rows);
            if (!m[i] && !banned.includes(i)) {
                m[i] = true;
                placed++;
            }
        }
        mines = m;
        counts = m.map((_, i) => neighbours(i).filter(n => m[n]).length);
        startedAt = Date.now();
        phase = "playing";
    }

    function reveal(i: int): void {
        if (phase === "won" || phase === "lost" || flagged[i])
            return;
        if (phase === "ready")
            placeMines(i);
        if (revealed[i])
            return chord(i);

        if (mines[i]) {
            exploded = i;
            revealed = revealed.map((r, j) => r || mines[j]);
            phase = "lost";
            return;
        }

        const r = revealed.slice();
        const stack = [i];
        while (stack.length) {
            const c = stack.pop();
            if (r[c] || flagged[c])
                continue;
            r[c] = true;
            if (counts[c] === 0)
                stack.push(...neighbours(c));
        }
        revealed = r;
        checkWin();
    }

    function chord(i: int): void {
        const around = neighbours(i);
        if (around.filter(n => flagged[n]).length !== counts[i])
            return;
        for (const n of around)
            if (!revealed[n] && !flagged[n])
                reveal(n);
    }

    function toggleFlag(i: int): void {
        if (phase === "won" || phase === "lost" || revealed[i])
            return;
        const f = flagged.slice();
        f[i] = !f[i];
        flagged = f;
        flags += f[i] ? 1 : -1;
    }

    function checkWin(): void {
        if (phase !== "playing" || revealed.filter(r => r).length !== cols * rows - mineCount)
            return;
        phase = "won";
        elapsed = Math.floor((Date.now() - startedAt) / 1000);
        flagged = mines.slice();
        flags = mineCount;
        if (!bestTime || elapsed < bestTime) {
            bestTime = elapsed;
            bestTimeFile.setText(String(elapsed));
        }
    }

    function keyPressed(key: int, isRepeat: bool): void {
    }

    function keyReleased(key: int): void {
    }

    Component.onCompleted: reset()

    FileView {
        id: bestTimeFile

        path: `${Paths.state}/minesweeper-best`
        printErrors: false
        onLoaded: root.bestTime = parseInt(text()) || 0
    }

    Timer {
        interval: 250
        repeat: true
        running: root.phase === "playing" && root.visible
        onTriggered: root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        RowLayout {
            id: hud

            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "flag"
                color: Hallownest.grimm
                fill: 1
            }

            StyledText {
                Layout.fillWidth: true
                text: String(root.mineCount - root.flags).padStart(3, "0")
                color: Hallownest.subtext
                font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: face.implicitHeight + Tokens.padding.extraSmall * 2
                radius: Tokens.rounding.full
                color: Hallownest.button
                border.width: 1
                border.color: Hallownest.border

                StateLayer {
                    color: Hallownest.soul
                    onClicked: root.reset()
                }

                MaterialIcon {
                    id: face

                    anchors.centerIn: parent
                    text: {
                        if (root.phase === "lost")
                            return "sentiment_very_dissatisfied";
                        if (root.phase === "won")
                            return "sentiment_very_satisfied";
                        return "sentiment_satisfied";
                    }
                    color: Hallownest.soul
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: (root.bestTime ? `${root.bestTime}s · ` : "") + String(root.elapsed).padStart(3, "0")
                color: Hallownest.subtext
                font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
            }

            MaterialIcon {
                text: "timer"
                color: Hallownest.faint
            }
        }

        Grid {
            columns: root.cols
            spacing: 0

            Repeater {
                model: root.cols * root.rows

                Item {
                    id: tile

                    required property int index
                    readonly property bool open: root.revealed[index] ?? false
                    readonly property bool flag: root.flagged[index] ?? false
                    readonly property bool mine: root.mines[index] ?? false

                    implicitWidth: root.cell
                    implicitHeight: root.cell

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: Math.max(1, root.cell / 16)
                        radius: Tokens.rounding.small / 2
                        color: {
                            if (root.exploded === tile.index)
                                return Hallownest.grimm;
                            if (tile.open)
                                return "transparent";
                            return Hallownest.button;
                        }

                        StateLayer {
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            disabled: tile.open && root.counts[tile.index] === 0
                            onClicked: event => {
                                if (event.button === Qt.RightButton)
                                    root.toggleFlag(tile.index);
                                else if (event.button === Qt.MiddleButton)
                                    root.chord(tile.index);
                                else
                                    root.reveal(tile.index);
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            visible: tile.open && !tile.mine && root.counts[tile.index] > 0
                            text: root.counts[tile.index] ?? ""
                            color: root.numberColours[root.counts[tile.index] ?? 0]
                            font: Tokens.font.mono.builders.small.weight(Font.Bold).build()
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            visible: tile.flag || (tile.open && tile.mine)
                            text: {
                                if (tile.flag && root.phase === "lost" && !tile.mine)
                                    return "close";
                                return tile.flag ? "flag" : "coronavirus";
                            }
                            color: {
                                if (root.exploded === tile.index)
                                    return Hallownest.void_;
                                return tile.flag ? Hallownest.grimm : Hallownest.subtext;
                            }
                            fill: 1
                        }
                    }
                }
            }
        }
    }
}
