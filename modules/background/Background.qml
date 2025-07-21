import qs.widgets
import qs.config
import Quickshell
import Quickshell.Wayland

LazyLoader {
    activeAsync: Config.background.enabled

    Variants {
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

            DesktopClock {
                visible: Config.background.desktopClock.enabled
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Appearance.padding.large
            }
        }
    }
}
