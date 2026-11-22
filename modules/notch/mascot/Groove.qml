pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Services
import qs.services

// Sways the mascot from side to side on each detected beat.
// `locked` stays true while beats keep coming, so the fixed idle sway can step aside.
Item {
    id: root

    required property Item mascot
    property bool active
    property real side: 1
    readonly property bool locked: active && lockTimer.running

    onActiveChanged: {
        if (!active) {
            sway.stop();
            lockTimer.stop();
            mascot.sway = 0;
        }
    }

    Loader {
        active: root.active

        sourceComponent: ServiceRef {
            service: Audio.beatTracker
        }
    }

    Connections {
        function onBeat(bpm: real): void {
            lockTimer.restart();
            root.side = -root.side;
            // Arrive at the far side right as the next beat lands
            sway.duration = bpm > 0 ? Math.max(220, Math.min(900, 60000 / bpm * 0.95)) : 450;
            sway.to = root.side;
            sway.restart();
        }

        target: root.active ? Audio.beatTracker : null
    }

    NumberAnimation {
        id: sway

        target: root.mascot
        property: "sway"
        easing.type: Easing.InOutSine
    }

    Timer {
        id: lockTimer

        interval: 1600
    }
}
