pragma ComponentBehavior: Bound

import "services"
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

    readonly property int padding: Appearance.padding.large
    readonly property int rounding: Appearance.rounding.large
    
    property string activeCategory: "all"
    property bool showNavbar: true
    
    readonly property var categoryList: [
        { id: "all", name: qsTr("All"), icon: "apps" },
        { id: "favorites", name: qsTr("Favorites"), icon: "favorite" }
    ].concat(Config.launcher.categories.map(cat => ({ id: cat.name.toLowerCase(), name: cat.name, icon: cat.icon })))
    
    function navigateCategory(direction: int): void {
        const currentIndex = categoryList.findIndex(cat => cat.id === activeCategory);
        if (currentIndex === -1) return;
        
        const newIndex = currentIndex + direction;
        if (newIndex >= 0 && newIndex < categoryList.length) {
            activeCategory = categoryList[newIndex].id;
            scrollToActiveTab();
        }
    }
    
    function scrollToActiveTab(): void {
        Qt.callLater(() => {
            if (!tabsFlickable || !tabsRow) return;
            
            const currentIndex = categoryList.findIndex(cat => cat.id === activeCategory);
            if (currentIndex === -1) return;
            
            // Calculate position of the active tab
            let tabX = 0;
            for (let i = 0; i < currentIndex && i < tabsRow.children.length; i++) {
                const child = tabsRow.children[i];
                if (child) {
                    tabX += child.width + tabsRow.spacing;
                }
            }
            
            const activeTab = tabsRow.children[currentIndex];
            if (!activeTab) return;
            
            const tabWidth = activeTab.width;
            const viewportStart = tabsFlickable.contentX;
            const viewportEnd = tabsFlickable.contentX + tabsFlickable.width;
            
            // Scroll if tab is not fully visible
            if (tabX < viewportStart) {
                tabsFlickable.contentX = tabX;
            } else if (tabX + tabWidth > viewportEnd) {
                tabsFlickable.contentX = Math.min(
                    tabsFlickable.contentWidth - tabsFlickable.width,
                    tabX + tabWidth - tabsFlickable.width
                );
            }
        });
    }

    implicitWidth: list.width + padding * 2
    implicitHeight: searchWrapper.implicitHeight + list.implicitHeight + (showNavbar ? tabsWrapper.implicitHeight + padding * 2 : 0) + padding * 2 + Appearance.spacing.normal

    StyledRect {
        id: tabsWrapper

        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Appearance.rounding.large

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.topMargin: root.padding

        visible: opacity > 0
        opacity: root.showNavbar ? 1 : 0
        implicitHeight: root.showNavbar ? tabsRow.height + Appearance.padding.small + Appearance.padding.normal : 0
        
        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
        
        Behavior on implicitHeight {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        RowLayout {
            id: tabsContent
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.normal
            anchors.topMargin: Appearance.padding.small
            anchors.bottomMargin: Appearance.padding.normal
            spacing: Appearance.spacing.smaller

            IconButton {
                icon: "chevron_left"
                visible: tabsFlickable.contentWidth > tabsFlickable.width
                type: IconButton.Tonal
                onClicked: {
                    tabsFlickable.contentX = Math.max(0, tabsFlickable.contentX - 100);
                }
            }

            StyledFlickable {
                id: tabsFlickable
                Layout.fillWidth: true
                Layout.preferredHeight: tabsRow.height
                flickableDirection: Flickable.HorizontalFlick
                contentWidth: tabsRow.width
                clip: true

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    
                    onWheel: wheel => {
                        const delta = wheel.angleDelta.y || wheel.angleDelta.x;
                        tabsFlickable.contentX = Math.max(0, Math.min(
                            tabsFlickable.contentWidth - tabsFlickable.width,
                            tabsFlickable.contentX - delta
                        ));
                        wheel.accepted = true;
                    }
                    
                    onPressed: mouse => {
                        mouse.accepted = false;
                    }
                }

                Row {
                    id: tabsRow
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: root.categoryList

                        delegate: StyledRect {
                            required property var modelData
                            
                            property bool isActive: root.activeCategory === modelData.id

                            implicitWidth: tabContent.width + Appearance.padding.normal * 2
                            implicitHeight: tabContent.height + Appearance.padding.smaller * 2

                            color: isActive ? Colours.palette.m3secondaryContainer : "transparent"
                            radius: Appearance.rounding.full

                            StateLayer {
                                radius: parent.radius
                                function onClicked(): void {
                                    root.activeCategory = modelData.id;
                                }
                            }

                            Row {
                                id: tabContent
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.smaller

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.pointSize: Appearance.font.size.small
                                    color: isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    font.pointSize: Appearance.font.size.small
                                    font.weight: isActive ? 500 : 400
                                    color: isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    }
                }
            }

            IconButton {
                icon: "chevron_right"
                visible: tabsFlickable.contentWidth > tabsFlickable.width
                type: IconButton.Tonal
                onClicked: {
                    tabsFlickable.contentX = Math.min(tabsFlickable.contentWidth - tabsFlickable.width, tabsFlickable.contentX + 100);
                }
            }
        }
    }

    ContentList {
        id: list

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: tabsWrapper.bottom
        anchors.bottom: searchWrapper.top
        anchors.topMargin: root.padding
        anchors.bottomMargin: root.padding

        content: root
        visibilities: root.visibilities
        panels: root.panels
        maxHeight: root.maxHeight - searchWrapper.implicitHeight - (root.showNavbar ? tabsWrapper.implicitHeight : 0) - root.padding * 4
        search: search
        padding: root.padding
        rounding: root.rounding
        activeCategory: root.activeCategory
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
