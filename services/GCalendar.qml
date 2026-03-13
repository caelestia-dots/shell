pragma Singleton

import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool enabled: Config.services.calendar.enabled

    property list<var> events: []
    readonly property var eventDateSet: {
        const s = new Set();
        for (const ev of events)
            s.add(ev.dateKey);
        return s;
    }
    readonly property list<var> upcoming: {
        const now = Date.now();
        const cutoff = now + Config.services.calendar.upcomingHours * 3600000;
        return events.filter(ev => {
            const t = ev.startTime;
            return t >= now && t < cutoff;
        });
    }

    property var notifiedSet: new Set()

    function hasEvent(date: date): bool {
        if (!enabled)
            return false;
        const y = date.getUTCFullYear();
        const m = String(date.getUTCMonth() + 1).padStart(2, "0");
        const d = String(date.getUTCDate()).padStart(2, "0");
        return eventDateSet.has(`${y}-${m}-${d}`);
    }

    function formatTime(isoStr: string): string {
        if (!isoStr || isoStr.length === 10)
            return qsTr("All day");
        const d = new Date(isoStr);
        return Config.services.useTwelveHourClock
            ? Qt.formatDateTime(d, "h:mm AP")
            : Qt.formatDateTime(d, "hh:mm");
    }

    function formatEventTime(ev: var): string {
        let parts = [];
        if (Config.services.calendar.upcomingHours > 24) {
            const d = new Date(ev.start);
            const target = ev.isAllDay ? new Date(ev.start + "T00:00:00") : d;
            const now = new Date();
            const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
            const dayAfter = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 2);
            if (target >= now && target < tomorrow)
                parts.push(qsTr("Today"));
            else if (target >= tomorrow && target < dayAfter)
                parts.push(qsTr("Tomorrow"));
            else
                parts.push(Qt.formatDateTime(target, "ddd, MMM d"));
        }
        parts.push(formatTime(ev.start));
        return parts.join(" · ");
    }

    function parseEvents(data: var): list<var> {
        const parsed = [];
        for (const ev of data) {
            const startStr = ev.start ?? "";
            const startDate = new Date(startStr);
            const isAllDay = startStr.length === 10;
            let dateKey;
            if (isAllDay) {
                dateKey = startStr;
            } else {
                const y = startDate.getFullYear();
                const m = String(startDate.getMonth() + 1).padStart(2, "0");
                const d = String(startDate.getDate()).padStart(2, "0");
                dateKey = `${y}-${m}-${d}`;
            }
            parsed.push({
                summary: ev.summary ?? "",
                start: startStr,
                end: ev.end ?? "",
                location: ev.location ?? "",
                calendar: ev.calendar ?? "",
                startTime: startDate.getTime(),
                dateKey: dateKey,
                isAllDay: isAllDay
            });
        }
        parsed.sort((a, b) => a.startTime - b.startTime);
        return parsed;
    }

    function saveCache(): void {
        cache.setText(JSON.stringify(root.events.map(ev => ({
            summary: ev.summary,
            start: ev.start,
            end: ev.end,
            location: ev.location,
            calendar: ev.calendar
        }))));
    }

    function fetch(): void {
        if (!enabled)
            return;
        fetchProc.running = true;
    }

    // Load cached events on startup
    FileView {
        id: cache

        path: `${Paths.state}/gcalendar.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (root.events.length === 0)
                    root.events = root.parseEvents(data);
            } catch (e) {
                // Ignore corrupt cache
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                setText("[]");
        }
    }

    Process {
        id: fetchProc

        command: [
            Config.services.calendar.command, "calendar", "+agenda",
            "--days", String(Config.services.calendar.agendaDays),
            "--format", "json"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const json = JSON.parse(text);
                    root.events = root.parseEvents(json.events ?? []);
                    root.saveCache();
                } catch (e) {
                    console.warn("GCalendar: failed to parse gws output:", e);
                }
            }
        }
    }

    // Check for reminders
    Timer {
        interval: 30000
        running: root.enabled && Config.services.calendar.reminderMinutes > 0
        repeat: true
        onTriggered: {
            const now = Date.now();
            const reminderMs = Config.services.calendar.reminderMinutes * 60000;
            for (const ev of root.events) {
                if (ev.isAllDay)
                    continue;
                const diff = ev.startTime - now;
                if (diff > 0 && diff <= reminderMs + 60000 && diff > reminderMs - 60000) {
                    const key = ev.summary + ev.start;
                    if (!root.notifiedSet.has(key)) {
                        root.notifiedSet.add(key);
                        const timeStr = root.formatTime(ev.start);
                        Quickshell.execDetached([
                            "notify-send", "-a", "caelestia-shell",
                            "-u", "normal",
                            "-i", "calendar",
                            ev.summary,
                            `Starts at ${timeStr}${ev.location ? " - " + ev.location : ""}`
                        ]);
                    }
                }
            }
        }
    }

    // Periodic refresh
    Timer {
        interval: Config.services.calendar.refreshInterval * 1000
        running: root.enabled
        repeat: true
        onTriggered: root.fetch()
    }

    // Initial fetch (refreshes cache in background)
    Component.onCompleted: fetch()
}
