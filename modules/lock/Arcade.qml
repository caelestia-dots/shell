pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// Game picker shown in the lock screen when there are no notifications
ColumnLayout {
    id: root

    property string label
    property string current: "dino"
    readonly property var games: [
        {
            id: "dino",
            name: Tr.tr("Dino"),
            icon: "pets"
        },
        {
            id: "tetris",
            name: Tr.tr("Tetris"),
            icon: "view_quilt"
        },
        {
            id: "pacman",
            name: Tr.tr("Pac-Man"),
            icon: "pie_chart"
        },
        {
            id: "minesweeper",
            name: Tr.tr("Minesweeper"),
            icon: "flag"
        },
        {
            id: "snake",
            name: Tr.tr("Snake"),
            icon: "gesture"
        },
        {
            id: "sudoku",
            name: Tr.tr("Sudoku"),
            icon: "grid_on"
        }
    ]

    function select(id: string): void {
        if (current === id)
            return;
        current = id;
        lastGameFile.setText(id);
    }

    function keyPressed(key: int, isRepeat: bool): void {
        gameLoader.item?.keyPressed(key, isRepeat);
    }

    function keyReleased(key: int): void {
        gameLoader.item?.keyReleased(key);
    }

    spacing: Tokens.spacing.medium

    FileView {
        id: lastGameFile

        path: `${Paths.state}/lock-game`
        printErrors: false
        onLoaded: {
            const id = text().trim();
            if (root.games.some(g => g.id === id))
                root.current = id;
        }
    }

    Loader {
        id: gameLoader

        Layout.fillWidth: true
        Layout.fillHeight: true

        sourceComponent: {
            if (root.current === "tetris")
                return tetris;
            if (root.current === "pacman")
                return pacman;
            if (root.current === "minesweeper")
                return minesweeper;
            if (root.current === "snake")
                return snake;
            if (root.current === "sudoku")
                return sudoku;
            return dino;
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: root.label
            color: Hallownest.faint
            font: Tokens.font.mono.builders.medium.weight(Font.Medium).build()
            elide: Text.ElideRight
        }

        Repeater {
            model: root.games

            StyledRect {
                id: chip

                required property var modelData
                readonly property bool selected: root.current === modelData.id

                implicitWidth: implicitHeight
                implicitHeight: icon.implicitHeight + Tokens.padding.small * 2
                radius: selected ? Tokens.rounding.medium : Tokens.rounding.full
                color: selected ? Qt.alpha(Hallownest.soul, 0.14) : "transparent"
                border.width: selected ? 1 : 0
                border.color: Qt.alpha(Hallownest.soul, 0.45)

                StateLayer {
                    color: Hallownest.soul
                    onClicked: root.select(chip.modelData.id)
                }

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: chip.modelData.icon
                    color: chip.selected ? Hallownest.soul : Hallownest.subtext
                    fill: chip.selected ? 1 : 0
                }

                Behavior on radius {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }
            }
        }
    }

    Component {
        id: dino

        Item {
            function keyPressed(key: int, isRepeat: bool): void {
                if (!isRepeat)
                    dinoGame.keyPressed(key);
            }

            function keyReleased(key: int): void {
                dinoGame.keyReleased(key);
            }

            DinoGame {
                id: dinoGame

                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height * worldWidth / worldHeight)
            }
        }
    }

    Component {
        id: tetris

        TetrisGame {}
    }

    Component {
        id: pacman

        PacmanGame {}
    }

    Component {
        id: minesweeper

        MinesweeperGame {}
    }

    Component {
        id: snake

        SnakeGame {}
    }

    Component {
        id: sudoku

        SudokuGame {}
    }
}
