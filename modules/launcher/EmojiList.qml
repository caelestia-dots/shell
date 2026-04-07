pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "items"
import "services"
import qs.components.controls
import qs.services
import qs.config

Item {
    id: root

    required property StyledTextField search
    required property PersistentProperties visibilities

    property string activeCategory: "all"

    readonly property int columns: 5
    readonly property int cellSize: Math.floor((Config.launcher.sizes.itemWidth - Appearance.padding.normal * 2) / columns)
    readonly property alias currentItem: grid.currentItem
    readonly property alias count: grid.count
    property int currentIndex: 0

    function incrementCurrentIndex(): void {
        const newIndex = currentIndex + columns;
        if (newIndex < grid.count) {
            currentIndex = newIndex;
        } else if (currentIndex < grid.count - 1) {
            currentIndex = grid.count - 1;
        }
    }

    function decrementCurrentIndex(): void {
        const newIndex = currentIndex - columns;
        if (newIndex >= 0) {
            currentIndex = newIndex;
        } else if (currentIndex > 0) {
            currentIndex = 0;
        }
    }

    function moveLeft(): void {
        if (currentIndex > 0) {
            currentIndex = currentIndex - 1;
        }
    }

    function moveRight(): void {
        if (currentIndex < grid.count - 1) {
            currentIndex = currentIndex + 1;
        }
    }

    function updateGrid(): void {
        const pattern = new RegExp("^" + Config.launcher.actionPrefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + "emoji\\s*", "i");
        const query = root.search.text.replace(pattern, "").trim();
        let emojis = Emojis.emojis; // qmllint disable missing-property
        if (root.activeCategory !== "all") {
            emojis = emojis.filter(emoji => emoji.category === root.activeCategory);
        }
        if (query) {
            const lowerQuery = query.toLowerCase();
            emojis = emojis.filter(emoji => emoji.name.toLowerCase().includes(lowerQuery) || emoji.keywords.some(kw => kw.toLowerCase().includes(lowerQuery)));
        }
        grid.model = emojis;
        currentIndex = 0;
    }

    implicitWidth: Config.launcher.sizes.itemWidth
    implicitHeight: categoryBar.height + grid.height + Appearance.padding.large

    onCurrentIndexChanged: {
        if (grid.currentIndex !== currentIndex) {
            grid.currentIndex = currentIndex;
        }
    }

    Component.onCompleted: {
        updateGrid();
    }

    RowLayout {
        id: categoryBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.spacing.small

        Repeater {
            model: Emojis.categories // qmllint disable missing-property

            IconButton {
                required property var modelData
                required property int index

                icon: modelData.icon
                type: root.activeCategory === modelData.id ? IconButton.Filled : IconButton.Tonal
                onClicked: {
                    root.activeCategory = modelData.id;
                    root.updateGrid();
                }
            }
        }
    }

    GridView {
        id: grid

        anchors.top: categoryBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        anchors.topMargin: Appearance.padding.large

        height: Math.min(Math.max(contentHeight, root.cellSize * 3), 400)
        clip: true

        cellWidth: root.cellSize
        cellHeight: root.cellSize

        verticalLayoutDirection: GridView.TopToBottom

        highlight: Rectangle {
            color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
            radius: Appearance.rounding.normal
        }
        highlightFollowsCurrentItem: true

        model: ScriptModel {
            id: model

            onValuesChanged: {
                grid.currentIndex = 0;
                root.currentIndex = 0;
            }
        }

        delegate: emojiItem

        Keys.onLeftPressed: function (event) {
            if (currentIndex % root.columns === 0) {
                event.accepted = false;
            } else {
                root.moveLeft();
            }
        }

        Keys.onRightPressed: function (event) {
            if (currentIndex % root.columns === root.columns - 1) {
                event.accepted = false;
            } else {
                root.moveRight();
            }
        }

        Keys.onUpPressed: function (event) {
            if (currentIndex < root.columns) {
                event.accepted = false;
            } else {
                currentIndex -= root.columns;
            }
        }

        Keys.onDownPressed: function (event) {
            if (currentIndex >= count - root.columns) {
                event.accepted = false;
            } else {
                currentIndex += root.columns;
            }
        }

        Component {
            id: emojiItem

            EmojiItem {
                width: grid.cellWidth - Appearance.spacing.small
                height: grid.cellHeight - Appearance.spacing.small
                visibilities: root.visibilities
            }
        }
    }

    Connections {
        function onEmojisLoaded(): void {
            root.updateGrid();
        }

        target: Emojis // qmllint disable incompatible-type
    }

    Connections {
        function onTextChanged(): void {
            root.updateGrid();
        }

        target: root.search
    }
}
