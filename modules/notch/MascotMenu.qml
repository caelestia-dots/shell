pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.hallownest
import qs.services

// Mascot animation picker, toggled with the paleshell:mascot global shortcut
Scope {
    id: root

    readonly property string kind: NotchSettings.mascotKind
    readonly property var entries: [
        {
            id: "",
            name: Tr.tr("Random"),
            icon: "casino"
        },
        {
            id: "happy",
            name: Tr.tr("Happy"),
            icon: "sentiment_very_satisfied"
        },
        {
            id: "vibe",
            name: Tr.tr("Vibe"),
            icon: "music_note"
        },
        {
            id: "sad",
            name: Tr.tr("Sad"),
            icon: "sentiment_dissatisfied"
        },
        {
            id: "cry",
            name: Tr.tr("Cry"),
            icon: "water_drop"
        },
        {
            id: "angry",
            name: Tr.tr("Angry"),
            icon: "sentiment_extremely_dissatisfied"
        },
        {
            id: "shocked",
            name: Tr.tr("Shocked"),
            icon: "bolt"
        },
        {
            id: "infected",
            name: Tr.tr("Infected"),
            icon: "coronavirus"
        },
        {
            id: "soul",
            name: Tr.tr("Soul"),
            icon: "auto_awesome"
        },
        {
            id: "void",
            name: Tr.tr("Void"),
            icon: "dark_mode"
        },
        {
            id: "boss",
            name: kind === "grimm" ? Tr.tr("Nightmare King") : kind === "hornet" ? Tr.tr("Final form") : Tr.tr("Hollow Knight"),
            icon: kind === "grimm" ? "local_fire_department" : kind === "hornet" ? "auto_fix_high" : "skull"
        },
        {
            id: "look",
            name: Tr.tr("Look around"),
            icon: "visibility"
        },
        {
            id: "tilt",
            name: Tr.tr("Tilt"),
            icon: "rotate_right"
        },
        {
            id: "hop",
            name: Tr.tr("Hop"),
            icon: "north"
        },
        {
            id: "confused",
            name: Tr.tr("Confused"),
            icon: "help"
        },
        {
            id: "sigh",
            name: Tr.tr("Sigh"),
            icon: "air"
        },
        {
            id: "stare",
            name: Tr.tr("Stare"),
            icon: "sentiment_neutral"
        }
    ].concat(kind === "grimm" ? [
        {
            id: "bow",
            name: Tr.tr("Bow"),
            icon: "theater_comedy"
        },
        {
            id: "teleport",
            name: Tr.tr("Teleport"),
            icon: "whatshot"
        }
    ] : kind === "hornet" ? [
        {
            id: "dash",
            name: Tr.tr("Dash"),
            icon: "fast_forward"
        }
    ] : [])

    function toggle(): void {
        if (loader.active)
            loader.item.close();
        else
            loader.activeAsync = true;
    }

    function pick(entry: var): void {
        const s = ShellState.forActive();
        s.mascotPick = entry.id;
        s.mascotCalls++;
        loader.item?.close();
    }

    LazyLoader {
        id: loader

        StyledWindow {
            id: win

            property bool closing

            function close(): void {
                closing = true;
            }

            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "mascot-menu"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Item {
                id: content

                property bool shown

                anchors.fill: parent
                opacity: win.closing ? 0 : shown ? 1 : 0

                Component.onCompleted: shown = true

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                        onRunningChanged: {
                            if (!running && win.closing)
                                loader.active = false;
                        }
                    }
                }

                // Backdrop, click to close
                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha("black", 0.45)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: win.close()
                    }
                }

                HkCard {
                    id: card

                    property real enter

                    anchors.centerIn: parent
                    implicitWidth: 3 * 136 + Tokens.padding.extraLarge * 2
                    implicitHeight: layout.implicitHeight + Tokens.padding.extraLarge * 2
                    ornate: true
                    scale: 0.96 + enter * 0.04
                    filigreeDrawn: 0

                    transform: Translate {
                        y: (1 - card.enter) * 10
                    }

                    Component.onCompleted: enterAnim.start()

                    ParallelAnimation {
                        id: enterAnim

                        Anim {
                            target: card
                            property: "enter"
                            from: 0
                            to: 1
                            type: Anim.FastSpatial
                        }
                        NumberAnimation {
                            target: card
                            property: "filigreeDrawn"
                            from: 0
                            to: 1
                            duration: 460
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // Swallow clicks so they don't reach the backdrop
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: layout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.extraLarge
                        spacing: Tokens.spacing.medium

                        HkTitle {
                            Layout.alignment: Qt.AlignHCenter
                            text: Tr.tr("Mascot")
                        }

                        HkDivider {
                            Layout.fillWidth: true
                        }

                        GridView {
                            id: grid

                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.ceil(count / 3) * cellHeight
                            focus: true
                            interactive: false
                            // Defaults to interactive, which is off because the grid never scrolls
                            keyNavigationEnabled: true
                            cellWidth: width / 3
                            cellHeight: 64
                            model: root.entries
                            highlightMoveDuration: 0

                            Keys.onEscapePressed: win.close()
                            Keys.onReturnPressed: root.pick(root.entries[currentIndex])
                            Keys.onEnterPressed: root.pick(root.entries[currentIndex])

                            highlight: Rectangle {
                                radius: 12
                                color: Qt.alpha(Hallownest.soul, 0.1)
                                border.width: 1
                                border.color: Qt.alpha(Hallownest.soul, 0.45)
                            }

                            delegate: Item {
                                id: cell

                                required property var modelData
                                required property int index
                                readonly property color tint: modelData.id ? Hallownest.text : Hallownest.gold

                                width: grid.cellWidth
                                height: grid.cellHeight

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: cell.modelData.icon
                                        color: cell.tint
                                        fontStyle: Tokens.font.icon.large
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: cell.modelData.name
                                        color: cell.tint
                                        font.weight: cell.modelData.id ? Font.Normal : Font.Bold
                                        font.pointSize: 9
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: grid.currentIndex = cell.index
                                    onClicked: root.pick(cell.modelData)
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: Tr.tr("Arrows to move · Enter to play · Esc to close")
                            color: Hallownest.faint
                            font.pointSize: 8
                        }
                    }
                }
            }
        }
    }
}
