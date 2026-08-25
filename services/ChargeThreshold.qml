pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    property string path
    property int threshold: 100
    readonly property real limit: threshold / 100
    readonly property bool isLimited: threshold > 0 && threshold < 100

    Process {
        id: findProc

        running: true
        command: ["sh", "-c", `for f in /sys/class/power_supply/*/charge_control_end_threshold /sys/class/power_supply/*/charge_stop_threshold; do if [ -r "$f" ]; then echo "$f"; exit; fi; done`]
        stdout: StdioCollector {
            onStreamFinished: root.path = text.trim()
        }
    }

    FileView {
        id: file

        path: root.path
        printErrors: false
        onLoaded: {
            const t = parseInt(text().trim());
            root.threshold = isNaN(t) || t <= 0 ? 100 : t;
        }
    }

    Timer {
        running: true
        repeat: true
        interval: GlobalConfig.general.battery.chargeThresholdPollInterval
        onTriggered: {
            if (root.path)
                file.reload();
            else if (!findProc.running)
                findProc.running = true;
        }
    }
}
