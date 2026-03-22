pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components.containers
import qs.services
import qs.config

Loader {
    asynchronous: true
    active: Config.background.enabled

    sourceComponent: Variants {
        model: Screens.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            name: "background"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: Config.background.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
            color: Config.background.wallpaperEnabled ? "black" : "transparent"
            surfaceFormat.opaque: false

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Item {
                id: behindClock

                anchors.fill: parent

                Loader {
                    id: wallpaper

                    asynchronous: true

                    anchors.fill: parent
                    active: Config.background.wallpaperEnabled

                    sourceComponent: Wallpaper {}
                }

                Visualiser {
                    anchors.fill: parent
                    screen: win.modelData
                    wallpaper: wallpaper
                }
            }

            Loader {
                id: clockLoader

                asynchronous: true
                active: Config.background.desktopClock.enabled

                anchors.margins: Appearance.padding.large * 2
                anchors.leftMargin: Appearance.padding.large * 2 + Config.bar.sizes.innerWidth + Math.max(Appearance.padding.smaller, Config.border.thickness)

                state: Config.background.desktopClock.position
                states: [
                    State {
                        name: "top-left"

                        AnchorChanges {
                            target: clockLoader
                            anchors.top: parent.top
                            anchors.left: parent.left
                        }
                    },
                    State {
                        name: "top-center"

                        AnchorChanges {
                            target: clockLoader
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    },
                    State {
                        name: "top-right"

                        AnchorChanges {
                            target: clockLoader
                            anchors.top: parent.top
                            anchors.right: parent.right
                        }
                    },
                    State {
                        name: "middle-left"

                        AnchorChanges {
                            target: clockLoader
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                        }
                    },
                    State {
                        name: "middle-center"

                        AnchorChanges {
                            target: clockLoader
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    },
                    State {
                        name: "middle-right"

                        AnchorChanges {
                            target: clockLoader
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                        }
                    },
                    State {
                        name: "bottom-left"

                        AnchorChanges {
                            target: clockLoader
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                        }
                    },
                    State {
                        name: "bottom-center"

                        AnchorChanges {
                            target: clockLoader
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    },
                    State {
                        name: "bottom-right"

                        AnchorChanges {
                            target: clockLoader
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                        }
                    }
                ]

                transitions: Transition {
                    AnchorAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }

                sourceComponent: DesktopClock {
                    wallpaper: behindClock
                    absX: clockLoader.x
                    absY: clockLoader.y
                }
            }
        }
    }
}
