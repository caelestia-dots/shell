pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

// Ported from Caelestia PR #1298's ClipboardList.qml: category tabs over the
// history rows, an item counter, a clear-all with a confirm dialog, and
// keep-the-cursor delete handling. Launcher closing goes through ScreenState.
Item {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    property string activeCategory: "all"
    property bool showClearConfirmation: false
    property alias hoveredItem: listView.hoveredItem
    property alias lastInteraction: listView.lastInteraction

    readonly property alias currentItem: listView.currentItem
    readonly property alias currentIndex: listView.currentIndex
    readonly property alias count: listView.count

    property bool isCategoryChange: false
    property alias deletedItemIndex: listView.deletedItemIndex
    property string previousCategory: "all"
    property var pendingModelUpdate: null

    readonly property var tabs: [
        {
            id: "all",
            name: Tr.tr("All"),
            icon: "apps"
        },
        {
            id: "images",
            name: Tr.tr("Images"),
            icon: "image"
        },
        {
            id: "misc",
            name: Tr.tr("Misc"),
            icon: "description"
        }
    ]

    function incrementCurrentIndex(): void {
        listView.incrementCurrentIndex();
    }

    function decrementCurrentIndex(): void {
        listView.decrementCurrentIndex();
    }

    // Tab / Shift+Tab move through the category bar.
    function cycleTab(delta: int): void {
        const i = root.tabs.findIndex(t => t.id === root.activeCategory);
        root.activeCategory = root.tabs[(i + delta + root.tabs.length) % root.tabs.length].id;
    }

    function filterAndSortItems(): var {
        const pattern = new RegExp("^" + GlobalConfig.launcher.actionPrefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + "clipboard\\s*", "i");
        const query = root.search.text.replace(pattern, "").trim();
        let items = Clipboard.history;

        if (root.activeCategory === "images") {
            items = items.filter(item => item.isImage);
        } else if (root.activeCategory === "misc") {
            items = items.filter(item => !item.isImage);
        }

        if (query) {
            const lowerQuery = query.toLowerCase();
            items = items.filter(item => item.content.toLowerCase().includes(lowerQuery));
        }

        items.sort((a, b) => {
            if (a.isPinned && !b.isPinned)
                return -1;
            if (!a.isPinned && b.isPinned)
                return 1;
            return a.index - b.index;
        });

        return items;
    }

    function updateModel(): void {
        model.values = root.filterAndSortItems();
    }

    implicitWidth: Tokens.sizes.launcher.itemWidth
    implicitHeight: toolbarBg.height + listView.implicitHeight + Tokens.spacing.small

    Component.onCompleted: {
        Clipboard.refresh();
        updateModel();
    }

    StyledRect {
        id: toolbarBg

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.medium
        implicitHeight: toolbar.implicitHeight + Tokens.padding.small * 2

        RowLayout {
            id: toolbar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: tabsRow.height

                StyledRect {
                    id: activeIndicator

                    property Item activeTab: {
                        for (let i = 0; i < tabsRepeater.count; i++) {
                            const tab = tabsRepeater.itemAt(i);
                            if (tab && tab.isActive) { // qmllint disable missing-property
                                return tab;
                            }
                        }
                        return null;
                    }

                    visible: activeTab !== null
                    color: Colours.palette.m3primary
                    radius: Tokens.rounding.small

                    x: activeTab ? activeTab.x : 0
                    y: activeTab ? activeTab.y : 0
                    width: activeTab ? activeTab.width : 0
                    height: activeTab ? activeTab.height : 0

                    Behavior on x {
                        Anim {
                            type: Anim.Standard
                        }
                    }

                    Behavior on width {
                        Anim {
                            type: Anim.Standard
                        }
                    }
                }

                Row {
                    id: tabsRow

                    spacing: Tokens.spacing.small

                    Repeater {
                        id: tabsRepeater

                        model: root.tabs

                        delegate: Item {
                            id: categoryTab

                            required property var modelData
                            required property int index

                            property bool isActive: root.activeCategory === modelData.id

                            implicitWidth: tabContent.width + Tokens.padding.medium * 2
                            implicitHeight: tabContent.height + Tokens.padding.extraSmall * 2

                            StateLayer {
                                anchors.fill: parent
                                radius: Tokens.rounding.small

                                onClicked: {
                                    root.activeCategory = categoryTab.modelData.id;
                                }
                            }

                            Row {
                                id: tabContent

                                anchors.centerIn: parent
                                spacing: Tokens.spacing.extraSmall

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: categoryTab.modelData.icon
                                    fontStyle: Tokens.font.icon.small
                                    color: categoryTab.isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: categoryTab.modelData.name
                                    font: Tokens.font.body.small
                                    color: categoryTab.isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.preferredWidth: countText.implicitWidth
                Layout.preferredHeight: countText.implicitHeight

                StyledText {
                    id: countText

                    anchors.centerIn: parent
                    text: Tr.trN("%n item", "%n items", listView.count)
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: listView.count > 0 ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.StandardSmall
                        }
                    }
                }
            }

            IconButton {
                icon: "delete_sweep"
                type: IconButton.Text
                radius: Tokens.rounding.small
                padding: Tokens.padding.small
                enabled: listView.count > 0
                onClicked: {
                    if (listView.count > 0) {
                        root.showClearConfirmation = true;
                    }
                }
            }
        }
    }

    Row {
        id: emptyState

        opacity: listView.count === 0 ? 1 : 0
        scale: listView.count === 0 ? 1 : 0.5
        visible: opacity > 0

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: toolbarBg.bottom
        anchors.topMargin: (listView.implicitHeight - implicitHeight) / 2 + Tokens.spacing.small

        MaterialIcon {
            text: "content_paste"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: Tr.tr("No clipboard history")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: Tr.tr("Copy something to populate clipboard history")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    StyledListView {
        id: listView

        property var hoveredItem: null
        property string lastInteraction: "keyboard"
        property int deletedItemIndex: -1

        anchors.top: toolbarBg.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.small

        spacing: Tokens.spacing.small
        orientation: Qt.Vertical

        implicitHeight: {
            if (count === 0)
                return (Tokens.sizes.launcher.itemHeight + spacing) * 1.2 - spacing;
            const itemsToShow = Math.min(GlobalConfig.launcher.maxShown, count);
            return (Tokens.sizes.launcher.itemHeight + spacing) * itemsToShow - spacing;
        }

        preferredHighlightBegin: 0
        preferredHighlightEnd: height
        highlightRangeMode: ListView.ApplyRange

        onCurrentIndexChanged: {
            if (lastInteraction !== "hover") {
                lastInteraction = "keyboard";
            }
        }

        onContentYChanged: {
            hoveredItem = null;
        }

        highlightFollowsCurrentItem: false

        delegate: clipboardItem

        model: ScriptModel {
            id: model

            onValuesChanged: {
                if (listView.deletedItemIndex >= 0) {
                    if (listView.deletedItemIndex <= listView.currentIndex) {
                        listView.currentIndex = Math.max(0, listView.currentIndex - 1);
                    }
                    listView.deletedItemIndex = -1;
                }
            }
        }

        highlight: StyledRect {
            radius: Tokens.rounding.medium
            color: Colours.palette.m3onSurface
            opacity: 0.08

            y: listView.currentItem?.y ?? 0
            implicitWidth: listView.width
            implicitHeight: listView.currentItem?.implicitHeight ?? 0

            Behavior on y {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }

        HoverHandler {
            id: listHoverHandler

            onHoveredChanged: {
                if (!hovered) {
                    listView.hoveredItem = null;
                }
            }
        }

        Component {
            id: clipboardItem

            ClipboardItem {
                screenState: root.screenState
            }
        }
    }

    Connections {
        function onHistoryChanged(): void {
            root.updateModel();
        }

        target: Clipboard
    }

    Connections {
        function onTextChanged(): void {
            root.updateModel();
        }

        target: root.search
    }

    Connections {
        function onActiveCategoryChanged(): void {
            if (root.previousCategory !== root.activeCategory && root.search.text.startsWith(GlobalConfig.launcher.actionPrefix + "clipboard")) {
                if (categoryChangeAnimation.running) {
                    categoryChangeAnimation.stop();
                    listView.opacity = 1;
                    listView.scale = 1;
                }

                root.pendingModelUpdate = root.filterAndSortItems();
                root.isCategoryChange = true;
                categoryChangeAnimation.start();
            }
            root.previousCategory = root.activeCategory;
        }

        // ComponentBehavior: Bound disables the implicit target; without this
        // the category change never reaches the filter.
        target: root
    }

    SequentialAnimation {
        id: categoryChangeAnimation

        ParallelAnimation {
            Anim {
                target: listView
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }

            Anim {
                target: listView
                property: "scale"
                to: 0.95
                type: Anim.EmphasizedSmall
            }
        }

        ScriptAction {
            script: {
                if (root.pendingModelUpdate !== null) {
                    model.values = root.pendingModelUpdate;
                    root.pendingModelUpdate = null;
                    if (root.isCategoryChange) {
                        listView.currentIndex = 0;
                        listView.positionViewAtBeginning();
                        root.isCategoryChange = false;
                    }
                }
            }
        }

        ParallelAnimation {
            Anim {
                target: listView
                property: "opacity"
                to: 1
                type: Anim.StandardSmall
            }

            Anim {
                target: listView
                property: "scale"
                to: 1
                type: Anim.EmphasizedSmall
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.5)
        visible: root.showClearConfirmation
        z: 1000

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.showClearConfirmation = false
        }

        StyledRect {
            anchors.centerIn: parent
            width: Math.min(400, parent.width - Tokens.padding.large * 2)
            height: confirmContent.implicitHeight + Tokens.padding.large * 2
            color: Colours.palette.m3surfaceContainer
            radius: Tokens.rounding.large

            opacity: root.showClearConfirmation ? 1 : 0
            scale: root.showClearConfirmation ? 1 : 0.8

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }

            ColumnLayout {
                id: confirmContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true

                    text: {
                        if (root.activeCategory === "all") {
                            return Tr.tr("Clear all clipboard items?");
                        } else if (root.activeCategory === "images") {
                            return Tr.tr("Clear image items?");
                        } else {
                            return Tr.tr("Clear misc items?");
                        }
                    }
                    font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    Layout.fillWidth: true

                    text: Tr.tr("Non-pinned items in this category will be deleted. Pinned items are preserved.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.medium
                    spacing: Tokens.spacing.medium

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: Tr.tr("Cancel")
                        type: TextButton.Text
                        onClicked: root.showClearConfirmation = false
                    }

                    TextButton {
                        text: Tr.tr("Clear All")
                        type: TextButton.Filled
                        onClicked: {
                            root.showClearConfirmation = false;
                            Clipboard.clearAll(root.activeCategory);
                        }
                    }
                }
            }
        }
    }
}
