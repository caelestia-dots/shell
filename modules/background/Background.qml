pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Wayland
import QtQuick

Loader {
    asynchronous: true
    active: Config.background.enabled

    sourceComponent: Variants {
        model: Quickshell.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            name: "background"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            color: "black"

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Wallpaper {
                id: wallpaper
            }

            Loader {
                readonly property bool shouldBeActive: Config.background.visualiser.enabled && (!Config.background.visualiser.autoHide || Hypr.monitorFor(win.modelData).activeWorkspace.toplevels.values.every(t => t.lastIpcObject.floating)) ? 1 : 0
                property real offset: shouldBeActive ? 0 : win.modelData.height * 0.2

                anchors.fill: parent
                anchors.topMargin: offset
                anchors.bottomMargin: -offset
                opacity: shouldBeActive ? 1 : 0
                active: opacity > 0
                asynchronous: true

                sourceComponent: Visualiser {
                    screen: win.modelData
                    wallpaper: wallpaper
                }

                Behavior on offset {
                    Anim {}
                }

                Behavior on opacity {
                    Anim {}
                }
            }

            Loader {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Appearance.padding.large

                active: Config.background.desktopClock.enabled
                asynchronous: true

                source: "DesktopClock.qml"
            }
        }
    }
}
