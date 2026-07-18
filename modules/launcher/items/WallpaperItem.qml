import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Images
import Caelestia.Models
import qs.components
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    required property FileSystemEntry modelData
    required property ScreenState screenState

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + label.height + Tokens.spacing.extraSmall + Tokens.padding.large + Tokens.padding.medium

    Item {
        id: popContainer
        anchors.fill: parent
        scale: 0.5
        opacity: 0.3

        NumberAnimation on scale {
            to: 1
            duration: 800
            easing.type: Easing.OutBack
            running: true
        }
        NumberAnimation on opacity {
            to: 1
            duration: 800
            easing.type: Easing.OutCubic
            running: true
        }

        StateLayer {
            radius: Tokens.rounding.large
            anchors.fill: parent
            onClicked: {
                Wallpapers.setWallpaper(root.modelData.path);
                root.screenState.launcher = false;
            }
        }

        Elevation {
            anchors.fill: image
            radius: image.radius
            opacity: root.PathView.isCurrentItem ? 1 : 0
            level: 4

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledClippingRect {
            id: image

            anchors.horizontalCenter: parent.horizontalCenter
            y: Tokens.padding.large
            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            implicitWidth: Tokens.sizes.launcher.wallpaperWidth
            implicitHeight: implicitWidth / 16 * 9

            MaterialIcon {
                anchors.centerIn: parent
                text: "image"
                color: Colours.tPalette.m3outline
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
            }

            CachingImage {
                id: thumbImg
                anchors.fill: parent
                path: root.modelData.path
                source: Wallpapers.isVideo(root.modelData.path) ? Wallpapers.getWallpaperThumb(root.modelData.path, Wallpapers.itemBusters[root.modelData.path] || Wallpapers.cacheBuster) : IUtils.urlForPath(root.modelData.path, fillMode)
                smooth: !root.PathView.view.moving
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(image.implicitWidth * dpr, image.implicitHeight * dpr);
                }
                
                property bool isThumbReady: !Wallpapers._refreshing || Wallpapers.itemBusters[root.modelData.path] !== undefined
                
                // Premium fade-in and scale animation when loaded
                opacity: isThumbReady && status === Image.Ready ? 1 : 0
                scale: isThumbReady && status === Image.Ready ? 1 : 0.7
                
                Behavior on opacity {
                    NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 800; easing.type: Easing.OutBack }
                }
            }
        }

        StyledText {
            id: label

            anchors.top: image.bottom
            anchors.topMargin: Tokens.spacing.extraSmall
            anchors.horizontalCenter: parent.horizontalCenter

            width: image.width - Tokens.padding.medium * 2
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            renderType: Text.QtRendering
            text: root.modelData.relativePath
            font: Tokens.font.label.medium
        }
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
