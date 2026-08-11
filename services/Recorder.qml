pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    property int refCount: 0
    property real lastCommand: 0
    property bool pending // Waiting for the proc to catch up with a command of ours
    property bool needsStart
    property list<string> startArgs
    property bool needsStop
    property bool needsPause

    function start(extraArgs = []): void {
        needsStart = true;
        startArgs = extraArgs;
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
        onExited: code => { // qmllint disable signal-handler-parameters
            const running = code === 0;

            if (running && root.needsStop) {
                Quickshell.execDetached(["caelestia", "record"]);
                props.running = false;
                props.paused = false;
                root.pending = true;
            } else if (running && root.needsPause) {
                Quickshell.execDetached(["caelestia", "record", "-p"]);
                props.paused = !props.paused;
            } else if (!running && root.needsStart) {
                Quickshell.execDetached(["caelestia", "record", ...root.startArgs]);
                props.running = true;
                props.paused = false;
                props.elapsed = 0;
                root.pending = true;
            } else if (running === props.running) {
                root.pending = false; // The proc caught up with us
            } else if (!root.pending || Date.now() - root.lastCommand > 10000) {
                // The recording was started/stopped outside the shell (e.g. via
                // keybind), or a command of ours never took effect
                props.running = running;
                props.paused = false;
                props.elapsed = 0;
                root.pending = false;
            }

            if (root.needsStart || root.needsStop || root.needsPause)
                root.lastCommand = Date.now();

            root.needsStart = false;
            root.needsStop = false;
            root.needsPause = false;
        }
    }

    // Only poll while something is showing the state, i.e. the utilities drawer is open
    Timer {
        interval: 1000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true

        onTriggered: checkProc.running = true
    }

    Connections {
        enabled: props.running && !props.paused

        function onSecondsChanged(): void {
            props.elapsed++;
        }

        target: Time // qmllint disable incompatible-type
    }
}
