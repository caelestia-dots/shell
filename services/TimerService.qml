pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config

Singleton {
    id: root

    property bool active: false
    property bool running: false
    property int totalSeconds: 0
    property int remainingSeconds: 0
    readonly property real progress: totalSeconds > 0 ? Math.max(0, Math.min(1, 1 - remainingSeconds / totalSeconds)) : 0

    readonly property string remainingFormatted: {
        const s = remainingSeconds;
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        if (h > 0)
            return `${h}:${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
        return `${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
    }

    property bool timerDone: false

    signal finished()

    function start(h: int, m: int, s: int): void {
        const total = h * 3600 + m * 60 + s;
        if (total <= 0)
            return;
        timerDone = false;
        totalSeconds = total;
        remainingSeconds = total;
        endTimeStore.endTime = Date.now() + total * 1000;
        endTimeStore.total = total;
        running = true;
        active = true;
        countdownTimer.start();
    }

    function pause(): void {
        if (!running)
            return;
        running = false;
        countdownTimer.stop();
        endTimeStore.endTime = Date.now() + remainingSeconds * 1000;
    }

    function resume(): void {
        if (running || !active)
            return;
        endTimeStore.endTime = Date.now() + remainingSeconds * 1000;
        running = true;
        countdownTimer.start();
    }

    function cancel(): void {
        countdownTimer.stop();
        running = false;
        active = false;
        totalSeconds = 0;
        remainingSeconds = 0;
        endTimeStore.endTime = 0;
        endTimeStore.total = 0;
    }

    onFinished: {
        const sf = GlobalConfig.bar.clock.timer?.soundFile ?? "";
        if (sf.length > 0)
            Quickshell.execDetached(["paplay", sf]);
    }

    Component.onCompleted: {
        if (endTimeStore.endTime > 0 && endTimeStore.total > 0) {
            const now = Date.now();
            if (endTimeStore.endTime > now) {
                root.totalSeconds = endTimeStore.total;
                root.remainingSeconds = Math.round((endTimeStore.endTime - now) / 1000);
                root.running = true;
                root.active = true;
                countdownTimer.start();
            } else {
                endTimeStore.endTime = 0;
                endTimeStore.total = 0;
            }
        }
    }

    Timer {
        id: countdownTimer

        interval: 500
        repeat: true

        onTriggered: {
            const remaining = Math.max(0, Math.round((endTimeStore.endTime - Date.now()) / 1000));
            root.remainingSeconds = remaining;
            if (remaining <= 0) {
                countdownTimer.stop();
                root.running = false;
                root.active = false;
                root.timerDone = true;
                root.finished();
            }
        }
    }

    PersistentProperties {
        id: endTimeStore

        property real endTime: 0
        property int total: 0

        reloadableId: "timer"
    }
}
