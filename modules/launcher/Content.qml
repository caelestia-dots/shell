pragma ComponentBehavior: Bound

import "services"
import "../../components" as Components
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property PersistentProperties visibilities
    required property var panels
    required property real maxHeight

    readonly property alias searchField: search
    readonly property int padding: Appearance.padding.large
    readonly property int rounding: Appearance.rounding.large

    property var showContextMenuAt: null
    property Item wrapperRoot: null

    property string activeCategory: "all"
    property bool showNavbar: (Config.launcher.enableCategories ?? true) && !search.text.startsWith(Config.launcher.actionPrefix)

    readonly property var categoryList: [
        {
            id: "all",
            name: qsTr("All"),
            icon: "apps"
        },
        {
            id: "favourites",
            name: qsTr("Favourites"),
            icon: "favorite"
        }
    ].concat(Config.launcher.categories.map(cat => ({
                id: cat.name.toLowerCase(),
                name: cat.name,
                icon: cat.icon
            })))

    function navigateCategory(direction: int): void {
        const currentIndex = categoryList.findIndex(cat => cat.id === activeCategory);
        if (currentIndex === -1)
            return;

        const newIndex = currentIndex + direction;
        if (newIndex >= 0 && newIndex < categoryList.length) {
            activeCategory = categoryList[newIndex].id;
            if (categoryNavbar) {
                categoryNavbar.scrollToActiveTab();
            }
        }
    }

    implicitWidth: list.width + padding * 2
    implicitHeight: searchWrapper.implicitHeight + list.implicitHeight + categoryNavbar.height + (showNavbar ? padding * 2 : 0) + padding * 2 + Appearance.spacing.normal

    Components.CategoryNavbar {
        id: categoryNavbar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.topMargin: root.padding

        categories: root.categoryList
        activeCategory: root.activeCategory
        showScrollButtons: true

        opacity: root.showNavbar ? 1 : 0
        height: root.showNavbar ? implicitHeight : 0

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        Behavior on height {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        onCategoryChanged: categoryId => {
            root.activeCategory = categoryId;
        }
    }

    ContentList {
        id: list

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: categoryNavbar.bottom
        anchors.bottom: searchWrapper.top
        anchors.topMargin: root.showNavbar ? root.padding : 0
        anchors.bottomMargin: root.padding

        content: root
        visibilities: root.visibilities
        panels: root.panels
        maxHeight: root.maxHeight - searchWrapper.implicitHeight - categoryNavbar.implicitHeight - (root.showNavbar ? root.padding * 2 : 0) - root.padding * 4
        search: search
        padding: root.padding
        rounding: root.rounding
        activeCategory: root.activeCategory
        showContextMenuAt: root.showContextMenuAt
        wrapperRoot: root.wrapperRoot
    }

    StyledRect {
        id: searchWrapper

        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Appearance.rounding.full

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding

        implicitHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearIcon.implicitHeight)

        MaterialIcon {
            id: searchIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.padding

            text: "search"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledTextField {
            id: search

            anchors.left: searchIcon.right
            anchors.right: clearIcon.left
            anchors.leftMargin: Appearance.spacing.small
            anchors.rightMargin: Appearance.spacing.small

            topPadding: Appearance.padding.larger
            bottomPadding: Appearance.padding.larger

            placeholderText: qsTr("Type \"%1\" for commands").arg(Config.launcher.actionPrefix)

            onTextChanged: {
                root.showNavbar = !text.startsWith(Config.launcher.actionPrefix);
            }

            onAccepted: {
                const currentItem = list.currentList?.currentItem;
                if (currentItem) {
                    if (list.showWallpapers) {
                        if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                            Wallpapers.previewColourLock = true;
                        Wallpapers.setWallpaper(currentItem.modelData.path);
                        root.visibilities.launcher = false;
                    } else if (text.startsWith(Config.launcher.actionPrefix)) {
                        if (text.startsWith(`${Config.launcher.actionPrefix}calc `))
                            currentItem.onClicked();
                        else
                            currentItem.modelData.onClicked(list.currentList);
                    } else {
                        Apps.launch(currentItem.modelData);
                        root.visibilities.launcher = false;
                    }
                }
            }

            Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
            Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

            Keys.onLeftPressed: event => {
                if (event.modifiers === Qt.NoModifier) {
                    root.navigateCategory(-1);
                    event.accepted = true;
                }
            }

            Keys.onRightPressed: event => {
                if (event.modifiers === Qt.NoModifier) {
                    root.navigateCategory(1);
                    event.accepted = true;
                }
            }

            Keys.onEscapePressed: root.visibilities.launcher = false

            Keys.onPressed: event => {
                if (!Config.launcher.vimKeybinds)
                    return;

                if (event.modifiers & Qt.ControlModifier) {
                    if (event.key === Qt.Key_J) {
                        list.currentList?.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K) {
                        list.currentList?.decrementCurrentIndex();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Tab) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()

            Connections {
                target: root.visibilities

                function onLauncherChanged(): void {
                    if (!root.visibilities.launcher)
                        search.text = "";
                }

                function onSessionChanged(): void {
                    if (!root.visibilities.session)
                        search.forceActiveFocus();
                }
            }
        }

        MaterialIcon {
            id: clearIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.padding

            width: search.text ? implicitWidth : implicitWidth / 2
            opacity: {
                if (!search.text)
                    return 0;
                if (mouse.pressed)
                    return 0.7;
                if (mouse.containsMouse)
                    return 0.8;
                return 1;
            }

            text: "close"
            color: Colours.palette.m3onSurfaceVariant

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: search.text ? Qt.PointingHandCursor : undefined

                onClicked: search.text = ""
            }

            Behavior on width {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }
        }
    }
}
