pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import Caelestia.I18n
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

    function applyPrefill(): void {
        if (!screenState.launcher || !screenState.launcherPrefill)
            return;

        search.text = screenState.launcherPrefill;
        screenState.launcherPrefill = "";
    }

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

        placeholderText: Tr.tr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

        onAccepted: {
            if (list.showPicker) {
                list.currentList?.activate(false);
                return;
            }

            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showWallpapers) {
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

        Keys.onUpPressed: root.move("up")
        Keys.onDownPressed: root.move("down")

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
                    root.move("down");
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    root.move("up");
                    event.accepted = true;
                } else if (list.showPicker && event.key === Qt.Key_H) {
                    root.move("left");
                    event.accepted = true;
                } else if (list.showPicker && event.key === Qt.Key_L) {
                    root.move("right");
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                root.move("down");
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                root.move("up");
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            forceActiveFocus();
            root.applyPrefill();
        }

        // Lets other things (i.e. the picker shortcuts) tell whether the launcher is in a given mode
        onTextChanged: root.screenState.launcherText = text

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    search.text = "";
                else
                    root.applyPrefill();
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
    }
}
