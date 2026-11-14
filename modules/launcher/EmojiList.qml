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

Item {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    readonly property int columns: 12
    readonly property string prefix: `${GlobalConfig.launcher.actionPrefix}emoji `
    readonly property string query: search.text.slice(prefix.length).trim()

    // Every row (emojis and section headers) has the same height, so row positions are exact and can be animated to
    readonly property real cellSize: Math.floor(list.width / columns)

    // Snapshot so picking an emoji doesn't reshuffle the grid while the launcher is closing
    property var recent: []
    property int currentIndex
    property string targetGroup

    // rows: header/emoji-row entries shown in the list. flat: every emoji in display order.
    // rowOf: flat index -> row index. starts: group id -> row index of its first row (or header)
    readonly property var built: buildModel(Emojis.groups, Emojis.byGroup, Emojis.byChar, recent, query, columns)
    readonly property int count: Emojis.loaded ? built.flat.length : -1

    readonly property string activeGroup: {
        const rows = built.rows;
        if (query || rows.length === 0)
            return "";

        if (scrollAnim.running)
            return targetGroup;

        if (list.atYEnd && list.contentHeight > list.height)
            return rows[rows.length - 1].group;

        return rows[list.indexAt(0, list.contentY + 1)]?.group ?? "";
    }

    function buildModel(groups: var, byGroup: var, byChar: var, recent: var, query: string, columns: int): var {
        const rows = [];
        const flat = [];
        const rowOf = [];
        const starts = {};

        const add = (id, title, items) => {
            if (items.length === 0)
                return;

            starts[id] = rows.length;
            if (title)
                rows.push({
                    kind: "header",
                    group: id,
                    title
                });

            for (let i = 0; i < items.length; i += columns) {
                const row = {
                    kind: "row",
                    group: id,
                    start: flat.length,
                    items: items.slice(i, i + columns)
                };
                for (let j = 0; j < row.items.length; j++)
                    rowOf.push(rows.length);
                rows.push(row);
                flat.push(...row.items);
            }
        };

        if (query) {
            // Search results are a flat list with no sections
            add("results", "", Emojis.search(query));
        } else {
            for (const g of groups) {
                if (g.id === "recent")
                    add(g.id, g.name, recent.map(c => byChar[c]).filter(e => e).slice(0, columns));
                else
                    add(g.id, g.name, byGroup[g.id] ?? []);
            }
        }

        return {
            rows,
            flat,
            rowOf,
            starts
        };
    }

    function scrollTo(row: int): void {
        scrollAnim.stop();
        scrollAnim.from = list.contentY;
        scrollAnim.to = Math.max(0, Math.min(row * cellSize, list.contentHeight - list.height));
        scrollAnim.restart();
    }

    function ensureVisible(row: int, up: bool): void {
        scrollAnim.stop();

        // Also reveal the section header when moving up into the first row of a section
        const header = built.rows[row - 1]?.kind === "header";
        list.positionViewAtIndex(up && header ? row - 1 : row, ListView.Contain);
    }

    function move(direction: string): void {
        const flat = built.flat;
        if (flat.length === 0)
            return;

        const rows = built.rows;
        const up = direction === "up" || direction === "left";
        let target = currentIndex;

        if (direction === "left") {
            target = Math.max(0, currentIndex - 1);
        } else if (direction === "right") {
            target = Math.min(flat.length - 1, currentIndex + 1);
        } else {
            const step = up ? -1 : 1;
            const col = currentIndex - rows[built.rowOf[currentIndex]].start;

            // Skip over section headers, keeping the same column (clamped for short rows)
            let r = built.rowOf[currentIndex] + step;
            while (rows[r]?.kind === "header")
                r += step;

            if (rows[r])
                target = rows[r].start + Math.min(col, rows[r].items.length - 1);
        }

        currentIndex = target;
        ensureVisible(built.rowOf[target], up);
    }

    function jumpTo(id: string): void {
        if (query) {
            // Leave search to go back to browsing categories
            search.text = prefix;
            Qt.callLater(() => jumpTo(id));
            return;
        }

        const row = built.starts[id] ?? 0;
        const first = built.rows[row]?.kind === "header" ? built.rows[row + 1] : built.rows[row];

        currentIndex = first?.start ?? 0;
        targetGroup = built.rows[row]?.group ?? id;
        scrollTo(row);
    }

    function switchCategory(direction: int): void {
        // Categories without any emojis (i.e. recent when empty) have no tab to land on
        const ids = Emojis.groups.map(g => g.id).filter(id => id !== "recent" || recent.some(c => Emojis.byChar[c]));
        if (ids.length === 0)
            return;

        const current = ids.indexOf(activeGroup);
        const next = current < 0 ? (direction > 0 ? 0 : ids.length - 1) : (current + direction + ids.length) % ids.length;
        jumpTo(ids[next]);
    }

    function activate(paste: bool): void {
        const emoji = built.flat[currentIndex];
        if (!emoji)
            return;

        Emojis.pick(emoji.c, paste);
        screenState.launcher = false;
    }

    implicitHeight: (Tokens.sizes.launcher.itemHeight + Tokens.spacing.small) * Config.launcher.maxShown - Tokens.spacing.small + hints.implicitHeight + Tokens.spacing.small

    Component.onCompleted: recent = Emojis.recent

    EmojiTabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        groups: Emojis.groups
        current: root.activeGroup
        onSelected: id => root.jumpTo(id)
    }

    StyledListView {
        id: list

        anchors.top: tabs.bottom
        anchors.topMargin: Tokens.spacing.small
        anchors.bottom: hints.top
        anchors.bottomMargin: Tokens.spacing.small
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small

        clip: true

        // Wheel/touch scrolling takes over from any category scroll animation
        onMovementStarted: scrollAnim.stop()

        model: ScriptModel {
            values: root.built.rows
            onValuesChanged: {
                scrollAnim.stop();
                root.currentIndex = 0;
                Qt.callLater(() => list.positionViewAtBeginning());
            }
        }

        delegate: Item {
            id: row

            required property var modelData

            readonly property bool isHeader: modelData.kind === "header"

            width: list.width
            height: root.cellSize

            StyledText {
                id: headerLabel

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

                    EmojiCell {
                        start: row.modelData.start
                        size: root.cellSize
                        currentIndex: root.currentIndex

                        onActivated: {
                            root.currentIndex = flatIndex;
                            root.activate(false);
                        }
                    }
                }
            }
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: list
        }
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

    Anim {
        id: scrollAnim

        target: list
        property: "contentY"
        type: Anim.Standard
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
