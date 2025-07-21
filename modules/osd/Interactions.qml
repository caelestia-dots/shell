import qs.services
import qs.config
import Quickshell
import QtQuick

Scope {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property bool hovered
    readonly property Brightness.Monitor monitor: Brightness.getMonitorForScreen(screen)

    function show(): void {
        root.visibilities.osd = true;
        timer.restart();
    }

    Connections {
        target: Audio

        function onMutedChanged(): void {
            root.show();
        }

        function onVolumeChanged(): void {
            root.show();
        }
    }

    Connections {
        target: root.monitor

        function onBrightnessChanged(): void {
            root.show();
        }
    }

    Timer {
        id: timer

        interval: Config.osd.hideDelay
        onTriggered: {
            if (!root.hovered)
                root.visibilities.osd = false;
        }
    }
}
