pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config

Singleton {
    id: root

    property bool active: false
    property int alarmHour: 0
    property int alarmMinute: 0
    property bool alarmFired: false

    readonly property string alarmTimeFormatted: {
        if (!active)
            return "";
        if (GlobalConfig.services.useTwelveHourClock) {
            const h = alarmHour % 12 || 12;
            const suffix = alarmHour < 12 ? "AM" : "PM";
            return `${String(h).padStart(2, "0")}:${String(alarmMinute).padStart(2, "0")} ${suffix}`;
        }
        return `${String(alarmHour).padStart(2, "0")}:${String(alarmMinute).padStart(2, "0")}`;
    }

    signal finished()

    function setAlarm(h: int, m: int): void {
        const now = new Date();
        const target = new Date(now.getFullYear(), now.getMonth(), now.getDate(), h, m, 0, 0);
        if (target.getTime() <= now.getTime())
            target.setDate(target.getDate() + 1);
        alarmHour = h;
        alarmMinute = m;
        _store.targetMs = target.getTime();
        alarmFired = false;
        active = true;
    }

    function cancelAlarm(): void {
        active = false;
        alarmFired = false;
        _store.targetMs = 0;
    }

    onFinished: {
        const sf = GlobalConfig.bar.clock.timer?.soundFile ?? "";
        if (sf.length > 0)
            Quickshell.execDetached(["paplay", sf]);
    }

    Component.onCompleted: {
        if (_store.targetMs > 0 && _store.targetMs > Date.now()) {
            const d = new Date(_store.targetMs);
            alarmHour = d.getHours();
            alarmMinute = d.getMinutes();
            active = true;
        } else {
            _store.targetMs = 0;
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.active

        onTriggered: {
            if (!root.active || root.alarmFired)
                return;
            const now = Date.now();
            if (now >= root._store.targetMs) {
                root.alarmFired = true;
                root.active = false;
                root._store.targetMs = 0;
                root.finished();
            }
        }
    }

    PersistentProperties {
        id: _store
        reloadableId: "alarm"
        property real targetMs: 0
    }
}
