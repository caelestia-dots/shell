pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n

// Calendar events backed by khal (https://khal.readthedocs.io). Events live as .ics files in khal's
// calendars, so events added with the khal CLI show up here too.
Singleton {
    id: root

    readonly property string fieldSep: "\x1f"
    readonly property string recordSep: "\x1e"
    readonly property string dayMarker: "\x1d"

    property bool available: false
    property bool loading: false

    // Qt date/time formats equivalent to khal's configured [locale] formats. khal only accepts and
    // prints dates in those formats, so we derive them from `khal printformats`.
    property string dateFormat: "dd/MM/yyyy"
    property string longDateFormat: "dd/MM/yyyy"
    property string timeFormat: "HH:mm"
    property bool formatsReady: false

    // "yyyy-MM-dd" -> list of events for that day
    property var byDay: ({})

    // Date ranges requested by each view (key -> { start, end }); the union of them is loaded
    property var ranges: ({})
    property bool reloadPending: false

    readonly property string removeScript: `
import sys, os
from khal.settings import get_config
uid = sys.argv[1]
removed = 0
for cal in get_config()["calendars"].values():
    path = os.path.expanduser(cal["path"])
    for root, _, files in os.walk(path):
        for f in files:
            if not f.endswith(".ics"):
                continue
            p = os.path.join(root, f)
            with open(p, encoding="utf-8", errors="ignore") as fh:
                # Unfold continuation lines before matching
                content = fh.read().replace("\\r\\n ", "").replace("\\n ", "")
            if any(l.strip() == "UID:" + uid for l in content.splitlines()):
                os.remove(p)
                removed += 1
if not removed:
    sys.exit("Event not found")
`

    signal changed

    function dayKey(date: date): string {
        return Qt.formatDate(date, "yyyy-MM-dd");
    }

    function eventsOn(date: date): list<var> {
        return byDay[dayKey(date)] ?? [];
    }

    // Loads the visible span of a month grid (6 weeks around the given month)
    function loadMonth(year: int, month: int, key = "calendar"): void {
        const start = new Date(year, month, 1);
        start.setDate(start.getDate() - 7);
        const end = new Date(year, month + 1, 1);
        end.setDate(end.getDate() + 14);
        loadRange(key, start, end);
    }

    function loadRange(key: string, start: date, end: date): void {
        const prev = ranges[key];
        if (prev && dayKey(prev.start) === dayKey(start) && dayKey(prev.end) === dayKey(end))
            return;

        const newRanges = Object.assign({}, ranges);
        newRanges[key] = {
            start,
            end
        };
        ranges = newRanges;
        reload();
    }

    function reload(): void {
        const keys = Object.keys(ranges);
        if (!available || !formatsReady || keys.length === 0)
            return;

        // Don't change the command under a running process, rerun once it finishes instead
        if (listProc.running) {
            reloadPending = true;
            return;
        }

        const start = new Date(Math.min(...keys.map(k => ranges[k].start.getTime())));
        const end = new Date(Math.max(...keys.map(k => ranges[k].end.getTime())));

        listProc.command = ["khal", "list", "--day-format", `${dayMarker}{date}${recordSep}`, "--format", ["{uid}", "{title}", "{all-day}", "{start-time}", "{end-time}", "{repeat-pattern}", "{location}", "{description}", "{calendar}", "{calendar-color}"].join(fieldSep) + recordSep, Qt.formatDate(start, dateFormat), Qt.formatDate(end, dateFormat)];
        listProc.running = true;
        loading = true;
    }

    // event: { title, date, allDay, start: "HH:mm", end: "HH:mm", weekly, until: date | null, location, description }
    function add(event: var): void {
        const cmd = ["khal", "new"];

        if (event.location)
            cmd.push("--location", event.location);

        if (event.weekly) {
            cmd.push("--repeat", "weekly");
            if (event.until) {
                // khal ends the rule at the start of the until day, which would drop an occurrence on that
                // very day, so end it a day later to make the end date inclusive
                const until = new Date(event.until);
                until.setDate(until.getDate() + 1);
                cmd.push("--until", Qt.formatDate(until, dateFormat));
            }
        }

        // Positional args after `--` so titles starting with a dash aren't taken as options
        cmd.push("--", Qt.formatDate(event.date, dateFormat));
        if (!event.allDay)
            cmd.push(toKhalTime(event.start), toKhalTime(event.end));

        cmd.push(event.title);
        if (event.description)
            cmd.push("::", event.description);

        writeProc.errorTitle = Tr.tr("Failed to add event");
        writeProc.successTitle = "";
        writeProc.command = cmd;
        writeProc.running = true;
    }

    // Removes the whole event (all occurrences if it repeats)
    function remove(uid: string): void {
        writeProc.errorTitle = Tr.tr("Failed to delete event");
        writeProc.successTitle = "";
        writeProc.command = ["python3", "-c", removeScript, uid];
        writeProc.running = true;
    }

    // Edits an event in place (the whole series if it repeats), keeping what the form doesn't show.
    // event: like add(), plus untilChanged; date null keeps the current start day (used for series)
    function update(uid: string, event: var): void {
        const payload = {
            title: event.title,
            date: event.date ? Qt.formatDate(event.date, "yyyy-MM-dd") : null,
            allDay: event.allDay,
            start: event.start,
            end: event.end,
            repeat: event.weekly,
            until: event.until ? Qt.formatDate(event.until, "yyyy-MM-dd") : "",
            untilChanged: event.untilChanged,
            location: event.location,
            description: event.description
        };
        writeProc.errorTitle = Tr.tr("Failed to edit event");
        writeProc.successTitle = "";
        writeProc.command = ["python3", Quickshell.shellPath("assets/edit-event.py"), uid, JSON.stringify(payload)];
        writeProc.running = true;
    }

    // Imports all events of an .ics file into the default calendar. Events already imported (same UID)
    // are updated instead of duplicated, so re-importing an updated schedule is safe. The file is
    // cleaned up first (see assets/import-ics.py) since some exporters produce files khal rejects.
    function importFile(path: string): void {
        path = decodeURIComponent(path.replace(/^file:\/\//, ""));
        writeProc.errorTitle = Tr.tr("Failed to import schedule");
        writeProc.successTitle = Tr.tr("Schedule imported");
        writeProc.importName = path.split("/").pop();
        writeProc.command = ["python3", Quickshell.shellPath("assets/import-ics.py"), path];
        writeProc.running = true;
    }

    function toKhalTime(time: string): string {
        const [h, m] = time.split(":").map(n => parseInt(n));
        return Qt.formatTime(new Date(2000, 0, 1, h, m), timeFormat);
    }

    function fromKhalTime(time: string): string {
        if (!time)
            return "";
        const parsed = Date.fromLocaleTimeString(Qt.locale(), time, timeFormat);
        return isNaN(parsed) ? time : Qt.formatTime(parsed, "HH:mm");
    }

    // Converts a strftime sample from `khal printformats` (rendered from 2013-12-21 21:45) to a Qt format
    function sampleToQtFormat(sample: string, isTime: bool): string {
        const tokens = isTime ? {
            "21": "HH",
            "09": "hh",
            "9": "h",
            "45": "mm",
            "PM": "AP",
            "pm": "ap"
        } : {
            "2013": "yyyy",
            "Saturday": "dddd",
            "Sat": "ddd",
            "December": "MMMM",
            "Dec": "MMM",
            "13": "yy",
            "12": "MM",
            "21": "dd"
        };
        const re = new RegExp(Object.keys(tokens).join("|"), "g");

        let out = "";
        let last = 0;
        const literal = s => /[a-zA-Z']/.test(s) ? `'${s.replace(/'/g, "''")}'` : s;
        let m;
        while ((m = re.exec(sample)) !== null) {
            out += literal(sample.slice(last, m.index)) + tokens[m[0]];
            last = m.index + m[0].length;
        }
        return out + literal(sample.slice(last));
    }

    function parseList(text: string): void {
        const days = {};
        const dateFormats = [dateFormat, longDateFormat];
        let current = null;

        for (let record of text.split(recordSep)) {
            record = record.replace(/^\n+/, "");
            if (!record)
                continue;

            if (record.startsWith(dayMarker)) {
                const str = record.slice(1).trim();
                current = null;
                for (const fmt of dateFormats) {
                    const d = Date.fromLocaleDateString(Qt.locale(), str, fmt);
                    if (!isNaN(d)) {
                        current = dayKey(d);
                        break;
                    }
                }
                if (current && !days[current])
                    days[current] = [];
                continue;
            }

            if (!current)
                continue;

            const [uid, title, allDay, start, end, repeat, location, description, calendar, colour] = record.split(fieldSep);
            days[current].push({
                uid,
                title,
                allDay: allDay === "True",
                start: fromKhalTime(start),
                end: fromKhalTime(end),
                recurring: !!repeat,
                repeat,
                until: parseUntil(repeat),
                location,
                description,
                calendar,
                colour: colour || ""
            });
        }

        for (const k in days)
            days[k].sort((a, b) => (b.allDay - a.allDay) || a.start.localeCompare(b.start));

        byDay = days;
        loading = false;
        changed();
    }

    function parseUntil(rrule: string): var {
        const m = rrule?.match(/UNTIL=(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z?))?/);
        if (!m)
            return null;

        const [y, mo, d, h, mi, s] = m.slice(1, 7).map(n => parseInt(n ?? "0"));
        const until = m[7] ? new Date(Date.UTC(y, mo - 1, d, h, mi, s)) : new Date(y, mo - 1, d, h, mi, s);
        // khal (and add()) end the rule at local midnight of the day after the last one
        if (m[4] && until.getHours() === 0 && until.getMinutes() === 0)
            until.setDate(until.getDate() - 1);
        return new Date(until.getFullYear(), until.getMonth(), until.getDate());
    }

    Component.onCompleted: checkProc.running = true

    Process {
        id: checkProc

        command: ["sh", "-c", "command -v khal >/dev/null && khal printformats"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const get = key => lines.find(l => l.startsWith(key + ": "))?.slice(key.length + 2);

                const date = get("dateformat");
                if (date === undefined)
                    return;

                root.dateFormat = root.sampleToQtFormat(date, false);
                root.longDateFormat = root.sampleToQtFormat(get("longdateformat") ?? date, false);
                root.timeFormat = root.sampleToQtFormat(get("timeformat") ?? "21:45", true);
                root.available = true;
                root.formatsReady = true;
                root.reload();
            }
        }
    }

    Process {
        id: listProc

        stdout: StdioCollector {
            onStreamFinished: root.parseList(text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.warn("[Events] khal list:", text.trim());
            }
        }
        onExited: {
            root.loading = false;
            if (root.reloadPending) {
                root.reloadPending = false;
                root.reload();
            }
        }
    }

    Process {
        id: writeProc

        property string errorTitle
        property string successTitle
        property string importName

        stdout: StdioCollector {
            id: writeOut
        }
        stderr: StdioCollector {
            id: writeErr
        }
        onExited: code => {
            if (code !== 0) {
                Toaster.toast(writeProc.errorTitle, writeErr.text.trim().split("\n").pop() || Tr.tr("Unknown error"), "event_busy");
                return;
            }
            if (writeProc.successTitle)
                Toaster.toast(writeProc.successTitle, Tr.tr("Imported %1 events from %2").arg(writeOut.text.trim()).arg(writeProc.importName), "event_available");
            root.reload();
        }
    }

    // Pick up external changes (e.g. events added with the khal CLI)
    Timer {
        running: root.available
        repeat: true
        interval: 15 * 60 * 1000
        onTriggered: root.reload()
    }
}
