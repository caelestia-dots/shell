pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property var content
    required property DrawerVisibilities visibilities
    required property var panels
    required property real maxHeight
    required property StyledTextField search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    readonly property bool showWindowSwitcher: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}windows `)
    readonly property bool showKeybinds: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}keybinds `)
    readonly property var currentList: showWallpapers ? wallpaperList.item : (showWindowSwitcher ? windowSwitcherList.item : (showKeybinds ? keybindsList.item : appList.item))

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: showWindowSwitcher ? "windowSwitcher" : (showKeybinds ? "keybinds" : (showWallpapers ? "wallpapers" : "apps"))

    states: [
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
        },
        State {
            name: "windowSwitcher"

            PropertyChanges {
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, windowSwitcherList.implicitWidth)
                root.implicitHeight: root.Tokens.sizes.launcher.windowSwitcherHeight
                windowSwitcherList.active: true
            }
        },
        State {
            name: "keybinds"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, root.Tokens.sizes.launcher.itemHeight * 7)
                keybindsList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        }
    ]

    Behavior on state {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                type: Anim.StandardSmall
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                type: Anim.StandardSmall
            }
        }
    }

    onStateChanged: {
        if (state === "keybinds") {
            keybindsList.active = true;
        } else {
            keybindsList.active = false;
        }
    }

    Timer {
        id: keybindsTimer
        interval: 50
        onTriggered: {
            if (state === "keybinds" && keybindsList.item) {
                keybindsList.item.refreshModel();
            }
        }
    }

    Loader {
        id: appList

        active: false

        anchors.fill: parent

        sourceComponent: AppList {
            search: root.search
            visibilities: root.visibilities
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
            search: root.search
            visibilities: root.visibilities
            panels: root.panels
            content: root.content
        }
    }

    Loader {
        id: windowSwitcherList

        asynchronous: true
        active: false

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WindowSwitcherList {
            search: root.search
            visibilities: root.visibilities
            panels: root.panels
            content: root.content
        }
    }

    Loader {
        id: keybindsList

        active: false

        anchors.fill: parent

        sourceComponent: KeybindsList {
            search: root.search
            visibilities: root.visibilities
        }
    }

    Row {
        id: empty

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.normal
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: {
                if (root.state === "wallpapers") return "wallpaper_slideshow";
                if (root.state === "keybinds") return "keyboard";
                return "manage_search";
            }
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: {
                    if (root.state === "wallpapers") return qsTr("No wallpapers found");
                    if (root.state === "keybinds") return qsTr("No keybinds found");
                    return qsTr("No results");
                }
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: {
                    if (root.state === "wallpapers") return Wallpapers.list.length === 0 ? qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : qsTr("Try searching for something else");
                    if (root.state === "keybinds") return qsTr("No keybinds match your search");
                    return qsTr("Try searching for something else");
                }
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal
            }
        }

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.visibilities.launcher

        Anim {
            duration: Tokens.anim.durations.large
            easing: Tokens.anim.emphasizedDecel
        }
    }

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher

        Anim {
            duration: Tokens.anim.durations.large
            easing: Tokens.anim.emphasizedDecel
        }
    }
}
