pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.services
import qs.utils

Singleton {
    id: root

    property var eventsData: ({})
    property bool loaded: false
    property bool dirty: false
    property bool loadFailed: false
    property int loadRetryCount: 0
    property var rangeIndex: {
        const idx = {};
        const data = root.eventsData;
        if (data && typeof data === "object") {
            for (const startKey in data) {
                const list = data[startKey];
                if (!Array.isArray(list))
                    continue;
                for (const evt of list) {
                    if (!evt || !evt.date)
                        continue;
                    const s = evt.date;
                    const e = evt.endDate && evt.endDate >= s ? evt.endDate : s;
                    if (s === e) {
                        if (!idx[s])
                            idx[s] = [];
                        idx[s].push(evt);
                    } else {
                        let cur = new Date(s + "T12:00:00");
                        const end = new Date(e + "T12:00:00");
                        let count = 0;
                        while (cur <= end && count <= 366) {
                            const k = formatDateKey(cur);
                            if (!idx[k])
                                idx[k] = [];
                            idx[k].push(evt);
                            cur.setDate(cur.getDate() + 1);
                            count++;
                        }
                    }
                }
            }
            for (const k in idx) {
                idx[k] = root.sortEvents(idx[k], k);
            }
        }
        return idx;
    }

    function parseTimeToMinutes(t: var): int {
        if (!t || typeof t !== "string")
            return -1;
        const str = t.trim();
        if (!str)
            return -1;

        const match12 = str.match(/^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$/i);
        if (match12) {
            let h = parseInt(match12[1], 10);
            const m = match12[2] ? parseInt(match12[2], 10) : 0;
            if (h < 1 || h > 12 || m < 0 || m > 59)
                return -1;
            const isPm = match12[3].toLowerCase() === "pm";
            if (h === 12) {
                h = isPm ? 12 : 0;
            } else if (isPm) {
                h += 12;
            }
            return h * 60 + m;
        }

        const match24 = str.match(/^(\d{1,2}):(\d{2})$/);
        if (match24) {
            const h = parseInt(match24[1], 10);
            const m = parseInt(match24[2], 10);
            if (h >= 0 && h < 24 && m >= 0 && m < 60)
                return h * 60 + m;
        }

        return -1;
    }

    function getEventTier(evt: var, dayKey: string): int {
        if (!evt || !dayKey)
            return 1;
        const isRange = Boolean(evt.endDate && evt.endDate > evt.date);
        if (!isRange)
            return 1;
        if (evt.endDate === dayKey)
            return 0;
        if (evt.date === dayKey)
            return 2;
        return 1;
    }

    function sortEvents(list: var, dayKey: var): var {
        if (!Array.isArray(list))
            return [];
        return [...list].sort((a, b) => {
            if (dayKey) {
                const tierA = root.getEventTier(a, dayKey);
                const tierB = root.getEventTier(b, dayKey);
                if (tierA !== tierB)
                    return tierA - tierB;
            }

            const tA = parseTimeToMinutes(a?.time);
            const tB = parseTimeToMinutes(b?.time);

            if (tA !== -1 && tB !== -1) {
                if (tA !== tB)
                    return tA - tB;
            } else if (tA !== -1 && tB === -1) {
                return -1;
            } else if (tA === -1 && tB !== -1) {
                return 1;
            } else {
                const hasA = Boolean(a?.time && a.time.trim());
                const hasB = Boolean(b?.time && b.time.trim());
                if (hasA && !hasB)
                    return -1;
                if (!hasA && hasB)
                    return 1;
                if (hasA && hasB) {
                    const strCmp = a.time.localeCompare(b.time);
                    if (strCmp !== 0)
                        return strCmp;
                }
            }

            const aIsRange = Boolean(a?.endDate && a.endDate > a?.date);
            const bIsRange = Boolean(b?.endDate && b.endDate > b?.date);
            if (aIsRange !== bIsRange)
                return aIsRange ? -1 : 1;

            return (a?.title ?? "").localeCompare(b?.title ?? "");
        });
    }

    function formatDateKey(date: var): string {
        if (!date)
            return "";
        if (typeof date === "string") {
            const match = date.match(/^(\d{4})-(\d{1,2})-(\d{1,2})/);
            if (match) {
                const y = match[1];
                const m = match[2].padStart(2, "0");
                const d = match[3].padStart(2, "0");
                return `${y}-${m}-${d}`;
            }
        }
        const d = date instanceof Date ? date : new Date(date);
        if (isNaN(d.getTime()))
            return "";
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, "0");
        const day = String(d.getDate()).padStart(2, "0");
        return `${y}-${m}-${day}`;
    }

    function cleanText(text: var, maxLen: int): string {
        if (!text)
            return "";
        return String(text).replace(/\s+/g, " ").trim().slice(0, maxLen);
    }

    function ensureLoaded(): void {
        if (root.loaded)
            return;
        try {
            const raw = storage.text();
            if (raw) {
                const parsed = JSON.parse(raw);
                if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
                    root.eventsData = parsed;
                } else {
                    root.eventsData = {};
                }
                root.loaded = true;
            }
        } catch (e) {
            // Keep waiting for onLoaded / onLoadFailed
        }
    }

    function getEvents(dateKey: string): var {
        const key = formatDateKey(dateKey);
        if (!key)
            return [];
        ensureLoaded();
        return root.rangeIndex[key] ?? [];
    }

    function hasEvents(dateKey: string): bool {
        const key = formatDateKey(dateKey);
        if (!key)
            return false;
        ensureLoaded();
        return (root.rangeIndex[key]?.length ?? 0) > 0;
    }

    function getRangesForMonth(year: int, month: int): var {
        ensureLoaded();
        const ranges = [];
        const data = root.eventsData;
        const monthStart = `${year}-${String(month + 1).padStart(2, "0")}-01`;
        const lastDay = new Date(year, month + 1, 0).getDate();
        const monthEnd = `${year}-${String(month + 1).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;

        for (const k in data) {
            const list = data[k];
            if (!Array.isArray(list))
                continue;
            for (const evt of list) {
                if (!evt || !evt.date)
                    continue;
                if (evt.endDate && evt.endDate > evt.date) {
                    if (evt.date <= monthEnd && evt.endDate >= monthStart) {
                        ranges.push({
                            id: evt.id,
                            startDate: evt.date,
                            endDate: evt.endDate
                        });
                    }
                }
            }
        }
        return ranges;
    }

    function addEvent(dateKey: string, time: string, title: string, description: string, endDateKey: var): void {
        let startKey = formatDateKey(dateKey);
        if (!startKey)
            return;
        let endKey = endDateKey ? formatDateKey(endDateKey) : "";
        if (endKey && endKey < startKey) {
            const temp = startKey;
            startKey = endKey;
            endKey = temp;
        }
        if (endKey && endKey !== startKey) {
            const dStart = new Date(startKey + "T12:00:00");
            const dEnd = new Date(endKey + "T12:00:00");
            const diffDays = Math.round((dEnd.getTime() - dStart.getTime()) / (1000 * 60 * 60 * 24));
            if (diffDays > 366) {
                const clamped = new Date(dStart.getTime() + 366 * 24 * 60 * 60 * 1000);
                endKey = formatDateKey(clamped);
            }
        }
        ensureLoaded();
        const id = "evt_" + Date.now() + "_" + Math.floor(Math.random() * 1000);
        const newEvent = {
            id: id,
            date: startKey,
            endDate: (endKey && endKey !== startKey) ? endKey : undefined,
            time: cleanText(time, 32),
            title: cleanText(title, 200),
            description: cleanText(description, 2000),
            createdAt: Date.now()
        };
        if (!newEvent.endDate)
            delete newEvent.endDate;

        let current = (root.eventsData && typeof root.eventsData === "object" && !Array.isArray(root.eventsData)) ? Object.assign({}, root.eventsData) : {};
        if (!Array.isArray(current[startKey]))
            current[startKey] = [];
        current[startKey] = [...current[startKey], newEvent];
        root.eventsData = current;
        save();
    }

    function updateEvent(id: string, time: string, title: string, description: string, dateKey: var, endDateKey: var): void {
        ensureLoaded();
        let current = (root.eventsData && typeof root.eventsData === "object" && !Array.isArray(root.eventsData)) ? Object.assign({}, root.eventsData) : {};
        let found = false;

        for (const k in current) {
            const list = current[k];
            if (!Array.isArray(list))
                continue;
            const idx = list.findIndex(e => e && e.id === id);
            if (idx !== -1) {
                const existing = list[idx];
                let newStartKey = (dateKey ? formatDateKey(dateKey) : "") || existing.date;
                if (!newStartKey)
                    return;
                let newEndKey = existing.endDate || "";
                if (endDateKey !== undefined) {
                    newEndKey = endDateKey ? formatDateKey(endDateKey) : "";
                }
                if (newEndKey && newEndKey < newStartKey) {
                    const temp = newStartKey;
                    newStartKey = newEndKey;
                    newEndKey = temp;
                }
                if (newEndKey && newEndKey !== newStartKey) {
                    const dStart = new Date(newStartKey + "T12:00:00");
                    const dEnd = new Date(newEndKey + "T12:00:00");
                    const diffDays = Math.round((dEnd.getTime() - dStart.getTime()) / (1000 * 60 * 60 * 24));
                    if (diffDays > 366) {
                        const clamped = new Date(dStart.getTime() + 366 * 24 * 60 * 60 * 1000);
                        newEndKey = formatDateKey(clamped);
                    }
                }

                const updated = Object.assign({}, existing, {
                    date: newStartKey,
                    endDate: (newEndKey && newEndKey !== newStartKey) ? newEndKey : undefined,
                    time: time !== undefined ? cleanText(time, 32) : existing.time,
                    title: title !== undefined ? cleanText(title, 200) : existing.title,
                    description: description !== undefined ? cleanText(description, 2000) : existing.description
                });
                if (!updated.endDate)
                    delete updated.endDate;

                if (newStartKey === k) {
                    current[k] = [...list.slice(0, idx), updated, ...list.slice(idx + 1)];
                } else {
                    const filtered = list.filter(e => e && e.id !== id);
                    if (filtered.length > 0)
                        current[k] = filtered;
                    else
                        delete current[k];
                    if (!Array.isArray(current[newStartKey]))
                        current[newStartKey] = [];
                    current[newStartKey] = [...current[newStartKey], updated];
                }
                found = true;
                break;
            }
        }

        if (found) {
            root.eventsData = current;
            save();
        }
    }

    function deleteEvent(id: string): void {
        ensureLoaded();
        let current = (root.eventsData && typeof root.eventsData === "object" && !Array.isArray(root.eventsData)) ? Object.assign({}, root.eventsData) : {};
        let found = false;

        for (const k in current) {
            const list = current[k];
            if (!Array.isArray(list))
                continue;
            const filtered = list.filter(e => e && e.id !== id);
            if (filtered.length !== list.length) {
                if (filtered.length > 0) {
                    current[k] = filtered;
                } else {
                    delete current[k];
                }
                found = true;
                break;
            }
        }

        if (found) {
            root.eventsData = current;
            save();
        }
    }

    function restoreEvent(eventObj: var): void {
        if (!eventObj || !eventObj.id || !eventObj.date)
            return;
        ensureLoaded();
        const startKey = formatDateKey(eventObj.date);
        if (!startKey)
            return;
        let current = (root.eventsData && typeof root.eventsData === "object" && !Array.isArray(root.eventsData)) ? Object.assign({}, root.eventsData) : {};
        if (!Array.isArray(current[startKey]))
            current[startKey] = [];
        if (!current[startKey].some(e => e && e.id === eventObj.id)) {
            current[startKey] = [...current[startKey], eventObj];
            root.eventsData = current;
            save();
        }
    }

    function checkReminders(): void {
        if (!root.loaded)
            return;
        const now = new Date();
        const todayKey = formatDateKey(now);
        if (!todayKey)
            return;
        const todayEvents = getEvents(todayKey);
        if (!todayEvents || todayEvents.length === 0)
            return;

        const currentHour = now.getHours();
        const currentMin = now.getMinutes();
        const currentTotalMin = currentHour * 60 + currentMin;

        if (reminderProps.lastDailyPingDate !== todayKey && currentHour >= 8) {
            const count = todayEvents.length;
            const title = count === 1 ? Tr.tr("Today: %1").arg(todayEvents[0].title || Tr.tr("Event")) : Tr.tr("Today's Events (%1)").arg(count);
            const maxVisible = 5;
            const visibleEvents = todayEvents.slice(0, maxVisible);
            let body = "";
            if (count === 1) {
                body = todayEvents[0].description ? (todayEvents[0].time ? `${todayEvents[0].time}\n${todayEvents[0].description}` : todayEvents[0].description) : (todayEvents[0].time ?? "");
            } else {
                body = visibleEvents.map(e => (e.time ? `[${e.time}] ` : "") + e.title).join("\n");
                if (todayEvents.length > maxVisible)
                    body += "\n" + Tr.trN("+%n more", "+%n more", todayEvents.length - maxVisible);
            }
            try {
                Notifs.send(title, body, "x-office-calendar", "Calendar");
                reminderProps.lastDailyPingDate = todayKey;
            } catch (e) {
                // Stamping skipped on throw to retry on next tick
            }
        }

        const updatedReminded = {};
        for (const k in reminderProps.remindedEvents) {
            if (k.startsWith(todayKey + "_"))
                updatedReminded[k] = reminderProps.remindedEvents[k];
        }
        let remindedChanged = false;

        for (const evt of todayEvents) {
            if (!evt || !evt.id || !evt.time)
                continue;
            const eventKey = `${todayKey}_${evt.id}_${evt.time}`;
            if (updatedReminded[eventKey])
                continue;

            const evtMin = parseTimeToMinutes(evt.time);
            if (evtMin === -1)
                continue;

            if (currentTotalMin >= evtMin - 10 && currentTotalMin <= evtMin + 5) {
                const title = Tr.tr("Today: %1").arg(evt.title || Tr.tr("Event"));
                const body = evt.description ? `${evt.time}\n${evt.description}` : evt.time;
                try {
                    Notifs.send(title, body, "appointment-soon", "Calendar");
                    updatedReminded[eventKey] = true;
                    remindedChanged = true;
                } catch (e) {
                    // Stamping skipped on throw to retry on next tick
                }
            }
        }

        if (remindedChanged || Object.keys(updatedReminded).length !== Object.keys(reminderProps.remindedEvents ?? {}).length)
            reminderProps.remindedEvents = updatedReminded;
    }

    function save(): void {
        if (!root.loaded) {
            root.dirty = true;
            return;
        }
        if (root.loadFailed) {
            if (root.loadRetryCount < 3) {
                root.loadRetryCount++;
                console.warn(`Events: save() skipped because initial storage load failed; attempting reload (attempt ${root.loadRetryCount}/3)`);
                root.dirty = true;
                storage.reload();
            } else if (root.loadRetryCount === 3) {
                root.loadRetryCount++;
                console.warn("Events: storage reload limit reached (3/3); suspending further retries until session reload");
            }
            return;
        }
        storage.setText(JSON.stringify(root.eventsData, null, 2));
    }

    PersistentProperties {
        id: reminderProps

        property string lastDailyPingDate: ""
        property var remindedEvents: ({})

        reloadableId: "events_reminders"
    }

    Timer {
        id: reminderTimer

        interval: 30000
        repeat: true
        running: root.loaded
        triggeredOnStart: true
        onTriggered: root.checkReminders()
    }

    FileView {
        id: storage

        printErrors: true
        path: `${Paths.config}/events.json`

        onLoaded: {
            root.loadFailed = false;
            root.loadRetryCount = 0;
            try {
                const raw = text();
                let diskData = {};
                if (raw) {
                    const parsed = JSON.parse(raw);
                    if (parsed && typeof parsed === "object" && !Array.isArray(parsed))
                        diskData = parsed;
                }
                if (root.dirty) {
                    const merged = Object.assign({}, diskData);
                    for (const k in root.eventsData) {
                        const inMemoryList = root.eventsData[k];
                        if (!Array.isArray(inMemoryList))
                            continue;
                        if (!merged[k]) {
                            merged[k] = inMemoryList;
                        } else {
                            const existingIds = {};
                            for (let i = 0; i < merged[k].length; ++i) {
                                if (merged[k][i] && merged[k][i].id)
                                    existingIds[merged[k][i].id] = true;
                            }
                            const combined = [...merged[k]];
                            for (let i = 0; i < inMemoryList.length; ++i) {
                                const evt = inMemoryList[i];
                                if (evt && evt.id && !existingIds[evt.id]) {
                                    combined.push(evt);
                                    existingIds[evt.id] = true;
                                }
                            }
                            merged[k] = combined;
                        }
                    }
                    root.eventsData = merged;
                    root.loaded = true;
                    root.dirty = false;
                    save();
                } else if (!root.loaded) {
                    root.eventsData = diskData;
                    root.loaded = true;
                }
            } catch (e) {
                console.error("Events: JSON parse failed, preserving file on disk:", e);
                root.loadFailed = true;
                root.loaded = false;
            }
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loadFailed = false;
                root.loaded = true;
                if (root.dirty) {
                    root.dirty = false;
                    save();
                } else {
                    root.eventsData = {};
                    Qt.callLater(() => storage.setText("{}"));
                }
            } else {
                root.loadFailed = true;
                root.loaded = true;
                console.warn(`Events: failed to load events file: ${err}`);
            }
        }
    }
}
