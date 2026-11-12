pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    readonly property string dir: `${Paths.state}/notch`
    readonly property var defaults: ({
            mascot: true,
            mascotKind: "knight",
            mascotRandom: true,
            mascotTracking: true,
            mascotReactions: true,
            minimal: false,
            scale: 1,
            twelveHour: false,
            showDate: true,
            lyrics: false,
            mascotDelay: 2,
            dozeDelay: 10,
            pomodoroFocus: 25,
            pomodoroBreak: 5,
            snoozeMinutes: 10,
            osdDuration: 1800,
            osdVolume: true,
            osdMicrophone: true,
            osdBrightness: true,
            osdCapsLock: true,
            osdKbLayout: true,
            osdCharger: true,
            autoPowerProfile: true,
            osdBattery: true,
            osdWifi: true,
            osdBluetooth: true,
            notifsInNotch: true,
            nextEvent: true,
            nextEventLead: 20,
            agentOsd: true,
            agentAlerts: true,
            animBench: true,
            animWeather: true,
            animSeasons: true,
            animTyping: true,
            animGoo: true
        })
    property var values: defaults

    readonly property bool mascot: values.mascot
    // knight, grimm or hornet; the Knight gives way to Grimm while his troupe is in town
    readonly property string mascotKind: values.mascotKind === "knight" && Season.current === "grimm" ? "grimm" : values.mascotKind
    readonly property bool minimal: values.minimal
    readonly property real scale: values.scale
    readonly property bool twelveHour: values.twelveHour
    readonly property bool showDate: values.showDate
    readonly property bool lyrics: values.lyrics
    readonly property int mascotDelay: values.mascotDelay
    readonly property int dozeDelay: values.dozeDelay
    readonly property int pomodoroFocus: values.pomodoroFocus
    readonly property int pomodoroBreak: values.pomodoroBreak
    readonly property int snoozeMinutes: values.snoozeMinutes
    readonly property int osdDuration: values.osdDuration

    function set(key: string, value: var): void {
        if (values[key] === value)
            return;
        const next = Object.assign({}, values);
        next[key] = value;
        values = next;
        saveTimer.restart();
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    Timer {
        id: saveTimer

        interval: 300
        onTriggered: file.setText(JSON.stringify(root.values, null, 2))
    }

    FileView {
        id: file

        path: `${root.dir}/config.json`
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            try {
                root.values = Object.assign({}, root.defaults, JSON.parse(text()));
            } catch (e) {
                root.values = root.defaults;
            }
        }
    }
}
