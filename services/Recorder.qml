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
    
    // Fast polling for instant feedback on recording actions
    property bool fastPolling: false
    property int fastPollCount: 0

    function start(extraArgs: list<string>): void {
        needsStart = true;
        startArgs = extraArgs || [];
        startFastPolling();
        checkProc.running = true;
    }

    function stop(): void {
        needsStop = true;
        startFastPolling();
        checkProc.running = true;
    }

    function togglePause(): void {
        needsPause = true;
        startFastPolling();
        checkProc.running = true;
    }
    
    // Start fast polling for instant feedback (called externally for area recordings)
    function startFastPolling(): void {
        fastPolling = true;
        fastPollCount = 0;
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
                    // External start detected (e.g., region recording via area picker CLI)
                    props.paused = false;
                    props.elapsed = 0;
                }
            } else if (root.needsStart) {
                Quickshell.execDetached(["caelestia", "record", ...root.startArgs]);
                props.running = true;
                props.paused = false;
                props.elapsed = 0;
            } else if (wasRunning && !props.running) {
                // External stop detected (e.g., recording finished externally)
                props.paused = false;
                props.elapsed = 0;
            }

            root.needsStart = false;
            root.needsStop = false;
            root.needsPause = false;
        }
    }

    // Smart polling: fast when actions are pending or during fast poll burst, slower when idle
    Timer {
        interval: {
            if (root.fastPolling || root.needsStart || root.needsStop || root.needsPause) {
                return 200; // Very fast polling for instant feedback
            } else if (props.running) {
                return 1000; // Normal polling when recording
            } else {
                return 3000; // Slow polling when idle
            }
        }
        repeat: true
        running: true
        onTriggered: {
            checkProc.running = true;
            
            // Manage fast polling burst - stop after 10 fast polls (2 seconds)
            if (root.fastPolling) {
                root.fastPollCount++;
                if (root.fastPollCount >= 10) {
                    root.fastPolling = false;
                    root.fastPollCount = 0;
                }
            }
        }
    }

    Connections {
        target: Time
        enabled: props.running && !props.paused

        function onSecondsChanged(): void {
            props.elapsed++;
        }
    }
}
