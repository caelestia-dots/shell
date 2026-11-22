pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// Sudoku with a unique solution. Only arrows reach the lock screen games, so digits come from the pad
Item {
    id: root

    readonly property int clues: 34
    readonly property real cell: Math.max(10, Math.floor(Math.min(width / 9, (height - hud.height - pad.height - Tokens.spacing.small * 2) / 9)))

    property string phase: "playing" // playing, won
    property var givens: [] // 81 digits, 0 = blank
    property var values: [] // what the player sees, givens included
    property int selected: -1
    property real startedAt
    property int elapsed
    property int bestTime
    // Same row, column or box of each cell; built once, the solver reads it constantly
    readonly property var peerTable: [...Array(81).keys()].map(i => peers(i))
    readonly property var conflicts: {
        const bad = new Array(81).fill(false);
        const pt = peerTable;
        for (let i = 0; i < 81; i++)
            if (values[i])
                for (const p of pt[i])
                    if (values[p] === values[i])
                        bad[i] = true;
        return bad;
    }

    function peers(i: int): var {
        const r = Math.floor(i / 9);
        const c = i % 9;
        const br = r - r % 3;
        const bc = c - c % 3;
        const out = [];
        for (let k = 0; k < 9; k++) {
            if (k !== c)
                out.push(r * 9 + k);
            if (k !== r)
                out.push(k * 9 + c);
            const j = (br + Math.floor(k / 3)) * 9 + bc + k % 3;
            if (Math.floor(j / 9) !== r && j % 9 !== c)
                out.push(j);
        }
        return out;
    }

    // Digits still free at cell i, as bits 1-9
    function freeDigits(grid: var, pt: var, i: int): int {
        let used = 0;
        const peers = pt[i];
        for (let k = 0; k < 20; k++)
            used |= 1 << grid[peers[k]];
        return ~used & 0x3fe;
    }

    function shuffle(a: var): var {
        for (let i = a.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [a[i], a[j]] = [a[j], a[i]];
        }
        return a;
    }

    // Counts solutions up to `limit`, filling the most constrained blank first. `pt` is peerTable,
    // passed in because reading a var property from JS copies it on every access
    function solve(grid: var, pt: var, limit: int, randomise: bool): int {
        let best = -1;
        let bestFree = 0;
        let bestCount = 10;
        for (let i = 0; i < 81; i++) {
            if (grid[i])
                continue;
            const free = freeDigits(grid, pt, i);
            let count = 0;
            for (let f = free; f; f &= f - 1)
                count++;
            if (count < bestCount) {
                best = i;
                bestFree = free;
                bestCount = count;
                if (!count)
                    return 0;
            }
        }
        if (best < 0)
            return 1;
        const digits = [];
        for (let d = 1; d <= 9; d++)
            if (bestFree & 1 << d)
                digits.push(d);
        let found = 0;
        for (const d of randomise ? shuffle(digits) : digits) {
            grid[best] = d;
            found += solve(grid, pt, limit - found, randomise);
            if (found >= limit)
                return found; // leaves the grid filled when limit is 1
        }
        grid[best] = 0;
        return found;
    }

    function generate(): var {
        const full = new Array(81).fill(0);
        const pt = peerTable;
        solve(full, pt, 1, true);
        const puzzle = full.slice();
        let left = 81;
        for (const i of shuffle([...Array(81).keys()])) {
            if (left <= clues)
                break;
            const keep = puzzle[i];
            puzzle[i] = 0;
            if (solve(puzzle.slice(), pt, 2, false) !== 1)
                puzzle[i] = keep;
            else
                left--;
        }
        return puzzle;
    }

    function newGame(): void {
        givens = generate();
        values = givens.slice();
        selected = -1;
        elapsed = 0;
        startedAt = Date.now();
        phase = "playing";
    }

    function put(digit: int): void {
        if (phase !== "playing" || selected < 0 || givens[selected])
            return;
        const v = values.slice();
        v[selected] = v[selected] === digit ? 0 : digit;
        values = v;
        if (v.every(d => d) && !conflicts.some(b => b))
            win();
    }

    function win(): void {
        phase = "won";
        elapsed = Math.floor((Date.now() - startedAt) / 1000);
        if (!bestTime || elapsed < bestTime) {
            bestTime = elapsed;
            bestTimeFile.setText(String(elapsed));
        }
    }

    function clock(s: int): string {
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    function keyPressed(key: int, isRepeat: bool): void {
        const r = selected < 0 ? 4 : Math.floor(selected / 9);
        const c = selected < 0 ? 4 : selected % 9;
        if (selected < 0)
            selected = 40;
        else if (key === Qt.Key_Left)
            selected = r * 9 + (c + 8) % 9;
        else if (key === Qt.Key_Right)
            selected = r * 9 + (c + 1) % 9;
        else if (key === Qt.Key_Up)
            selected = (r + 8) % 9 * 9 + c;
        else if (key === Qt.Key_Down)
            selected = (r + 1) % 9 * 9 + c;
    }

    function keyReleased(key: int): void {
    }

    Component.onCompleted: newGame()

    FileView {
        id: bestTimeFile

        path: `${Paths.state}/sudoku-best`
        printErrors: false
        onLoaded: root.bestTime = parseInt(text()) || 0
    }

    Timer {
        interval: 500
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
                text: "timer"
                color: Hallownest.faint
            }

            StyledText {
                Layout.fillWidth: true
                text: root.phase === "won" ? Tr.tr("Solved in %1").arg(root.clock(root.elapsed)) : root.clock(root.elapsed)
                color: root.phase === "won" ? Hallownest.unn : Hallownest.subtext
                font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
            }

            StyledText {
                visible: root.bestTime > 0
                text: Tr.tr("Best %1").arg(root.clock(root.bestTime))
                color: Hallownest.faint
                font: Tokens.font.mono.small
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: refresh.implicitHeight + Tokens.padding.extraSmall * 2
                radius: Tokens.rounding.full
                color: Hallownest.button
                border.width: 1
                border.color: Hallownest.border

                StateLayer {
                    color: Hallownest.soul
                    onClicked: root.newGame()
                }

                MaterialIcon {
                    id: refresh

                    anchors.centerIn: parent
                    text: "refresh"
                    color: Hallownest.soul
                }
            }
        }

        Item {
            implicitWidth: root.cell * 9
            implicitHeight: root.cell * 9

            Repeater {
                model: 81

                Rectangle {
                    id: tile

                    required property int index
                    readonly property int row: Math.floor(index / 9)
                    readonly property int col: index % 9
                    readonly property int value: root.values[index] ?? 0
                    readonly property bool given: (root.givens[index] ?? 0) !== 0
                    readonly property int sel: root.selected
                    readonly property bool related: sel >= 0 && (Math.floor(sel / 9) === row || sel % 9 === col || (Math.floor(sel / 27) === Math.floor(row / 3) && Math.floor(sel % 9 / 3) === Math.floor(col / 3)))
                    readonly property bool sameDigit: sel >= 0 && value !== 0 && root.values[sel] === value

                    x: col * root.cell
                    y: row * root.cell
                    width: root.cell
                    height: root.cell
                    color: {
                        if (sel === index)
                            return Qt.alpha(Hallownest.soul, 0.24);
                        if (sameDigit)
                            return Qt.alpha(Hallownest.soul, 0.14);
                        if (related)
                            return Qt.alpha(Hallownest.text, 0.06);
                        return Qt.alpha(Hallownest.text, 0.02);
                    }
                    border.width: 1
                    border.color: Hallownest.border

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: event => {
                            root.selected = tile.index;
                            if (event.button === Qt.RightButton && !tile.given && tile.value)
                                root.put(tile.value);
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        visible: tile.value !== 0
                        text: tile.value
                        color: {
                            if (root.conflicts[tile.index])
                                return Hallownest.grimm;
                            return tile.given ? Hallownest.text : Hallownest.lifeblood;
                        }
                        font: Tokens.font.mono.builders.small.size(Math.max(7, root.cell * 0.42)).weight(tile.given ? Font.Bold : Font.Medium).build()
                    }
                }
            }

            // Thicker lines between the 3x3 boxes
            Repeater {
                model: 4

                Item {
                    id: line

                    required property int index

                    Rectangle {
                        x: line.index * 3 * root.cell - 1
                        width: 2
                        height: root.cell * 9
                        color: Hallownest.steel
                    }

                    Rectangle {
                        y: line.index * 3 * root.cell - 1
                        width: root.cell * 9
                        height: 2
                        color: Hallownest.steel
                    }
                }
            }
        }

        RowLayout {
            id: pad

            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            Repeater {
                model: 9

                StyledRect {
                    id: key

                    required property int index
                    readonly property int digit: index + 1

                    implicitWidth: root.cell - 2
                    implicitHeight: Math.max(20, root.cell * 0.8)
                    radius: Tokens.rounding.small
                    color: Hallownest.button
                    border.width: 1
                    border.color: Hallownest.border
                    opacity: root.values.filter(v => v === key.digit).length >= 9 ? 0.35 : 1

                    StateLayer {
                        color: Hallownest.soul
                        onClicked: root.put(key.digit)
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: key.digit
                        color: Hallownest.text
                        font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
                    }
                }
            }
        }
    }
}
