import qs.components.containers
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

            Wallpaper {}

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
