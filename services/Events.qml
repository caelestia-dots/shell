pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property var eventsData: ({})
    property bool loaded: false

    function formatDateKey(date: var): string {
        if (!date)
            return "";
        if (typeof date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(date))
            return date;
        const d = date instanceof Date ? date : new Date(date);
        if (isNaN(d.getTime()))
            return "";
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${y}-${m}-${day}`;
    }

    function getEvents(dateKey: string): var {
        return root.eventsData[dateKey] ?? [];
    }

    function hasEvents(dateKey: string): bool {
        return (root.eventsData[dateKey]?.length ?? 0) > 0;
    }

    function addEvent(dateKey: string, time: string, title: string, description: string): void {
        const id = "evt_" + Date.now() + "_" + Math.floor(Math.random() * 1000);
        const newEvent = {
            id: id,
            date: dateKey,
            time: time || "",
            title: title || "",
            description: description || "",
            createdAt: Date.now()
        };

        let current = Object.assign({}, root.eventsData);
        if (!current[dateKey])
            current[dateKey] = [];
        current[dateKey] = [...current[dateKey], newEvent];
        root.eventsData = current;
        save();
    }

    function updateEvent(id: string, time: string, title: string, description: string): void {
        let current = Object.assign({}, root.eventsData);
        let found = false;

        for (const k in current) {
            const list = current[k];
            const idx = list.findIndex(e => e.id === id);
            if (idx !== -1) {
                const updated = Object.assign({}, list[idx], {
                    time: time || "",
                    title: title || "",
                    description: description || ""
                });
                current[k] = [...list.slice(0, idx), updated, ...list.slice(idx + 1)];
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
        let current = Object.assign({}, root.eventsData);
        let found = false;

        for (const k in current) {
            const list = current[k];
            const filtered = list.filter(e => e.id !== id);
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

    function save(): void {
        storage.setText(JSON.stringify(root.eventsData, null, 2));
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.config}/events.json`

        onLoaded: {
            try {
                const raw = text();
                root.eventsData = raw ? JSON.parse(raw) : {};
            } catch (e) {
                root.eventsData = {};
            }
            root.loaded = true;
        }

        onLoadFailed: err => {
            root.eventsData = {};
            root.loaded = true;
            if (err === FileViewError.FileNotFound) {
                Qt.callLater(() => setText("{}"));
            }
        }
    }
}
