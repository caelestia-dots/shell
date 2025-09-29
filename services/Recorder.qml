pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    property bool needsStart
    property list<string> startArgs: []
    property bool needsStop
    property bool needsPause

    function start(extraArgs: list<string>): void {
        needsStart = true;
        startArgs = extraArgs || [];
        checkProc.running = true;
    }

    function stop(): void {
        needsStop = true;
        checkProc.running = true;
    }

    function togglePause(): void {
        needsPause = true;
        checkProc.running = true;
    }

    // Re-run the pid check to update running/paused state when the recorder
    // was started or stopped outside of Recorder.start/stop.
    function refresh(): void {
        checkProc.running = true;
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0 // Might get too large for int

        reloadableId: "recorder"
    }

    Process {
        id: checkProc

        running: true
        command: ["pidof", "gpu-screen-recorder"]
        onExited: code => {
            const wasRunning = props.running;
            props.running = code === 0;

            if (code === 0) {
                if (root.needsStop) {
                    Quickshell.execDetached(["caelestia", "record"]);
                    props.running = false;
                    props.paused = false;
                    props.elapsed = 0;
                } else if (root.needsPause) {
                    Quickshell.execDetached(["caelestia", "record", "-p"]);
                    props.paused = !props.paused;
                } else if (!wasRunning && props.running) {
                    // External start detected (e.g., via AreaPicker path)
                    props.paused = false;
                    props.elapsed = 0;
                }
            } else if (root.needsStart) {
                Quickshell.execDetached(["caelestia", "record", ...root.startArgs]);
                props.running = true;
                props.paused = false;
                props.elapsed = 0;
            } else if (wasRunning && !props.running) {
                // External stop detected
                props.paused = false;
                props.elapsed = 0;
            }

            root.needsStart = false;
            root.needsStop = false;
            root.needsPause = false;
        }
    }

    // Poll for recorder state while running or when actions are pending
    Timer {
        interval: 1000
        repeat: true
        running: props.running || root.needsStart || root.needsStop || root.needsPause
        onTriggered: checkProc.running = true
    }

    Connections {
        target: Time
        enabled: props.running && !props.paused

        function onSecondsChanged(): void {
            props.elapsed++;
        }
    }
}
