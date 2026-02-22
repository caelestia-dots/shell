import "../../services"
import "../../../../services" as Services
import "." as ContextMenus
import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property DesktopEntry app: null
    property PersistentProperties visibilities
    property var windowRef: null
    property bool showAbove: false
    readonly property alias gooBounds: gooBounds
    property int activeSubmenuIndex: -1
    property int targetSubmenuIndex: -1
    property real submenuProgress: 0
    property int hoveredSubmenuIndex: -1
    property bool transitionContentVisible: false
    property real contentOpacity: {
        if (targetSubmenuIndex >= 0) {
            return transitionContentVisible ? 1 : 0;
        }
        if (activeSubmenuIndex >= 0) {
            return submenuProgress;
        }
        return 0;
    }
    property real submenuItemY: 0
    property int displayedSubmenuIndex: -1
    property real targetWidth: 0
    property real targetHeight: 0
    property real previousTargetWidth: 0
    property real previousTargetHeight: 0
    property real previousTopY: 0
    property real gooOverlapPx: 28
    readonly property real gooMarginPx: 30
    readonly property real bottomPadding: 16
    property string currentPage: "main"

    onVisibleChanged: {
        if (!visible)
            currentPage = "main";
        else if (app)
            buildSubmenuMap();
    }

    function navigateToPage(page) {
        if (currentPage === page)
            return;
        menuColumn.opacity = 0;
        pageTransitionTimer.page = page;
        pageTransitionTimer.restart();
    }

    Timer {
        id: pageTransitionTimer
        interval: 75
        property string page: "main"

        onTriggered: {
            currentPage = page;
            Qt.callLater(() => {
                menuColumn.opacity = 1;
            });
        }
    }

    readonly property var menuConfigMain: (Config.launcher.contextMenuMain && Config.launcher.contextMenuMain.length > 0) ? Config.launcher.contextMenuMain : [
        {
            "launch": {
                "text": "Launch",
                "icon": "play_arrow",
                "bold": true
            }
        },
        "separator", "favorites", "categories", "hide", "workspaces"]

    readonly property var menuConfigAdvanced: (Config.launcher.contextMenuAdvanced && Config.launcher.contextMenuAdvanced.length > 0) ? Config.launcher.contextMenuAdvanced : ["terminal",
        {
            "desktop-file": {
                "text": "edit .desktop File",
                "icon": "code"
            }
        },
        "open-path", "separator",
        {
            "custom-submenu": {
                "text": "Advanced Options",
                "icon": "settings"
            }
        },
        {
            "kill": {
                "parent": "custom-submenu"
            }
        },
        {
            "separator": {
                "parent": "custom-submenu"
            }
        },
        {
            "copy-exec": {
                "parent": "custom-submenu"
            }
        }
    ]

    readonly property var menuConfig: ({
            "main": menuConfigMain,
            "advanced": menuConfigAdvanced
        })
    readonly property bool hasAdvancedItems: menuConfig.advanced && menuConfig.advanced.length > 0

    property var menuContext: ({
            visibilities: root.visibilities,
            toggle: root.toggle,
            launchApp: root.launchApp,
            navigateToPage: root.navigateToPage
        })

    ContextMenus.MenuItemFactory {
        id: menuFactory
        app: root.app
        visibilities: root.visibilities
        launchApp: root.launchApp
        toggle: root.toggle
        menuContext: root.menuContext
    }

    readonly property var processedMainItems: menuFactory.processMenuItems(menuConfig.main || [])
    readonly property var processedAdvancedItems: menuFactory.processMenuItems(menuConfig.advanced || [])
    readonly property var currentPageItems: currentPage === "main" ? processedMainItems : processedAdvancedItems

    property var submenuMap: ({})
    property int nextSubmenuIndex: 0
    property int submenuMapVersion: 0

    function updateSubmenuDimensions() {
        targetWidth = submenuColumn.implicitWidth + Appearance.padding.smaller * 2;
        targetHeight = submenuColumn.implicitHeight + Appearance.padding.smaller * 2;
    }

    function buildSubmenuMap() {
        submenuMap = {};
        nextSubmenuIndex = 0;

        const allItems = [...processedMainItems, ...processedAdvancedItems];
        allItems.forEach(item => {
            const isSubmenu = menuFactory.shouldShowAsSubmenu(item.id, item.config, processedMainItems) || menuFactory.shouldShowAsSubmenu(item.id, item.config, processedAdvancedItems);
            if (isSubmenu) {
                submenuMap[item.id] = nextSubmenuIndex++;
            }
        });
        submenuMapVersion++;
    }

    function getSubmenuIndex(itemId) {
        submenuMapVersion;
        return submenuMap[itemId] ?? -1;
    }

    Component.onCompleted: buildSubmenuMap()
    onProcessedMainItemsChanged: buildSubmenuMap()
    onProcessedAdvancedItemsChanged: buildSubmenuMap()
    onAppChanged: buildSubmenuMap()

    function getSubmenuItemsForIndex(index) {
        const allItems = [...processedMainItems, ...processedAdvancedItems];
        for (const [itemId, submenuIdx] of Object.entries(submenuMap)) {
            if (submenuIdx === index) {
                const item = allItems.find(i => i.id === itemId);
                return item ? item.children : [];
            }
        }
        return [];
    }

    function getSubmenuParentId(index) {
        for (const [itemId, submenuIdx] of Object.entries(submenuMap)) {
            if (submenuIdx === index) {
                return itemId;
            }
        }
        return "";
    }

    Timer {
        id: contentSwitchTimer
        interval: Appearance.anim.durations.small
        onTriggered: {
            if (targetSubmenuIndex >= 0) {
                activeSubmenuIndex = displayedSubmenuIndex = targetSubmenuIndex;
                targetSubmenuIndex = -1;
            }
            transitionContentVisible = true;
            if (activeSubmenuIndex >= 0)
                Qt.callLater(updateSubmenuDimensions);
        }
    }

    onHoveredSubmenuIndexChanged: {
        if (hoveredSubmenuIndex < 0)
            return;
        if (activeSubmenuIndex < 0) {
            activeSubmenuIndex = displayedSubmenuIndex = hoveredSubmenuIndex;
            targetSubmenuIndex = -1;
            Qt.callLater(updateSubmenuDimensions);
        } else if (activeSubmenuIndex !== hoveredSubmenuIndex) {
            previousTargetWidth = targetWidth;
            previousTargetHeight = targetHeight;
            previousTopY = submenuContainer.interpolatedTopY;
            targetSubmenuIndex = hoveredSubmenuIndex;
            transitionContentVisible = false;
            contentSwitchTimer.restart();
        }
    }

    onActiveSubmenuIndexChanged: {
        if (activeSubmenuIndex < 0) {
            targetSubmenuIndex = displayedSubmenuIndex = -1;
            targetWidth = targetHeight = previousTargetWidth = previousTargetHeight = previousTopY = 0;
        } else if (displayedSubmenuIndex < 0) {
            displayedSubmenuIndex = activeSubmenuIndex;
            Qt.callLater(updateSubmenuDimensions);
        }
    }

    Connections {
        target: submenuColumn
        function onImplicitWidthChanged() {
            if (displayedSubmenuIndex >= 0)
                updateSubmenuDimensions();
        }
        function onImplicitHeightChanged() {
            if (displayedSubmenuIndex >= 0)
                updateSubmenuDimensions();
        }
    }

    visible: false
    property bool menuOpen: false

    function launchApp(workspace) {
        if (!root.app)
            return;
        if (workspace)
            Services.Hypr.dispatch(`workspace ${workspace}`);
        Apps.launch(root.app);
        root.visibilities.launcher = false;
        toggle();
    }

    function toggle() {
        if (!root.app)
            return;

        menuOpen = !root.visible;
        if (menuOpen) {
            activeSubmenuIndex = -1;
            submenuProgress = 0;
            root.visible = true;
        }
    }

    HyprlandFocusGrab {
        active: root.visible && root.windowRef !== null
        windows: root.windowRef ? [root.windowRef] : []

        onCleared: {
            if (root.visible) {
                toggle();
            }
        }
    }

    Behavior on submenuProgress {
        NumberAnimation {
            duration: Appearance.anim.durations.normal / 1.2
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on contentOpacity {
        enabled: targetSubmenuIndex >= 0
        Anim {
            duration: Appearance.anim.durations.normal / 1.2
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Timer {
        id: submenuCloseTimer
        interval: 150
        onTriggered: {
            if (hoveredSubmenuIndex < 0 && targetSubmenuIndex < 0 && !submenuHover.hovered) {
                submenuProgress = 0;
                Qt.callLater(() => {
                    if (submenuProgress === 0)
                        activeSubmenuIndex = -1;
                });
            }
        }
    }

    Item {
        id: menuWrapper
        width: menuContainer.width
        height: menuContainer.height

        opacity: menuOpen ? 1 : 0
        scale: menuOpen ? 1 : 0.85
        transformOrigin: Item.TopLeft

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.anim.durations.fast || 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.fast || 150
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        onOpacityChanged: {
            if (opacity === 0 && !menuOpen && root.visible) {
                root.visible = false;
                root.app = null;
                activeSubmenuIndex = -1;
                submenuProgress = 0;
            }
        }

        Item {
            id: gooBounds

            readonly property real menuLeft: menuContainer.x
            readonly property real menuTop: menuContainer.y
            readonly property real menuRight: menuContainer.x + menuContainer.width
            readonly property real menuBottom: menuContainer.y + menuContainer.height

            readonly property bool hasSub: submenuContainer.visible
            readonly property real subLeft: submenuContainer.x - root.gooOverlapPx
            readonly property real subTop: submenuContainer.y
            readonly property real subRight: submenuContainer.x + submenuContainer.width
            readonly property real subBottom: submenuContainer.y + submenuContainer.height

            readonly property real gooLeft: (hasSub ? Math.min(menuLeft, subLeft) : menuLeft) - root.gooMarginPx
            readonly property real gooTop: (hasSub ? Math.min(menuTop, subTop) : menuTop) - root.gooMarginPx
            readonly property real gooRight: (hasSub ? Math.max(menuRight, subRight) : menuRight) + root.gooMarginPx
            readonly property real gooBottom: (hasSub ? Math.max(menuBottom, subBottom) : menuBottom) + root.gooMarginPx

            x: gooLeft
            y: gooTop
            width: Math.max(1, gooRight - gooLeft)
            height: Math.max(1, gooBottom - gooTop)
        }

        ShaderEffect {
            id: gooEffect
            x: gooBounds.x
            y: gooBounds.y
            width: gooBounds.width
            height: gooBounds.height
            z: -2
            visible: root.visible

            property vector2d sizePx: Qt.vector2d(width, height)

            property vector4d menuRectPx: Qt.vector4d(menuContainer.x - gooBounds.x, menuContainer.y - gooBounds.y, menuContainer.width, menuContainer.height)

            property vector4d subRectPx: submenuContainer.visible ? Qt.vector4d((submenuContainer.x - gooBounds.x) - 24, submenuContainer.y - gooBounds.y, submenuContainer.width + 24, submenuContainer.height) : Qt.vector4d(0, 0, 0, 0)

            property real radiusPx: Appearance.rounding.normal * 0.75

            readonly property real topEdgeDiff: submenuContainer.visible ? Math.abs(menuContainer.y - submenuContainer.y) : 999
            readonly property real bottomEdgeDiff: submenuContainer.visible ? Math.abs((menuContainer.y + menuContainer.height) - (submenuContainer.y + submenuContainer.height)) : 999
            readonly property bool isTopAligned: submenuContainer.visible && topEdgeDiff < 3
            readonly property bool isBottomAligned: submenuContainer.visible && bottomEdgeDiff < 3

            property real smoothPxTop: isTopAligned ? 0 : 12
            property real smoothPxBottom: isBottomAligned ? 0 : 12

            property color fillColor: Colours.palette.m3surfaceContainer
            property color shadowColor: Qt.rgba(0, 0, 0, 0.20)
            property vector2d shadowOffsetPx: Qt.vector2d(0, 0)
            property real shadowSoftPx: 6

            vertexShader: Qt.resolvedUrl("shaders/goo_sdf.vert.qsb")
            fragmentShader: Qt.resolvedUrl("shaders/goo_sdf.frag.qsb")
        }

        Item {
            id: menuContainer
            width: menuColumn.implicitWidth + Appearance.padding.smaller * 2
            height: menuColumn.implicitHeight + Appearance.padding.smaller * 2

            Behavior on width {
                NumberAnimation {
                    duration: Appearance.anim.durations.normal / 2
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Appearance.anim.durations.normal / 2
                    easing.type: Easing.InOutQuad
                }
            }

            ColumnLayout {
                id: menuColumn
                anchors.fill: parent
                anchors.margins: Appearance.padding.smaller
                spacing: Appearance.spacing.smaller
                clip: true
                opacity: 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: (Appearance.anim.durations.fast || 150) / 2
                        easing.type: Easing.InOutQuad
                    }
                }

                // Back button for advanced page
                MenuItem {
                    visible: currentPage === "advanced"
                    text: qsTr("Back")
                    icon: "arrow_back"
                    onTriggered: navigateToPage("main")
                }

                MenuItem {
                    isSeparator: true
                    visible: currentPage === "advanced"
                }

                Repeater {
                    model: currentPageItems

                    MenuItem {
                        required property var modelData
                        readonly property var itemData: modelData.id === "separator" ? null : menuFactory.createMenuItem(modelData, false, -1)
                        readonly property int dynamicSubmenuIndex: modelData.id === "separator" ? -1 : getSubmenuIndex(modelData.id)

                        isSeparator: modelData.id === "separator"
                        text: itemData?.text || ""
                        icon: itemData?.icon || ""
                        bold: itemData?.bold || false
                        hasSubMenu: dynamicSubmenuIndex >= 0
                        submenuIndex: dynamicSubmenuIndex
                        isSubmenuItem: false

                        onTriggered: {
                            if (itemData?.onTriggered) {
                                itemData.onTriggered();
                            }
                        }
                    }
                }

                // More Options button for main page
                MenuItem {
                    isSeparator: true
                    visible: currentPage === "main" && hasAdvancedItems
                }

                MenuItem {
                    visible: currentPage === "main" && hasAdvancedItems
                    text: qsTr("More Options")
                    icon: "more_horiz"
                    onTriggered: navigateToPage("advanced")
                }
            }
        }

        Item {
            id: submenuContainer
            z: -1

            readonly property bool isTransitioning: targetSubmenuIndex >= 0
            readonly property bool shouldShowSubmenu: activeSubmenuIndex >= 0 && submenuProgress > 0

            property real interpolatedWidth: targetWidth
            property real interpolatedHeight: targetHeight
            property real interpolatedTopY: isTransitioning ? previousTopY : submenuItemY - targetHeight / 2

            property real centerOffset: (interpolatedHeight - interpolatedHeight * submenuProgress) / 2
            property real clampedY: {
                const unclampedY = interpolatedTopY + centerOffset;
                if (activeSubmenuIndex < 0 || height === 0)
                    return unclampedY;

                // Clamp to menu top edge when close
                const topDiff = Math.abs(unclampedY - menuContainer.y);
                if (topDiff < 3) {
                    return menuContainer.y;
                }

                // Clamp to menu bottom edge when close
                const menuBottom = menuContainer.y + menuContainer.height;
                const subBottom = unclampedY + height;
                const bottomDiff = Math.abs(subBottom - menuBottom);
                if (bottomDiff < 3) {
                    return menuBottom - height;
                }

                // Clamp to screen bottom
                const maxY = (root.parent ? root.parent.height - root.y : 1000) - height - bottomPadding;
                return Math.min(unclampedY, maxY);
            }

            readonly property real slideOffsetX: -10 * (1 - submenuProgress)

            Behavior on interpolatedWidth {
                enabled: submenuProgress >= 1
                Anim {
                    duration: Appearance.anim.durations.normal * 1.2
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
            Behavior on interpolatedHeight {
                enabled: submenuProgress >= 1
                Anim {
                    duration: Appearance.anim.durations.normal * 1.8
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
            Behavior on interpolatedTopY {
                enabled: submenuProgress >= 1
                Anim {
                    duration: Appearance.anim.durations.normal * 1.5
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            width: shouldShowSubmenu ? interpolatedWidth * submenuProgress : 0
            height: shouldShowSubmenu ? interpolatedHeight * submenuProgress : 0

            x: menuContainer.width + slideOffsetX
            y: clampedY
            visible: width > 0 || height > 0
            clip: true

            HoverHandler {
                id: submenuHover
            }

            ColumnLayout {
                id: submenuColumn
                anchors.fill: parent
                anchors.margins: Appearance.padding.smaller
                spacing: Appearance.spacing.smaller
                opacity: contentOpacity

                Loader {
                    id: launchSubmenuLoader
                    active: displayedSubmenuIndex >= 0 && getSubmenuParentId(displayedSubmenuIndex) === "launch"
                    visible: active
                    Layout.fillWidth: true
                    Layout.preferredHeight: active ? implicitHeight : 0

                    property var factoryRef: menuFactory
                    property var childrenRef: getSubmenuItemsForIndex(displayedSubmenuIndex)

                    sourceComponent: ContextMenus.Submenus.LaunchSubmenu {
                        app: root.app
                        visibilities: root.visibilities
                        launchApp: root.launchApp
                        toggle: root.toggle
                        children: launchSubmenuLoader.childrenRef
                        menuFactory: launchSubmenuLoader.factoryRef
                    }
                }

                Loader {
                    active: displayedSubmenuIndex >= 0 && getSubmenuParentId(displayedSubmenuIndex) === "workspaces"
                    visible: active
                    Layout.fillWidth: true
                    Layout.preferredHeight: active ? implicitHeight : 0
                    sourceComponent: ContextMenus.Submenus.WorkspaceSubmenu {
                        launchApp: root.launchApp
                    }
                }

                Loader {
                    id: categorySubmenuLoader
                    active: displayedSubmenuIndex >= 0 && getSubmenuParentId(displayedSubmenuIndex) === "categories"
                    visible: active
                    Layout.fillWidth: true
                    Layout.preferredHeight: active ? implicitHeight : 0
                    sourceComponent: ContextMenus.Submenus.CategorySubmenu {
                        app: root.app
                        Component.onCompleted: initializeState()
                        Component.onDestruction: saveChanges()
                    }
                }

                // Generic submenu for custom items
                Repeater {
                    model: {
                        if (displayedSubmenuIndex < 0)
                            return [];
                        const parentId = getSubmenuParentId(displayedSubmenuIndex);
                        if (parentId === "launch" || parentId === "workspaces" || parentId === "categories")
                            return [];
                        return getSubmenuItemsForIndex(displayedSubmenuIndex);
                    }

                    MenuItem {
                        required property var modelData
                        readonly property var itemData: modelData.id === "separator" ? null : menuFactory.createMenuItem(modelData, true, displayedSubmenuIndex)

                        isSeparator: modelData.id === "separator"
                        text: itemData?.text || ""
                        icon: itemData?.icon || ""
                        bold: itemData?.bold || false
                        hasSubMenu: false
                        submenuIndex: -1
                        isSubmenuItem: true

                        onTriggered: itemData?.onTriggered?.()
                    }
                }
            }
        }
    }
}
