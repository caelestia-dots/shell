pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Configurable durations (bound to persisted config) ─────────────────
    property int workDuration: 25
    property int shortBreakDuration: 5
    property int longBreakDuration: 15
    property bool useLongBreak: true
    property bool soundEnabled: true
    property int soundVolume: 80

    // ── Phases ────────────────────────────────────────────────────────────
    readonly property var phases: [
        {
            name: "Work",
            duration: workDuration * 60,
            type: "work"
        },
        {
            name: "Break",
            duration: shortBreakDuration * 60,
            type: "break"
        },
        {
            name: "Work",
            duration: workDuration * 60,
            type: "work"
        },
        {
            name: "Break",
            duration: shortBreakDuration * 60,
            type: "break"
        },
        {
            name: "Work",
            duration: workDuration * 60,
            type: "work"
        },
        {
            name: useLongBreak ? "Long Break" : "Break",
            duration: (useLongBreak ? longBreakDuration : shortBreakDuration) * 60,
            type: "break"
        }
    ]

    // ── State ─────────────────────────────────────────────────────────────
    property int phaseIndex: 0
    property int elapsed: 0
    property bool isRunning: false
    property bool idleMode: false
    property int idleElapsed: 0
    property int pomodoroCount: 0
    property int cycleCount: 0

    // ── Animated progress (smooth ring) ───────────────────────────────────
    property bool smoothProgress: true
    property real animatedProgress: 0

    // ── Derived ───────────────────────────────────────────────────────────
    readonly property var currentPhase: phases[phaseIndex]
    readonly property real progress: currentPhase.duration > 0 ? elapsed / currentPhase.duration : 0
    readonly property int timeRemaining: currentPhase.duration - elapsed

    // ── Logic ─────────────────────────────────────────────────────────────
    function playSound() {
        if (!soundEnabled)
            return;
        soundProcess.running = false;
        Qt.callLater(function () {
            soundProcess.running = true;
        });
    }

    function snapRingToZero() {
        smoothProgress = false;
        animatedProgress = 0;
        Qt.callLater(function () {
            root.smoothProgress = true;
        });
    }

    function phaseCompleted() {
        playSound();
        if (currentPhase.type === "work") {
            pomodoroCount++;
            snapRingToZero();
            elapsed = 0;
            phaseIndex = (phaseIndex + 1) % phases.length;
            idleMode = false;
            isRunning = true;
        } else {
            if (phaseIndex === phases.length - 1)
                cycleCount++;
            isRunning = false;
            idleMode = true;
            idleElapsed = 0;
        }
    }

    function goToPrev() {
        if (idleMode) {
            idleMode = false;
            idleElapsed = 0;
            elapsed = 0;
            return;
        }
        snapRingToZero();
        if (elapsed > 5) {
            elapsed = 0;
        } else {
            phaseIndex = (phaseIndex - 1 + phases.length) % phases.length;
            elapsed = 0;
        }
    }

    function skipToNext() {
        const wasActive = isRunning || idleMode;
        snapRingToZero();
        elapsed = 0;
        phaseIndex = (phaseIndex + 1) % phases.length;
        idleMode = false;
        idleElapsed = 0;
        isRunning = wasActive;
    }

    function togglePlayPause() {
        if (idleMode) {
            snapRingToZero();
            elapsed = 0;
            phaseIndex = (phaseIndex + 1) % phases.length;
            idleMode = false;
            idleElapsed = 0;
            isRunning = true;
        } else {
            isRunning = !isRunning;
        }
    }

    function resetCurrent() {
        if (idleMode) {
            idleMode = false;
            idleElapsed = 0;
        }
        snapRingToZero();
        elapsed = 0;
    }

    function formatTime(secs) {
        const s = Math.max(0, Math.floor(secs));
        return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
    }

    onPhasesChanged: {
        const newDuration = phases[phaseIndex].duration;
        if (elapsed >= newDuration)
            elapsed = Math.max(0, newDuration - 1);
    }

    onProgressChanged: animatedProgress = progress

    Behavior on animatedProgress {
        enabled: root.smoothProgress

        NumberAnimation {
            duration: 950
            easing.type: Easing.Linear
        }
    }

    // ── Tick ──────────────────────────────────────────────────────────────
    Timer {
        id: ticker

        interval: 1000
        repeat: true
        running: root.isRunning || root.idleMode

        onTriggered: {
            if (root.idleMode) {
                root.idleElapsed++;
                return;
            }
            root.elapsed++;
            if (root.elapsed >= root.currentPhase.duration)
                root.phaseCompleted();
        }
    }

    // ── Sound ──────────────────────────────────────────────────────────────
    Process {
        id: soundProcess

        command: ["mpv", "--no-video", "--really-quiet", "--no-terminal", "--volume=" + root.soundVolume, "/usr/share/sounds/freedesktop/stereo/complete.oga"]
    }
}
