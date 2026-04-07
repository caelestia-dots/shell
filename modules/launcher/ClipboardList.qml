pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "items"
import "services"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config

Item {
    id: root

    required property StyledTextField search
    required property PersistentProperties visibilities

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

    function incrementCurrentIndex(): void {
        listView.incrementCurrentIndex();
    }

    function decrementCurrentIndex(): void {
        listView.decrementCurrentIndex();
    }

    function filterAndSortItems(): var {
        const pattern = new RegExp("^" + Config.launcher.actionPrefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + "clipboard\\s*", "i");
        const query = root.search.text.replace(pattern, "").trim();
        let items = Clipboard.history; // qmllint disable missing-property

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

    implicitWidth: Config.launcher.sizes.itemWidth
    implicitHeight: toolbarBg.height + listView.implicitHeight + Appearance.spacing.small

    Component.onCompleted: {
        Clipboard.refresh(); // qmllint disable missing-property
        updateModel();
    }

    StyledRect {
        id: toolbarBg

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Appearance.rounding.normal
        implicitHeight: toolbar.implicitHeight + Appearance.padding.small * 2

        RowLayout {
            id: toolbar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            spacing: Appearance.spacing.small

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
                    radius: 10

                    x: activeTab ? activeTab.x : 0
                    y: activeTab ? activeTab.y : 0
                    width: activeTab ? activeTab.width : 0
                    height: activeTab ? activeTab.height : 0

                    Behavior on x {
                        Anim {
                            duration: Appearance.anim.durations.normal
                            easing.bezierCurve: Appearance.anim.curves.emphasized
                        }
                    }

                    Behavior on width {
                        Anim {
                            duration: Appearance.anim.durations.normal
                            easing.bezierCurve: Appearance.anim.curves.emphasized
                        }
                    }
                }

                Row {
                    id: tabsRow

                    spacing: Appearance.spacing.small

                    Repeater {
                        id: tabsRepeater

                        model: [
                            {
                                id: "all",
                                name: qsTr("All"),
                                icon: "apps"
                            },
                            {
                                id: "images",
                                name: qsTr("Images"),
                                icon: "image"
                            },
                            {
                                id: "misc",
                                name: qsTr("Misc"),
                                icon: "description"
                            }
                        ]

                        delegate: Item {
                            id: categoryTab

                            required property var modelData
                            required property int index

                            property bool isActive: root.activeCategory === modelData.id

                            implicitWidth: tabContent.width + Appearance.padding.normal * 2
                            implicitHeight: tabContent.height + Appearance.padding.smaller * 2

                            StateLayer {
                                function onClicked(): void {
                                    root.activeCategory = categoryTab.modelData.id;
                                }

                                anchors.fill: parent
                                radius: 6
                            }

                            Row {
                                id: tabContent

                                anchors.centerIn: parent
                                spacing: Appearance.spacing.smaller

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: categoryTab.modelData.icon
                                    font.pointSize: Appearance.font.size.small
                                    color: categoryTab.isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: categoryTab.modelData.name
                                    font.pointSize: Appearance.font.size.small
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
                    text: qsTr("%n item(s)", "", listView.count)
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: listView.count > 0 ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.small
                            easing.bezierCurve: Appearance.anim.curves.standard
                        }
                    }
                }
            }

            IconButton {
                icon: "delete_sweep"
                type: IconButton.Text
                radius: Appearance.rounding.small
                padding: Appearance.padding.small
                disabled: listView.count === 0
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

        spacing: Appearance.spacing.normal
        padding: Appearance.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: toolbarBg.bottom
        anchors.topMargin: (listView.implicitHeight - implicitHeight) / 2 + Appearance.spacing.small

        MaterialIcon {
            text: "content_paste"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.extraLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: qsTr("No clipboard history")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Copy something to populate clipboard history")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
            }
        }

        Behavior on opacity {
            Anim {}
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
        anchors.topMargin: Appearance.spacing.small

        spacing: Appearance.spacing.small
        orientation: Qt.Vertical

        implicitHeight: {
            if (count === 0)
                return (Config.launcher.sizes.itemHeight + spacing) * 1.2 - spacing;
            const itemsToShow = Math.min(Config.launcher.maxShown, count);
            return (Config.launcher.sizes.itemHeight + spacing) * itemsToShow - spacing;
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
            radius: Appearance.rounding.normal
            color: Colours.palette.m3onSurface
            opacity: 0.08

            y: listView.currentItem?.y ?? 0
            implicitWidth: listView.width
            implicitHeight: listView.currentItem?.implicitHeight ?? 0

            Behavior on y {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
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
                visibilities: root.visibilities
            }
        }
    }

    Connections {
        function onHistoryChanged(): void {
            root.updateModel();
        }

        target: Clipboard // qmllint disable incompatible-type
    }

    Connections {
        function onTextChanged(): void {
            root.updateModel();
        }

        target: root.search
    }

    Connections {
        function onActiveCategoryChanged(): void {
            if (root.previousCategory !== root.activeCategory && root.search.text.startsWith(Config.launcher.actionPrefix + "clipboard")) {
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
    }

    SequentialAnimation {
        id: categoryChangeAnimation

        ParallelAnimation {
            Anim {
                target: listView
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardAccel
            }
            Anim {
                target: listView
                property: "scale"
                to: 0.95
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
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
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                target: listView
                property: "scale"
                to: 1
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
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
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.showClearConfirmation = false
        }

        StyledRect {
            anchors.centerIn: parent
            width: Math.min(400, parent.width - Appearance.padding.large * 2)
            height: confirmContent.implicitHeight + Appearance.padding.large * 2
            color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.large

            opacity: root.showClearConfirmation ? 1 : 0
            scale: root.showClearConfirmation ? 1 : 0.8

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
                }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
                }
            }

            ColumnLayout {
                id: confirmContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (root.activeCategory === "all") {
                            return qsTr("Clear all clipboard items?");
                        } else if (root.activeCategory === "images") {
                            return qsTr("Clear image items?");
                        } else {
                            return qsTr("Clear misc items?");
                        }
                    }
                    font.pointSize: Appearance.font.size.larger
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Non-pinned items in this category will be deleted. Pinned items are preserved.")
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.normal
                    spacing: Appearance.spacing.normal

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Cancel")
                        type: TextButton.Text
                        onClicked: root.showClearConfirmation = false
                    }

                    TextButton {
                        text: qsTr("Clear All")
                        type: TextButton.Filled
                        onClicked: {
                            root.showClearConfirmation = false;
                            Clipboard.clearAll(root.activeCategory); // qmllint disable missing-property
                        }
                    }
                }
            }
        }
    }
}
