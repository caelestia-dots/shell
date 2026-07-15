pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import Quickshell.Io

Item {
    id: root

    property string activeTab: Wallpapers.activeTab
    onActiveTabChanged: Wallpapers.activeTab = activeTab

    required property var content
    required property ScreenState screenState
    required property var panels
    required property real maxHeight
    required property SearchBar search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    readonly property var currentList: showWallpapers ? wallpaperList.item : appList.item // Can be either ListView or PathView, so can't type properly
    property string animState: showWallpapers ? "wallpapers" : "apps"

    readonly property int textBarHeight: Tokens.font.size.normal + Tokens.spacing.normal * 2

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: (root.visibilities?.launcher && showWallpapers) ? "wallpapers" : "apps"

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
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight + root.textBarHeight
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
    anchors.topMargin: root.textBarHeight
    anchors.bottom: parent.bottom

    sourceComponent: WallpaperList {
        search: root.search
        visibilities: root.visibilities
        panels: root.panels
        content: root.content
        activeTab: root.activeTab
    }
}

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Tokens.spacing.normal
        spacing: Tokens.spacing.normal

        StyledRect {
            implicitWidth: btn1Text.implicitWidth + Tokens.padding.large * 2
            implicitHeight: btn1Text.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3primary
            visible: root.state == "wallpapers"
            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onPrimary
                onClicked: root.activeTab = "static"
            }

            StyledText {
                id: btn1Text
                anchors.centerIn: parent
                text: "Static"
                color: Colours.palette.m3onPrimary
                font.pointSize: Tokens.font.size.normal
            }
        }

        StyledRect {
            implicitWidth: btn2Text.implicitWidth + Tokens.padding.large * 2
            implicitHeight: btn2Text.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3primary
            visible: root.state == "wallpapers"

            Process {
                id: mpvpaper
                command: ["mpvpaper", "-o", "loop", "ALL", "../../Pictures/Wallpapers/rei_video.mp4"]
                running: false
            }

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onPrimary
                onClicked: root.activeTab = "animated"
            }

            StyledText {
                id: btn2Text
                anchors.centerIn: parent
                text: "Animated"
                color: Colours.palette.m3onPrimary
                font.pointSize: Tokens.font.size.normal
            }
        }

        StyledRect {
            implicitWidth: btn3Text.implicitWidth + Tokens.padding.large * 2
            implicitHeight: btn3Text.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3primary
            visible: root.state == "wallpapers"
            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onPrimary
                onClicked: root.activeTab = "all"
            }

            StyledText {
                id: btn3Text
                anchors.centerIn: parent
                text: "All"
                color: Colours.palette.m3onPrimary
                font.pointSize: Tokens.font.size.normal
            }
        }
    }
 
    Row {
        id: empty

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: root.state === "wallpapers" ? "wallpaper_slideshow" : "manage_search"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.state === "wallpapers" ? qsTr("No wallpapers found") : qsTr("No results")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: root.state === "wallpapers" && Wallpapers.list.length === 0 ? qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : qsTr("Try searching for something else")
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
