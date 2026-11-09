pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState

    // Disable all internal search bar and list view event listeners when closed
    property string filterText: ""
    property string activeCategory: "All"
    property var allEntries: []

    readonly property var categories: {
        const cats = ["All"];
        for (const e of allEntries) {
            if (!cats.includes(e.category))
                cats.push(e.category);
        }
        return cats;
    }

    readonly property var filteredEntries: {
        const q = filterText.trim().toLowerCase();

        // First filter by category
        const categoryEntries = allEntries.filter(e => activeCategory === "All" || e.category === activeCategory);

        // No search text: preserve normal category ordering
        if (!q)
            return categoryEntries;

        const results = [];

        for (const e of categoryEntries) {
            const keyScore = fuzzyScore(q, e.keyStr);
            const labelScore = fuzzyScore(q, e.label);
            const categoryScore = fuzzyScore(q, e.category);

            const score = Math.max(keyScore, labelScore, categoryScore);

            if (score >= 0) {
                results.push({
                    entry: e,
                    score: score
                });
            }
        }

        // Best matches first
        results.sort((a, b) => b.score - a.score);

        return results.map(r => r.entry);
    }

    function fuzzyScore(query, text) {
        if (!query)
            return 0;

        query = query.toLowerCase();
        text = text.toLowerCase();

        // Exact match
        if (text === query)
            return 1000;

        // Starts with query
        if (text.startsWith(query))
            return 800;

        // Consecutive substring
        const substringIndex = text.indexOf(query);
        if (substringIndex !== -1)
            return 600 - substringIndex;

        // Fuzzy character matching
        let queryIndex = 0;
        let score = 0;
        let consecutive = 0;

        for (let i = 0; i < text.length && queryIndex < query.length; i++) {
            if (text[i] === query[queryIndex]) {
                queryIndex++;

                consecutive++;
                score += 10 + consecutive * 5;
            } else {
                consecutive = 0;
            }
        }

        // Not all query characters were found
        if (queryIndex !== query.length)
            return -1;

        return score;
    }

    function highlightMatch(query, text) {
        if (!query || !text)
            return text;

        query = query.toLowerCase();
        const lowerText = text.toLowerCase();

        // Escape HTML characters so the text is safe for RichText
        const escaped = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

        // Find the query as a consecutive substring first
        const substringIndex = lowerText.indexOf(query);

        if (substringIndex !== -1) {
            const before = escaped.substring(0, substringIndex);
            const match = escaped.substring(substringIndex, substringIndex + query.length);
            const after = escaped.substring(substringIndex + query.length);

            return before + "<b>" + match + "</b>" + after;
        }

        // Otherwise highlight fuzzy-matched characters
        let queryIndex = 0;
        let result = "";

        for (let i = 0; i < text.length; i++) {
            if (queryIndex < query.length && lowerText[i] === query[queryIndex]) {
                const char = escaped[i];
                result += "<b>" + char + "</b>";
                queryIndex++;
            } else {
                result += escaped[i];
            }
        }

        return result;
    }

    function refreshBinds() {
        bindsProc.running = true;
    }

    // Fallback modmask decoder, only used if the "modkeys" field isn't
    // present on your Hyprland version (older builds may lack it)
    function decodeModmask(mask) {
        const bits = [[1, "Shift"], [4, "Ctrl"], [8, "Alt"], [64, "Super"]];
        return bits.filter(([bit]) => (mask & bit) !== 0).map(([, name]) => name).join(" + ");
    }

    enabled: Boolean(screenState.cheatsheet)
    implicitWidth: 1200
    implicitHeight: 900

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            screenState.cheatsheet = false;
            event.accepted = true;
        }
    }

    Component.onCompleted: {
        refreshBinds();
        Qt.callLater(() => search.forceActiveFocus());
    }

    // Re-query live every time the panel opens, so it can never go stale
    Connections {
        function onCheatsheetChanged() {
            if (root.screenState.cheatsheet) {
                root.refreshBinds();
                Qt.callLater(() => search.forceActiveFocus());
            }
        }

        target: root.screenState
    }

    Process {
        id: bindsProc

        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = JSON.parse(text);
                    root.allEntries = raw.filter(b => b.has_description && b.description && b.description.length > 0).map(b => {
                        // Convention: description = "Category: Label"
                        const parts = b.description.split(":");
                        const category = parts.length > 1 ? parts[0].trim() : "Other";
                        const label = parts.length > 1 ? parts.slice(1).join(":").trim() : b.description.trim();
                        const modStr = b.modkeys ? b.modkeys.trim().replace(/\s+/g, " + ") : root.decodeModmask(b.modmask);
                        const keyStr = modStr ? `${modStr} + ${b.key}` : b.key;
                        return {
                            keyStr,
                            label,
                            category
                        };
                    });
                } catch (e) {
                    console.log("Cheatsheet: failed to parse hyprctl binds -j —", e);
                }
            }
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer
        border.color: Colours.palette.m3outlineVariant
        border.width: 1
        radius: 16

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 16

            SearchBar {
                id: search

                Layout.fillWidth: true
                placeholderText: qsTr("Type to filter…")

                onTextChanged: root.filterText = text
            }

            Flow {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: root.categories

                    StyledRect {
                        id: pill

                        required property string modelData

                        color: root.activeCategory === modelData ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh
                        radius: 80
                        implicitWidth: pillText.implicitWidth + 16 * 2
                        implicitHeight: pillText.implicitHeight + 12 * 2

                        StateLayer {
                            radius: 80
                            color: pill.color === Colours.palette.m3primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                            onClicked: root.activeCategory = pill.modelData
                        }

                        StyledText {
                            id: pillText

                            anchors.centerIn: parent
                            text: pill.modelData
                            color: root.activeCategory === pill.modelData ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        }
                    }
                }
            }

            StyledText {
                text: `${root.filteredEntries.length}/${root.allEntries.length}`
                color: Colours.palette.m3onSurfaceVariant
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 12
                    model: root.filteredEntries

                    delegate: RowLayout {
                        id: delegateRoot

                        required property var modelData

                        width: ListView.view.width
                        spacing: 16

                        StyledText {
                            Layout.preferredWidth: 260
                            text: root.highlightMatch(root.filterText, delegateRoot.modelData.keyStr)
                            textFormat: Text.RichText
                            font.family: Tokens.font.mono.family
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.highlightMatch(root.filterText, delegateRoot.modelData.label)
                            textFormat: Text.RichText
                            color: Colours.palette.m3onSurface
                        }
                    }
                }

                StyledScrollBar {
                    Layout.fillHeight: true
                    flickable: list
                }
            }
        }
    }
}
