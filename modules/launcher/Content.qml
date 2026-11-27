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

    // Vertical movement across every list kind: the picker grid walks its own
    // layout, the menu list steps over separators and disabled rows, and the
    // stock lists use the standard index changers.
    function moveVertical(delta: int): void {
        if (list.showPicker) {
            list.currentList?.move(delta > 0 ? "down" : "up");
            return;
        }
        moveListSelection(delta);
    }

    // Picker grid movement (emoji/kaomoji/symbol): left/right walk cells, the
    // list itself knows its layout.
    function move(direction: string): void {
        if (list.showPicker) {
            list.currentList?.move(direction);
            return;
        }

        if (direction === "up")
            list.currentList?.decrementCurrentIndex();
        else if (direction === "down")
            list.currentList?.incrementCurrentIndex();
    }

    function applyPendingMenu(): void {
        if (!MenuService.pendingOpen)
            return;
        MenuService.pendingOpen = false;
        const prefix = GlobalConfig.launcher.menu.prefix;
        search.text = GlobalConfig.launcher.menu.defaultView ? "" : prefix;
        search.forceActiveFocus();
    }

    function applyPrefill(): void {
        if (!screenState.launcher || !screenState.launcherPrefill)
            return;

        search.text = screenState.launcherPrefill;
        screenState.launcherPrefill = "";
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
            if (list.showPicker) {
                list.currentList?.activate(false);
                return;
            }

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

        Keys.onUpPressed: root.moveVertical(-1)
        Keys.onDownPressed: root.moveVertical(1)

        // Only steal left/right from the text cursor when browsing a picker
        Keys.onLeftPressed: event => {
            if (list.showPicker)
                root.move("left");
            else
                event.accepted = false;
        }
        Keys.onRightPressed: event => {
            if (list.showPicker)
                root.move("right");
            else
                event.accepted = false;
        }

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

            // Alt + Enter pastes into the previously focused window instead of just copying
            if (list.showPicker && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.AltModifier)) {
                list.currentList?.activate(true);
                event.accepted = true;
                return;
            }

            // Tab / Shift + Tab switch between picker categories
            if (list.showPicker && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
                const back = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier);
                list.currentList?.switchCategory(back ? -1 : 1);
                event.accepted = true;
                return;
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    root.moveVertical(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    root.moveVertical(-1);
                    event.accepted = true;
                } else if (list.showPicker && event.key === Qt.Key_H) {
                    root.move("left");
                    event.accepted = true;
                } else if (list.showPicker && event.key === Qt.Key_L) {
                    root.move("right");
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                root.moveVertical(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                root.moveVertical(-1);
                event.accepted = true;
            }
        }

        // Lets other things (i.e. the picker shortcuts) tell whether the launcher is in a given mode
        onTextChanged: root.screenState.launcherText = text

        Component.onCompleted: {
            forceActiveFocus();
            root.applyPrefill();
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
                    root.applyPrefill();
                    root.applyPendingMenu();
                }
            }

            function onLauncherPrefillChanged(): void {
                root.applyPrefill();
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
