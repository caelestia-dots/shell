pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

// Two independent grids instead of one that gets its rows swapped:
// - browse: the categories. Built from the data only, so typing never touches it. Its scroll position, selection
// and layout stay valid while searching, and jumping to a category is always a plain scroll.
// - results: the search results. Rebuilt on every keystroke, always starts at the top.
// Only one is shown at a time (the other is faded out and disabled but kept laid out)
Item {
    id: root

    required property SearchBar search
    required property ScreenState screenState
    required property var source // PickerSource

    readonly property int columns: source.columns
    readonly property string prefix: `${GlobalConfig.launcher.actionPrefix}${source.mode} `
    readonly property string query: search.text.slice(prefix.length).trim()
    readonly property bool searching: query.length > 0

    // Every row (items and section headers) has the same height, so row positions are exact and can be animated to
    readonly property real cellWidth: Math.floor(browse.width / columns)
    readonly property real rowHeight: source.wide ? Tokens.sizes.launcher.itemHeight * 0.8 : cellWidth
    readonly property int recentShown: source.wide ? columns * 3 : columns

    // Snapshot so picking an item doesn't reshuffle the grid while the launcher is closing
    property var recent: []

    // rows: header/item-row entries shown in the list. flat: every item in display order.
    // rowOf: flat index -> row index. starts: group id -> row index of its first row (or header)
    readonly property var browseBuilt: {
        const sections = [];
        for (const g of source.groups) {
            const items = g.id === "recent" ? recent.map(c => source.byChar[c]).filter(e => e).slice(0, recentShown) : (source.byGroup[g.id] ?? []);
            sections.push({
                              id: g.id,
                              title: g.name,
                              items
                          });
        }
        return layout(sections, columns);
    }

    // Search results are a flat list with no sections
    readonly property var resultsBuilt: layout(searching ? [
                                                               {
                                                                   id: "results",
                                                                   title: "",
                                                                   items: source.search(query)
                                                               }
                                                           ] : [], columns)

    readonly property var currentGrid: searching ? results : browse
    readonly property int count: source.loaded ? currentGrid.built.flat.length : -1

    // The category shown in the tabs. Sticks to the last clicked tab until the user scrolls by hand
    readonly property string activeGroup: {
        const rows = browseBuilt.rows;
        if (searching || rows.length === 0)
            return "";

        if (browse.targetGroup)
            return browse.targetGroup;

        if (browse.atYEnd && browse.contentHeight > browse.height)
            return rows[rows.length - 1].group;

        const i = Math.floor((browse.contentY - browse.originY + 1) / rowHeight);
        return rows[Math.max(0, Math.min(rows.length - 1, i))].group;
    }

    function layout(sections: var, columns: int): var {
        const rows = [];
        const flat = [];
        const rowOf = [];
        const starts = {};

        for (const s of sections) {
            if (s.items.length === 0)
                continue;

            starts[s.id] = rows.length;
            if (s.title)
                rows.push({
                              kind: "header",
                              group: s.id,
                              title: s.title
                          });

            for (let i = 0; i < s.items.length; i += columns) {
                const row = {
                    kind: "row",
                    group: s.id,
                    start: flat.length,
                    items: s.items.slice(i, i + columns)
                };
                for (let j = 0; j < row.items.length; j++)
                    rowOf.push(rows.length);
                rows.push(row);
                flat.push(...row.items);
            }
        }

        return {
            rows,
            flat,
            rowOf,
            starts
        };
    }

    function move(direction: string): void {
        currentGrid.moveSelection(direction);
    }

    // Leaving the search is just revealing the browse grid again, which was never touched
    function jumpTo(id: string): void {
        if (searching)
            search.text = prefix;

        browse.goToCategory(id, true);
    }

    function switchCategory(direction: int): void {
        // Categories without any items (i.e. recent when empty) have no tab to land on
        const ids = source.groups.map(g => g.id).filter(id => browseBuilt.starts[id] !== undefined);
        if (ids.length === 0)
            return;

        const current = ids.indexOf(activeGroup);
        const next = current < 0 ? (direction > 0 ? 0 : ids.length - 1) : (current + direction + ids.length) % ids.length;
        jumpTo(ids[next]);
    }

    function activate(paste: bool): void {
        const item = currentGrid.built.flat[currentGrid.selected];
        if (!item)
            return;

        source.pick(item.c, paste);
        screenState.launcher = false;
    }

    implicitHeight: (Tokens.sizes.launcher.itemHeight + Tokens.spacing.small) * Config.launcher.maxShown - Tokens.spacing.small + hints.implicitHeight + Tokens.spacing.small

    Component.onCompleted: recent = source.recent
    onSourceChanged: recent = source.recent

    PickerTabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        groups: source.groups
        current: root.activeGroup
        onSelected: id => root.jumpTo(id)
    }

    PickerGrid {
        id: browse

        anchors.top: tabs.bottom
        anchors.topMargin: Tokens.spacing.small
        anchors.bottom: hints.top
        anchors.bottomMargin: Tokens.spacing.small
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small

        built: root.browseBuilt
        opacity: root.searching ? 0 : 1
        enabled: !root.searching
    }

    PickerGrid {
        id: results

        anchors.fill: browse

        built: root.resultsBuilt
        opacity: root.searching ? 1 : 0
        enabled: root.searching
    }

    Item {
        id: hints

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small

        implicitHeight: copyHint.implicitHeight

        // Previous category, in the left corner
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            spacing: Tokens.spacing.small

            ArrowButton {
                id: prevArrow

                icon: "chevron_left"
                onClicked: root.switchCategory(-1)
            }

            HintLabel {
                shown: prevArrow.hovered
                text: "⇧⇥"
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            spacing: Tokens.spacing.small

            HintButton {
                id: copyHint

                keys: "↵"
                label: Tr.tr("Copy")
                onClicked: root.activate(false)
            }

            HintButton {
                keys: "⌥↵"
                label: Tr.tr("Paste")
                onClicked: root.activate(true)
            }
        }

        // Next category, in the right corner
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: Tokens.spacing.small

            HintLabel {
                shown: nextArrow.hovered
                text: "⇥"
            }

            ArrowButton {
                id: nextArrow

                icon: "chevron_right"
                onClicked: root.switchCategory(1)
            }
        }
    }

    // A scrollable grid of picker rows with its own selection and category scrolling
    component PickerGrid: StyledListView {
        id: grid

        required property var built // { rows, flat, rowOf, starts }, see layout()

        property int selected // Index into built.flat
        property string targetGroup // Set by category jumps, cleared as soon as the user scrolls or moves the selection

        clip: true

        // Wheel/touch scrolling takes over from any category scroll animation. The fake flick that
        // StyledListView does after a rebound also reports as movement, so ignore that one
        onMovementStarted: {
            if (doneFakeFlick)
                return;

            scrollAnim.stop();
            targetGroup = "";
        }

        function resetView(): void {
            forceLayout();
            positionViewAtBeginning();
        }

        function scrollTo(row: int): void {
            scrollAnim.stop();
            scrollAnim.from = contentY;

            // Rows all have the same height, so the end is known exactly
            scrollAnim.to = originY + Math.max(0, Math.min(row * root.rowHeight, built.rows.length * root.rowHeight - height));
            scrollAnim.restart();
        }

        function goToCategory(id: string, animate: bool): void {
            const row = built.starts[id] ?? 0;
            const first = built.rows[row]?.kind === "header" ? built.rows[row + 1] : built.rows[row];

            selected = first?.start ?? 0;
            targetGroup = built.rows[row]?.group ?? id;

            if (animate) {
                scrollTo(row);
            } else {
                scrollAnim.stop();
                positionViewAtIndex(row, ListView.Beginning);
            }
        }

        function ensureVisible(row: int, up: bool): void {
            scrollAnim.stop();
            targetGroup = "";

            // Also reveal the section header when moving up into the first row of a section
            const header = built.rows[row - 1]?.kind === "header";
            positionViewAtIndex(up && header ? row - 1 : row, ListView.Contain);
        }

        function moveSelection(direction: string): void {
            const flat = built.flat;
            if (flat.length === 0)
                return;

            const rows = built.rows;
            const up = direction === "up" || direction === "left";
            const cur = Math.max(0, Math.min(flat.length - 1, selected));
            let target = cur;

            if (direction === "left") {
                target = Math.max(0, cur - 1);
            } else if (direction === "right") {
                target = Math.min(flat.length - 1, cur + 1);
            } else {
                const step = up ? -1 : 1;
                const col = cur - rows[built.rowOf[cur]].start;

                // Skip over section headers, keeping the same column (clamped for short rows)
                let r = built.rowOf[cur] + step;
                while (rows[r]?.kind === "header")
                    r += step;

                if (rows[r])
                    target = rows[r].start + Math.min(col, rows[r].items.length - 1);
            }

            selected = target;
            ensureVisible(built.rowOf[target], up);
        }

        model: ScriptModel {
            values: grid.built.rows
            onValuesChanged: {
                scrollAnim.stop();
                grid.selected = 0;
                grid.targetGroup = "";
                Qt.callLater(grid.resetView);
            }
        }

        delegate: Item {
            id: row

            required property var modelData

            readonly property bool isHeader: modelData.kind === "header"

            width: grid.width
            height: root.rowHeight

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.padding.medium
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.spacing.small

                visible: row.isHeader
                text: row.modelData.title ?? ""
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.large
            }

            Row {
                anchors.left: parent.left

                visible: !row.isHeader

                Repeater {
                    model: row.isHeader ? [] : row.modelData.items

                    PickerCell {
                        start: row.modelData.start
                        cellWidth: root.cellWidth
                        cellHeight: root.rowHeight
                        wide: root.source.wide
                        currentIndex: grid.selected

                        onActivated: {
                            grid.selected = flatIndex;
                            root.activate(false);
                        }
                    }
                }
            }
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: grid
        }

        Anim {
            id: scrollAnim

            target: grid
            property: "contentY"
            type: Anim.Standard
        }
    }

    // Only visible while hovering its arrow. Fades rather than hides so the layout doesn't shift
    component HintLabel: StyledText {
        property bool shown

        anchors.verticalCenter: parent.verticalCenter

        opacity: shown ? 1 : 0
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    component ArrowButton: StyledRect {
        id: arrow

        required property string icon
        readonly property alias hovered: layer.containsMouse

        signal clicked

        implicitWidth: copyHint.implicitHeight
        implicitHeight: copyHint.implicitHeight

        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        StateLayer {
            id: layer

            radius: arrow.radius
            onClicked: arrow.clicked()
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: arrow.icon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }
    }
}