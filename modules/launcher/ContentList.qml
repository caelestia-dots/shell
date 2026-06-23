pragma ComponentBehavior: Bound
import Caelestia.Config

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property var content
    readonly property var currentList: showWallpapers ? wallpaperList.item : appList.item // Can be either ListView or PathView, so can't type properly

    required property real maxHeight
    required property int padding
    required property var panels
    required property int rounding
    required property StyledTextField search
    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    required property DrawerVisibilities visibilities

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    clip: true
    state: showWallpapers ? "wallpapers" : "apps"

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher

        Anim {
            duration: Tokens.anim.durations.large
            easing: Tokens.anim.emphasizedDecel
        }
    }
    Behavior on implicitWidth {
        enabled: root.visibilities.launcher

        Anim {
            duration: Tokens.anim.durations.large
            easing: Tokens.anim.emphasizedDecel
        }
    }
    Behavior on state {
        SequentialAnimation {
            Anim {
                from: 1
                property: "opacity"
                target: root
                to: 0
                type: Anim.StandardSmall
            }
            PropertyAction {
            }
            Anim {
                from: 0
                property: "opacity"
                target: root
                to: 1
                type: Anim.StandardSmall
            }
        }
    }
    states: [
        State {
            name: "apps"

            PropertyChanges {
                appList.active: true
                root.implicitHeight: Math.min(root.maxHeight, appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight)
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
            }
            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight + 56
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                wallpaperList.active: true
            }
        }
    ]

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

        active: false
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        asynchronous: true

        sourceComponent: ColumnLayout {
            implicitWidth: listComp.implicitWidth
            spacing: Tokens.spacing.normal

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.normal * 1.06

                // Dedicated IconTextButtons to independently filter views between static images and animated videos within the picker UI.
                IconTextButton {
                    font.pointSize: Tokens.font.size.small
                    horizontalPadding: Tokens.padding.medium
                    icon: "image"
                    isRound: true
                    text: qsTr("Static")
                    type: Wallpapers.wallpaperMode === "static" ? IconTextButton.Filled : IconTextButton.Tonal
                    verticalPadding: Tokens.padding.extraSmall

                    onClicked: Wallpapers.setWallpaperMode("static")
                }
                IconTextButton {
                    font.pointSize: Tokens.font.size.small
                    horizontalPadding: Tokens.padding.medium
                    icon: "movie"
                    isRound: true
                    text: qsTr("Animated")
                    type: Wallpapers.wallpaperMode === "animated" ? IconTextButton.Filled : IconTextButton.Tonal
                    verticalPadding: Tokens.padding.extraSmall

                    onClicked: Wallpapers.setWallpaperMode("animated")
                }
                IconTextButton {
                    font.pointSize: Tokens.font.size.small
                    horizontalPadding: Tokens.padding.medium
                    icon: "refresh"
                    isRound: true
                    scale: 0.9
                    text: qsTr("Refresh")
                    type: IconTextButton.Tonal
                    verticalPadding: Tokens.padding.extraSmall
                    visible: Wallpapers.wallpaperMode === "animated"

                    onClicked: {
                        Wallpapers.refreshAnimatedThumbs();
                    }
                }
                Text {
                    id: processingText

                    property int dotCount: 1

                    Layout.alignment: Qt.AlignVCenter
                    color: Colours.palette.m3secondary
                    font.pointSize: Tokens.font.size.small
                    text: "Processing" + ".".repeat(dotCount)
                    visible: Wallpapers._refreshing && Wallpapers.wallpaperMode === "animated"

                    Timer {
                        interval: 400
                        repeat: true
                        running: processingText.visible

                        onTriggered: {
                            processingText.dotCount = (processingText.dotCount % 3) + 1;
                        }
                    }
                }
            }
            WallpaperList {
                id: listComp

                Layout.fillHeight: true
                Layout.fillWidth: true
                content: root.content
                panels: root.panels
                search: root.search
                visibilities: root.visibilities
            }
        }
    }
    Row {
        id: empty

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.currentList?.count === 0 ? 1 : 0
        padding: Tokens.padding.large
        scale: root.currentList?.count === 0 ? 1 : 0.5
        spacing: Tokens.spacing.normal

        Behavior on opacity {
            Anim {
            }
        }
        Behavior on scale {
            Anim {
            }
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.extraLarge
            text: root.state === "wallpapers" ? "wallpaper_slideshow" : "manage_search"
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.larger
                font.weight: 500
                text: root.state === "wallpapers" ? qsTr("No wallpapers found") : qsTr("No results")
            }
            StyledText {
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal
                text: root.state === "wallpapers" && Wallpapers.list.length === 0 ? qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : qsTr("Try searching for something else")
            }
        }
    }
}
