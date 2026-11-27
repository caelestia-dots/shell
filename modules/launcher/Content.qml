pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge

    function moveListSelection(delta: int): void {
        const l = list.currentList;
        if (!l)
            return;
        if (l.objectName === "launcherMenuList")
            l.moveSelection(delta);
        else if (delta < 0)
            l.decrementCurrentIndex();
        else
            l.incrementCurrentIndex();
    }

    function applyPendingMenu(): void {
        if (!MenuService.pendingOpen)
            return;
        MenuService.pendingOpen = false;
        const prefix = GlobalConfig.launcher.menu.prefix;
        search.text = GlobalConfig.launcher.menu.defaultView ? "" : prefix;
        search.forceActiveFocus();
    }

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: search.height + listWrapper.height + padding + search.anchors.bottomMargin

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: list.hintText
        crumbText: list.showMenu ? MenuService.breadcrumb() : ""
        onCrumbClicked: MenuService.back()

        onAccepted: {
            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showMenu) {
                    list.currentList.enterRow(currentItem.modelData);
                } else if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                        currentItem.onClicked();
                    else
                        currentItem.modelData.onClicked(list.currentList);
                } else {
                    Apps.launch(currentItem.modelData);
                    root.screenState.launcher = false;
                }
            }
        }

        Keys.onUpPressed: root.moveListSelection(-1)
        Keys.onDownPressed: root.moveListSelection(1)

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Backspace && !event.modifiers && GlobalConfig.launcher.menu.enabled && MenuService.route !== "") {
                const pfx = GlobalConfig.launcher.actionPrefix;
                if (text === `${pfx}wallpaper ` || text === `${pfx}scheme ` || text === `${pfx}variant `) {
                    const menuPfx = GlobalConfig.launcher.menu.prefix;
                    text = GlobalConfig.launcher.menu.defaultView ? "" : menuPfx;
                    event.accepted = true;
                    return;
                }
            }

            if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) && !event.modifiers && list.showMenu) {
                const menuPfx = GlobalConfig.launcher.menu.prefix;
                const menuQuery = menuPfx !== "" && text.startsWith(menuPfx) ? text.slice(menuPfx.length) : text;
                if (menuQuery === "" && MenuService.back()) {
                    event.accepted = true;
                    return;
                }
            }

            if (event.key === Qt.Key_Right && !event.modifiers && list.showMenu && cursorPosition === text.length) {
                const menuPfx = GlobalConfig.launcher.menu.prefix;
                const menuQuery = menuPfx !== "" && text.startsWith(menuPfx) ? text.slice(menuPfx.length) : text;
                if (menuQuery !== "") {
                    const currentItem = list.currentList?.currentItem;
                    if (currentItem)
                        list.currentList.enterRow(currentItem.modelData);
                    event.accepted = true;
                    return;
                }
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    root.moveListSelection(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    root.moveListSelection(-1);
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                root.moveListSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                root.moveListSelection(-1);
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            forceActiveFocus();
            root.applyPendingMenu();
        }

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher) {
                    search.text = "";
                    MenuService.scheduleRootReset();
                } else {
                    MenuService.flushRootReset();
                    if (GlobalConfig.launcher.menu.enabled)
                        MenuService.evalConds();
                    root.applyPendingMenu();
                }
            }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }

        Connections {
            function onPendingOpenChanged(): void {
                root.applyPendingMenu();
            }

            target: MenuService
        }
    }
}
