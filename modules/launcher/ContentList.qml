pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property var content
    required property ScreenState screenState
    required property var panels
    required property real maxHeight
    required property SearchBar search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    readonly property var picker: Pickers.forText(search.text) // The open picker (i.e. emoji), if any
    readonly property bool showPicker: picker !== null
    readonly property bool showClipboard: GlobalConfig.launcher.clipboard.enabled && search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}clipboard `)
    readonly property bool showPreview: showClipboard && GlobalConfig.launcher.clipboard.showPreview
    readonly property bool showMenu: {
        if (!GlobalConfig.launcher.menu.enabled || showWallpapers || showPicker || showClipboard)
            return false;
        const menuPrefix = GlobalConfig.launcher.menu.prefix;
        if (menuPrefix === "" || menuPrefix === GlobalConfig.launcher.actionPrefix)
            return false;
        if (search.text.startsWith(menuPrefix))
            return true;
        return GlobalConfig.launcher.menu.defaultView && !search.text.startsWith(GlobalConfig.launcher.actionPrefix);
    }
    readonly property string hintText: {
        if (showMenu)
            return Tr.tr("Search menu…");
        if (GlobalConfig.launcher.menu.enabled && GlobalConfig.launcher.menu.prefix !== "")
            return Tr.tr("Type \"%1\" for commands or \"%2\" for menu").arg(GlobalConfig.launcher.actionPrefix).arg(GlobalConfig.launcher.menu.prefix);
        return Tr.tr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix);
    }
    readonly property var currentList: showMenu ? menuList.item : showWallpapers ? wallpaperList.item : showPicker ? pickerList.item : showClipboard ? clipboardList.item : appList.item // Can be a ListView, PathView or PickerList, so can't type properly
    property string animState: showMenu ? "menu" : showWallpapers ? "wallpapers" : showPicker ? "picker" : showClipboard ? "clipboard" : "apps"

    // Kept so the picker doesn't lose its source while fading out
    property var lastPicker

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: animState

    onPickerChanged: {
        if (picker)
            lastPicker = picker;
    }

    states: [
        State {
            name: "menu"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, menuList.implicitHeight > 0 ? menuList.implicitHeight : empty.implicitHeight)
                menuList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "apps"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight)
                appList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "picker"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, pickerList.implicitHeight > 0 ? pickerList.implicitHeight : empty.implicitHeight)
                pickerList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "clipboard"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, clipboardList.implicitHeight > 0 ? clipboardList.implicitHeight : empty.implicitHeight)
                clipboardList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight
                wallpaperList.active: true
            }
        }
    ]

    Behavior on animState {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                type: Anim.DefaultEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: menuList

        active: false

        anchors.fill: parent

        sourceComponent: MenuList {
            objectName: "launcherMenuList"

            search: root.search
            screenState: root.screenState
        }
    }

    Loader {
        id: appList

        active: false

        anchors.fill: parent

        sourceComponent: AppList {
            objectName: "launcherAppList"

            search: root.search
            screenState: root.screenState
        }
    }

    Loader {
        id: pickerList

        active: false

        anchors.fill: parent

        sourceComponent: PickerList {
            objectName: "launcherPickerList"

            search: root.search
            screenState: root.screenState
            source: root.picker ?? root.lastPicker
        }
    }

    Loader {
        id: clipboardList

        active: false

        anchors.fill: parent

        sourceComponent: ClipboardList {
            objectName: "launcherClipboardList"

            search: root.search
            screenState: root.screenState
        }
    }

    Loader {
        id: wallpaperList

        asynchronous: true
        active: false

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WallpaperList {
            objectName: "launcherWallpaperList"

            search: root.search
            screenState: root.screenState
            panels: root.panels
            content: root.content
        }
    }

    Row {
        id: empty

        readonly property string emptyIcon: root.state === "wallpapers" ? "wallpaper_slideshow" : root.state === "menu" && MenuService.error !== "" ? "error" : root.state === "menu" ? "menu_open" : root.state === "clipboard" && Clipboard.history.length === 0 ? "content_paste_off" : "manage_search"
        readonly property string emptyTitle: root.state === "wallpapers" ? Tr.tr("No wallpapers found") : root.state === "menu" && MenuService.error !== "" ? Tr.tr("Menu definition error") : root.state === "menu" ? Tr.tr("No matching entries") : root.state === "clipboard" && Clipboard.history.length === 0 ? Tr.tr("Clipboard is empty") : Tr.tr("No results")
        readonly property string emptySubtitle: root.state === "menu" && MenuService.error !== "" ? MenuService.error : root.state === "wallpapers" && Wallpapers.list.length === 0 ? Tr.tr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : root.state === "clipboard" && Clipboard.history.length === 0 ? Tr.tr("Copy something and it will show up here") : Tr.tr("Try searching for something else")

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: empty.emptyIcon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: empty.emptyTitle
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: empty.emptySubtitle
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

    Behavior on implicitWidth {
        enabled: root.screenState.launcher

        Anim {}
    }

    Behavior on implicitHeight {
        enabled: root.screenState.launcher

        Anim {}
    }
}
