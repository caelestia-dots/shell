pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    property int refCount: 0
    property bool arming

    readonly property string startScript: `${Quickshell.shellDir}/scripts/record-start.sh`

    function start(extraArgs = []): void {
        if (props.running || root.arming)
            return;

        root.arming = true;
        // Detached: must not be tied to the utilities panel Process lifetime
        Quickshell.execDetached([root.startScript, ...extraArgs]);
        props.running = true;
        props.paused = false;
        props.elapsed = 0;

        // Confirm pid shortly after start; clear arming either way
        armingTimer.restart();
        checkTimer.restart();
    }

    function stop(): void {
        if (!props.running && !root.arming)
            return;
        root.arming = false;
        Quickshell.execDetached(["caelestia", "record"]);
        props.running = false;
        props.paused = false;
        checkTimer.restart();
    }

    function togglePause(): void {
        if (!props.running)
            return;
        Quickshell.execDetached(["caelestia", "record", "-p"]);
        props.paused = !props.paused;
    }

    function syncFromSystem(): void {
        checkProc.running = true;
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0

        reloadableId: "recorder"
    }

    Process {
        id: checkProc

        command: ["pidof", "gpu-screen-recorder"]
        onExited: code => {
            const alive = code === 0;
            if (root.arming && alive)
                root.arming = false;

            if (alive === props.running)
                return;

            // External start/stop (keybind) or start failed
            if (!root.arming) {
                props.running = alive;
                if (!alive) {
                    props.paused = false;
                    props.elapsed = 0;
                }
            } else if (!alive) {
                // Still arming and no process yet — keep optimistic running until armingTimer ends
            }
        }
    }

    Timer {
        id: armingTimer

        interval: 2500
        onTriggered: {
            root.arming = false;
            checkProc.running = true;
        }
    }

    Timer {
        id: checkTimer

        interval: 800
        running: props.running || root.arming || root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }

    Connections {
        function onSecondsChanged(): void {
            props.elapsed++;
        }

        enabled: props.running && !props.paused
        target: Time
    }
}
