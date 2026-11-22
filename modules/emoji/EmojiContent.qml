pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.utils

Item {
    id: root

    // [{ char, label }]
    property var all: []
    property var recent: []
    readonly property string query: normalise(search.text.trim())
    readonly property var results: {
        if (!query) {
            const recents = recent.map(c => all.find(e => e.char === c)).filter(e => !!e);
            const first = Math.max(0, all.findIndex(e => e.char === "😀"));
            return recents.concat(all.slice(first).filter(e => !recent.includes(e.char))).slice(0, 240);
        }
        const words = query.split(/\s+/);
        const out = [];
        for (const e of all) {
            if (words.every(w => e.search.includes(w))) {
                out.push(e);
                if (out.length >= 240)
                    break;
            }
        }
        return out;
    }
    readonly property var current: results[grid.currentIndex] ?? null

    signal close

    function normalise(text: string): string {
        return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
    }

    function pick(entry: var): void {
        if (!entry)
            return;
        Quickshell.execDetached(["wl-copy", "--", entry.char]);
        recent = [entry.char].concat(recent.filter(c => c !== entry.char)).slice(0, 24);
        recentFile.setText(JSON.stringify(recent));
        close();
    }

    Component.onCompleted: listProc.running = true

    Keys.onEscapePressed: close()

    Process {
        id: listProc

        command: ["caelestia", "emoji"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const sp = line.indexOf(" ");
                    if (sp <= 0)
                        continue;
                    const label = line.slice(sp + 1);
                    out.push({
                        char: line.slice(0, sp),
                        label,
                        search: root.normalise(label)
                    });
                }
                root.all = out;
            }
        }
    }

    FileView {
        id: recentFile

        path: `${Paths.state}/emoji-recent.json`
        printErrors: false
        onLoaded: {
            try {
                root.recent = JSON.parse(text());
            } catch (e) {}
        }
    }

    // Backdrop, click to close
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("black", 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    HkCard {
        id: card

        property real enter

        anchors.centerIn: parent
        implicitWidth: 560
        implicitHeight: 480
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
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraLarge
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                HkTitle {
                    Layout.fillWidth: true
                    text: Tr.tr("Emoji")
                }

                SearchBar {
                    id: search

                    Layout.preferredWidth: 300
                    topPadding: Tokens.padding.medium
                    bottomPadding: Tokens.padding.medium
                    placeholderText: Tr.tr("Search emojis")
                    focus: true

                    onTextChanged: grid.currentIndex = 0
                    Keys.onEscapePressed: {
                        if (text)
                            text = "";
                        else
                            root.close();
                    }
                    Keys.onReturnPressed: root.pick(root.current)
                    Keys.onEnterPressed: root.pick(root.current)
                    Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                    Keys.onRightPressed: grid.moveCurrentIndexRight()
                    Keys.onUpPressed: grid.moveCurrentIndexUp()
                    Keys.onDownPressed: grid.moveCurrentIndexDown()
                }
            }

            HkDivider {
                Layout.fillWidth: true
            }

            GridView {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / 9)
                cellHeight: cellWidth
                model: root.results
                highlightMoveDuration: 0
                boundsBehavior: Flickable.StopAtBounds

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

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 6
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: cell.modelData.char
                        font.pointSize: 20
                        font.family: "Noto Color Emoji"
                        color: Hallownest.text
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

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    text: root.current?.char ?? ""
                    font.pointSize: 16
                    font.family: "Noto Color Emoji"
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.all.length === 0 ? Tr.tr("Loading…") : root.results.length === 0 ? Tr.tr("No emojis match") : root.current?.label ?? ""
                    color: Hallownest.subtext
                    font.pointSize: 9
                    elide: Text.ElideRight
                }

                StyledText {
                    text: Tr.tr("Enter to copy")
                    color: Hallownest.faint
                    font.pointSize: 8
                }
            }
        }
    }
}
