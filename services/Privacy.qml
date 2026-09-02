pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.utils

// Tracks which privacy sensitive devices are in use, as reported by the
// privacy-monitor helper.
Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.privacy.enabled

    // Whether the helper is alive and PipeWire is reachable, so a quiet
    // indicator can be told apart from a broken one.
    property bool monitorRunning: false
    readonly property bool pipewireOk: raw.pipewire ?? false
    readonly property bool healthy: monitorRunning && pipewireOk

    // Last payload from the helper.
    property var raw: ({})

    readonly property string monitorPath: `${Paths.libdir}/privacy-monitor`

    readonly property var definitions: [
        {
            id: "microphone",
            icon: "mic",
            label: qsTr("Microphone"),
            verb: qsTr("is listening")
        },
        {
            id: "camera",
            icon: "videocam",
            label: qsTr("Camera"),
            verb: qsTr("is recording")
        },
        {
            id: "screen",
            icon: "screen_share",
            label: qsTr("Screen"),
            verb: qsTr("is being captured")
        },
        {
            id: "location",
            icon: "location_on",
            label: qsTr("Location"),
            verb: qsTr("was shared")
        }
    ]

    readonly property var sensors: definitions.map(def => {
        const s = root.raw[def.id] ?? {};
        return {
            id: def.id,
            icon: def.icon,
            label: def.label,
            verb: def.verb,
            watched: root.watches(def.id),
            active: !!(root.watches(def.id) && s.active),
            standby: !!s.standby,
            apps: s.apps ?? []
        };
    })

    readonly property var active: sensors.filter(s => s.active)
    readonly property bool anyActive: active.length > 0

    // Sensors already toasted, so only fresh activations are announced.
    property var announced: []

    // Toggled off and back on by the retry timer so the Process binding stays
    // intact; assigning to running directly would break it.
    property bool monitorWanted: true

    function watches(id: string): bool {
        const devices = GlobalConfig.privacy.devices;
        if (id === "microphone")
            return devices.microphone;
        if (id === "camera")
            return devices.camera;
        if (id === "screen")
            return devices.screen;
        if (id === "location")
            return devices.location;
        return false;
    }

    function describe(sensor: var): string {
        const apps = sensor.apps ?? [];
        if (apps.length === 0)
            return qsTr("Unidentified application");
        return apps.join(", ");
    }

    function summary(sensor: var): string {
        return `${sensor.label} ${sensor.verb}`;
    }

    onActiveChanged: {
        const ids = active.map(s => s.id);
        const fresh = active.filter(s => !announced.includes(s.id));
        announced = ids;

        if (!GlobalConfig.privacy.showToasts)
            return;

        for (const sensor of fresh)
            Toaster.toast(root.summary(sensor), root.describe(sensor), sensor.icon, Toast.Warning);
    }

    Process {
        id: monitor

        command: [root.monitorPath]
        running: root.enabled && root.monitorWanted

        stdout: SplitParser {
            onRead: line => {
                try {
                    root.raw = JSON.parse(line);
                } catch (e) {
                    // A truncated line is not worth tearing the service down.
                }
            }
        }

        onRunningChanged: {
            root.monitorRunning = running;
            if (!running)
                root.raw = ({});
        }

        // Silent monitoring is worse than no monitoring, so always come back.
        onExited: { // qmllint disable signal-handler-parameters
            if (root.enabled) {
                root.monitorWanted = false;
                retry.restart();
            }
        }
    }

    Timer {
        id: retry

        interval: 3000
        onTriggered: root.monitorWanted = true
    }

    IpcHandler {
        function status(): string {
            return JSON.stringify(root.raw);
        }

        function isActive(): bool {
            return root.anyActive;
        }

        target: "privacy"
    }
}
