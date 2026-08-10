pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias starting: props.starting
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    readonly property alias videoMode: props.videoMode
    readonly property alias audioMode: props.audioMode

    // Region and window captures only spawn the recorder once the user has
    // picked a target, so give them room before calling the start a failure.
    readonly property int maxChecks: 30

    property bool stopping: false
    property int checks: 0

    signal errorOccurred(errorMsg: string)
    signal recordingStarted
    signal recordingStopped

    function start(videoMode: string, audioMode: string): void {
        if (props.running || props.starting) {
            root.errorOccurred(qsTr("A recording is already in progress"));
            return;
        }

        props.videoMode = videoMode || "fullscreen";
        props.audioMode = audioMode || "none";
        props.starting = true;
        props.paused = false;
        props.elapsed = 0;
        root.checks = 0;

        Quickshell.execDetached(["caelestia", "record", "--mode", props.videoMode, "--audio", props.audioMode]);
        poll.restart();
    }

    function stop(): void {
        if (!props.running && !props.starting)
            return;

        root.stopping = true;
        root.checks = 0;
        Quickshell.execDetached(["caelestia", "record", "--stop"]);
        poll.restart();
    }

    function togglePause(): void {
        if (!props.running || root.stopping)
            return;

        Quickshell.execDetached(["caelestia", "record", "--pause"]);
        props.paused = !props.paused;
    }

    function reset(): void {
        root.stopping = false;
        root.checks = 0;
        props.starting = false;
        props.running = false;
        props.paused = false;
        props.elapsed = 0;
    }

    Component.onCompleted: pidof.running = true

    PersistentProperties {
        id: props

        property bool running: false
        property bool starting: false
        property bool paused: false
        property real elapsed: 0 // Might get too large for int
        property string videoMode: "fullscreen"
        property string audioMode: "none"

        reloadableId: "recorder"
    }

    // The CLI hands off to gpu-screen-recorder and exits, so its own exit says
    // nothing about whether a recording is up. Watching for the process is the
    // only way to know, and it also picks up a recording started from a
    // terminal or one that died on its own.
    Process {
        id: pidof

        command: ["pidof", "gpu-screen-recorder"]

        onExited: code => { // qmllint disable signal-handler-parameters
            const alive = code === 0;

            if (root.stopping) {
                if (alive && ++root.checks < root.maxChecks) {
                    poll.restart();
                    return;
                }
                root.reset();
                root.recordingStopped();
            } else if (props.starting) {
                if (alive) {
                    root.checks = 0;
                    props.starting = false;
                    props.running = true;
                    root.recordingStarted();
                    poll.restart();
                    return;
                }
                if (++root.checks < root.maxChecks) {
                    poll.restart();
                    return;
                }
                root.reset();
                root.errorOccurred(qsTr("Recording did not start"));
            } else if (props.running) {
                if (alive) {
                    poll.restart();
                    return;
                }
                root.reset();
                root.recordingStopped();
            } else if (alive) {
                // Adopt whatever was already recording when the shell came up
                props.running = true;
                poll.restart();
            }
        }
    }

    Timer {
        id: poll

        interval: root.stopping ? 500 : props.starting ? 1000 : 3000
        onTriggered: pidof.running = true
    }

    Timer {
        interval: 1000
        repeat: true
        running: props.running && !props.paused
        onTriggered: props.elapsed++
    }
}
