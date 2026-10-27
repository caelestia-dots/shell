pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils

Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.addons.timers.enabled

    property list<var> timers: []
    property int nextId: 1
    property bool loaded: false

    readonly property Timer tick: Timer {
        interval: 250
        running: root.enabled && root.timers.length > 0
        repeat: true
        onTriggered: root.tickTimers()
    }

    readonly property Timer saveTimer: Timer {
        interval: 200
        onTriggered: root.persist()
    }

    function setEnabled(on: bool): void {
        if (GlobalConfig.addons.timers.enabled === on)
            return;
        GlobalConfig.addons.timers.enabled = on;
    }

    function clearAll(): void {
        root.timers = [];
        root.schedulePersist();
    }

    function formatRemaining(ms: int): string {
        const total = Math.max(0, Math.ceil(ms / 1000));
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        if (h > 0)
            return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
        return `${m}:${String(s).padStart(2, "0")}`;
    }

    function schedulePersist(): void {
        if (root.loaded)
            saveTimer.restart();
    }

    function persist(): void {
        if (!root.loaded)
            return;
        storage.setText(JSON.stringify({
                    nextId: root.nextId,
                    timers: root.timers.map(t => ({
                                id: t.id,
                                label: t.label,
                                durationMs: t.durationMs,
                                endAt: t.endAt
                            }))
                }));
    }

    function addMinutes(minutes: real, label: string): void {
        if (!root.enabled)
            return;
        const mins = Math.max(0.05, Number(minutes) || 0);
        const durationMs = Math.round(mins * 60000);
        const id = root.nextId++;
        const pretty = label && label.length ? label : Tr.trN("%n min", "%n mins", Math.round(mins));
        root.timers = [
            ...root.timers,
            {
                id: id,
                label: pretty,
                durationMs: durationMs,
                endAt: Date.now() + durationMs,
                remainingMs: durationMs
            }
        ];
        root.schedulePersist();
    }

    function cancel(id: int): void {
        root.timers = root.timers.filter(t => t.id !== id);
        root.schedulePersist();
    }

    function tickTimers(): void {
        if (!root.enabled)
            return;
        const now = Date.now();
        const kept = [];
        let finished = false;
        for (const t of root.timers) {
            const remaining = t.endAt - now;
            if (remaining <= 0) {
                finished = true;
                root.finish(t);
            } else {
                kept.push({
                            id: t.id,
                            label: t.label,
                            durationMs: t.durationMs,
                            endAt: t.endAt,
                            remainingMs: remaining
                        });
            }
        }
        root.timers = kept;
        if (finished)
            root.schedulePersist();
    }

    function finish(t: var): void {
        Toaster.toast(Tr.tr("Timer finished"), t.label || Tr.tr("Time's up"), "timer");
        Quickshell.execDetached(["sh", "-c", "paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || canberra-gtk-play -i complete 2>/dev/null || true"]);
    }

    function restore(data: var): void {
        const now = Date.now();
        const kept = [];
        let maxId = 0;
        const entries = data?.timers ?? [];
        for (const t of entries) {
            const id = Number(t.id) || 0;
            maxId = Math.max(maxId, id);
            const endAt = Number(t.endAt) || 0;
            const remaining = endAt - now;
            const entry = {
                id: id,
                label: t.label || Tr.tr("Time's up"),
                durationMs: Number(t.durationMs) || 0,
                endAt: endAt,
                remainingMs: remaining
            };
            if (!root.enabled)
                continue;
            if (remaining <= 0)
                root.finish(entry);
            else
                kept.push(entry);
        }
        root.nextId = Math.max(Number(data?.nextId) || 1, maxId + 1);
        root.timers = root.enabled ? kept : [];
        root.loaded = true;
        root.schedulePersist();
    }

    Connections {
        target: GlobalConfig.addons.timers

        function onEnabledChanged(): void {
            if (!root.enabled)
                root.clearAll();
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/timers.json`
        onLoaded: {
            try {
                root.restore(JSON.parse(text()));
            } catch (e) {
                console.warn(`Unable to parse timers.json: ${e}`);
                root.loaded = true;
                root.schedulePersist();
            }
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => root.persist());
            else
                console.warn(`Unable to load timers.json: ${err}`);
        }
    }
}
