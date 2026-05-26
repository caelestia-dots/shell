pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config

Singleton {
    id: root

    readonly property var reminders: {
        try {
            return JSON.parse(_store.remindersJson);
        } catch (e) {
            return [];
        }
    }

    property bool reminderFired: false
    property string currentReminderText: ""
    property string currentReminderId: ""

    signal preNotify(string text, int minutesBefore)
    signal fired(string text)

    function addReminder(dateStr: string, timeStr: string, text: string): void {
        const list = _parseList();
        list.push({
            id: Date.now().toString(),
            date: dateStr,
            time: timeStr,
            text: text,
            preNotified: false,
            fired: false
        });
        _store.remindersJson = JSON.stringify(list);
    }

    function removeReminder(id: string): void {
        const list = _parseList().filter(r => r.id !== id);
        _store.remindersJson = JSON.stringify(list);
    }

    function dismissCurrent(): void {
        reminderFired = false;
        currentReminderText = "";
        currentReminderId = "";
    }

    function _parseList(): var {
        try {
            return JSON.parse(_store.remindersJson);
        } catch (e) {
            return [];
        }
    }

    function _check(): void {
        const now = new Date();
        const list = _parseList();
        let changed = false;
        const leadMs = (GlobalConfig.bar.clock.timer?.reminderLeadMinutes ?? 15) * 60 * 1000;

        for (let i = 0; i < list.length; i++) {
            const r = list[i];
            if (r.fired)
                continue;
            const target = new Date(`${r.date}T${r.time}`);
            const diff = target.getTime() - now.getTime();

            if (diff <= 0) {
                list[i].fired = true;
                changed = true;
                root.reminderFired = true;
                root.currentReminderText = r.text;
                root.currentReminderId = r.id;
                root.fired(r.text);
                const sf = GlobalConfig.bar.clock.timer?.soundFile ?? "";
                if (sf.length > 0)
                    Quickshell.execDetached(["paplay", sf]);
            } else if (!r.preNotified && diff <= leadMs) {
                list[i].preNotified = true;
                changed = true;
                root.preNotify(r.text, Math.round(diff / 60000));
                Toaster.toast(qsTr("Reminder"), r.text, "alarm");
            }
        }

        if (changed)
            _store.remindersJson = JSON.stringify(list);
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root._check()
    }

    PersistentProperties {
        id: _store
        reloadableId: "reminders"
        property string remindersJson: "[]"
    }
}
