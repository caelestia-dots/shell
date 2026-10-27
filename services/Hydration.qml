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

    readonly property bool enabled: GlobalConfig.addons.hydration.enabled
    readonly property int dailyGoalMl: Math.max(1, GlobalConfig.addons.hydration.dailyGoalMl)
    readonly property int reminderMinutes: Math.max(1, GlobalConfig.addons.hydration.reminderMinutes)
    readonly property list<int> presets: [
        Math.max(1, GlobalConfig.addons.hydration.presetMl0),
        Math.max(1, GlobalConfig.addons.hydration.presetMl1),
        Math.max(1, GlobalConfig.addons.hydration.presetMl2),
        Math.max(1, GlobalConfig.addons.hydration.presetMl3)
    ]

    property string dateKey: ""
    property int drunkMl: 0
    property real lastAddAt: 0
    property real lastRemindAt: 0
    property int lastAddedMl: 0
    property bool loaded: false
    property var activeReminder: null

    readonly property real progress: Math.min(1, drunkMl / dailyGoalMl)
    readonly property int remainingMl: Math.max(0, dailyGoalMl - drunkMl)
    readonly property bool goalReached: drunkMl >= dailyGoalMl

    readonly property Timer saveTimer: Timer {
        interval: 200
        onTriggered: root.persist()
    }

    readonly property Timer dayTimer: Timer {
        interval: 30000
        running: root.enabled
        repeat: true
        onTriggered: root.ensureToday()
    }

    readonly property Timer reminderTimer: Timer {
        interval: 15000
        running: root.enabled && root.loaded && !root.goalReached
        repeat: true
        onTriggered: root.maybeRemind()
    }

    function setEnabled(on: bool): void {
        if (GlobalConfig.addons.hydration.enabled === on)
            return;
        GlobalConfig.addons.hydration.enabled = on;
    }

    function setDailyGoal(ml: int): void {
        GlobalConfig.addons.hydration.dailyGoalMl = Math.max(1, Math.round(ml));
    }

    function setReminderMinutes(mins: int): void {
        GlobalConfig.addons.hydration.reminderMinutes = Math.max(1, Math.round(mins));
    }

    function setPreset(index: int, ml: int): void {
        const v = Math.max(1, Math.round(ml));
        if (index === 0)
            GlobalConfig.addons.hydration.presetMl0 = v;
        else if (index === 1)
            GlobalConfig.addons.hydration.presetMl1 = v;
        else if (index === 2)
            GlobalConfig.addons.hydration.presetMl2 = v;
        else if (index === 3)
            GlobalConfig.addons.hydration.presetMl3 = v;
    }

    function todayKey(): string {
        const d = new Date();
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, "0");
        const day = String(d.getDate()).padStart(2, "0");
        return `${y}-${m}-${day}`;
    }

    function ensureToday(): void {
        const key = root.todayKey();
        if (root.dateKey === key)
            return;
        root.dateKey = key;
        root.drunkMl = 0;
        root.lastAddedMl = 0;
        root.lastAddAt = Date.now();
        root.dismissReminder();
        root.schedulePersist();
    }

    function schedulePersist(): void {
        if (root.loaded)
            saveTimer.restart();
    }

    function persist(): void {
        if (!root.loaded)
            return;
        storage.setText(JSON.stringify({
                    dateKey: root.dateKey,
                    drunkMl: root.drunkMl,
                    lastAddAt: root.lastAddAt,
                    lastAddedMl: root.lastAddedMl
                }));
    }

    function addMl(amount: int): void {
        if (!root.enabled)
            return;
        root.ensureToday();
        const ml = Math.max(0, Math.round(amount));
        if (ml <= 0)
            return;
        root.drunkMl += ml;
        root.lastAddedMl = ml;
        root.lastAddAt = Date.now();
        root.dismissReminder();
        root.schedulePersist();
    }

    function removeMl(amount: int): void {
        if (!root.enabled)
            return;
        root.ensureToday();
        const ml = Math.max(0, Math.round(amount));
        if (ml <= 0 || root.drunkMl <= 0)
            return;
        const removed = Math.min(ml, root.drunkMl);
        root.drunkMl -= removed;
        root.lastAddedMl = 0;
        root.lastAddAt = Date.now();
        root.dismissReminder();
        root.schedulePersist();
    }

    function undoLast(): void {
        if (!root.enabled || root.lastAddedMl <= 0)
            return;
        root.ensureToday();
        root.drunkMl = Math.max(0, root.drunkMl - root.lastAddedMl);
        root.lastAddedMl = 0;
        root.lastAddAt = Date.now();
        root.schedulePersist();
    }

    function dismissReminder(): void {
        if (root.activeReminder) {
            try {
                root.activeReminder.close();
            } catch (e) {}
            root.activeReminder = null;
        }
    }

    function reminderStillOpen(): bool {
        const n = root.activeReminder;
        if (!n)
            return false;
        try {
            if (n.closed || !Notifs.list.includes(n)) {
                root.activeReminder = null;
                return false;
            }
            return !!n.popup;
        } catch (e) {
            root.activeReminder = null;
            return false;
        }
    }

    function maybeRemind(): void {
        if (!root.enabled || root.goalReached)
            return;
        root.ensureToday();
        if (root.reminderStillOpen())
            return;

        const windowMs = root.reminderMinutes * 60000;
        const now = Date.now();
        if (now - (root.lastAddAt || now) < windowMs)
            return;
        if (root.lastRemindAt && now - root.lastRemindAt < windowMs)
            return;

        root.showReminder();
    }

    function showReminder(): void {
        root.dismissReminder();
        root.lastRemindAt = Date.now();

        const p2 = root.presets[2] || 250;
        const p3 = root.presets[3] || 500;
        const notif = Notifs.pushLocal({
                notificationId: "local:hydration",
                summary: Tr.tr("Time to drink water"),
                body: Tr.tr("%1 / %2 ml — tap an amount to log it").arg(root.drunkMl).arg(root.dailyGoalMl),
                appName: Tr.tr("Hydration"),
                appIcon: "",
                expireTimeout: Math.max(8000, GlobalConfig.notifs.defaultExpireTimeout),
                resident: false,
                actions: []
            });

        notif.actions = [
            {
                identifier: "add-mid",
                text: `+${p2} ml`,
                invoke: () => {
                    root.addMl(p2);
                    notif.close();
                }
            },
            {
                identifier: "add-large",
                text: `+${p3} ml`,
                invoke: () => {
                    root.addMl(p3);
                    notif.close();
                }
            }
        ];
        root.activeReminder = notif;
    }

    function restore(data: var): void {
        const key = root.todayKey();
        const savedKey = data?.dateKey || "";
        if (savedKey === key) {
            root.dateKey = key;
            root.drunkMl = Math.max(0, Number(data.drunkMl) || 0);
            root.lastAddAt = Number(data.lastAddAt) || Date.now();
            root.lastAddedMl = Math.max(0, Number(data.lastAddedMl) || 0);
        } else {
            root.dateKey = key;
            root.drunkMl = 0;
            root.lastAddedMl = 0;
            root.lastAddAt = Date.now();
        }
        root.loaded = true;
        root.schedulePersist();
    }

    Connections {
        target: GlobalConfig.addons.hydration

        function onEnabledChanged(): void {
            if (!root.enabled)
                root.dismissReminder();
            else {
                root.ensureToday();
                if (!root.lastAddAt)
                    root.lastAddAt = Date.now();
            }
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/hydration.json`
        onLoaded: {
            try {
                root.restore(JSON.parse(text()));
            } catch (e) {
                console.warn(`Unable to parse hydration.json: ${e}`);
                root.dateKey = root.todayKey();
                root.lastAddAt = Date.now();
                root.loaded = true;
                root.schedulePersist();
            }
        }
        onLoadFailed: err => {
            root.dateKey = root.todayKey();
            root.lastAddAt = Date.now();
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => root.persist());
            else
                console.warn(`Unable to load hydration.json: ${err}`);
        }
    }
}
