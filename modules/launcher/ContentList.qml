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
    readonly property bool showMenu: {
        if (!GlobalConfig.launcher.menu.enabled || showWallpapers)
            return false;
        const menuPrefix = GlobalConfig.launcher.menu.prefix;
        if (menuPrefix !== "" && search.text.startsWith(menuPrefix))
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
    readonly property var currentList: showMenu ? menuList.item : showWallpapers ? wallpaperList.item : appList.item // Can be either ListView or PathView, so can't type properly
    property string animState: showMenu ? "menu" : showWallpapers ? "wallpapers" : "apps"

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: animState

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

        readonly property string emptyIcon: root.state === "wallpapers" ? "wallpaper_slideshow" : root.state === "menu" && MenuService.error !== "" ? "error" : root.state === "menu" ? "menu_open" : "manage_search"
        readonly property string emptyTitle: root.state === "wallpapers" ? Tr.tr("No wallpapers found") : root.state === "menu" && MenuService.error !== "" ? Tr.tr("Menu definition error") : root.state === "menu" ? Tr.tr("No matching entries") : Tr.tr("No results")
        readonly property string emptySubtitle: root.state === "menu" && MenuService.error !== "" ? MenuService.error : root.state === "wallpapers" && Wallpapers.list.length === 0 ? Tr.tr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : Tr.tr("Try searching for something else")

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
