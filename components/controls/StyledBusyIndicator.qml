import qs.config
import QtQuick
import QtQuick.Controls

BusyIndicator {
    id: root

    property real implicitSize: Appearance.font.size.normal * 3
    property real strokeWidth: Appearance.padding.small
    property real internalStrokeWidth: strokeWidth
    property string animState

    padding: 0
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    onRunningChanged: {
        if (running) {
            updater.completeEndProgress = 0;
            animState = "running";
        } else {
            if (animState == "running")
                animState = "completing";
        }
    }

    states: State {
        name: "stopped"
        when: !root.running

        PropertyChanges {
            root.opacity: 0
            root.internalStrokeWidth: root.strokeWidth / 3
        }
    }

    transitions: Transition {
        NumberAnimation {
            properties: "opacity,internalStrokeWidth"
            duration: updater.completeEndDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    background: null

    contentItem: CircularProgress {
        anchors.fill: parent
        strokeWidth: root.internalStrokeWidth
        padding: root.padding
        startAngle: updater.startFraction * 360
        value: updater.endFraction - updater.startFraction
    }

    Updater {
        id: updater
    }

    NumberAnimation {
        running: root.animState !== "stopped"
        loops: Animation.Infinite
        target: updater
        property: "progress"
        from: 0
        to: 1
        duration: updater.duration
    }

    NumberAnimation {
        running: root.animState === "completing"
        target: updater
        property: "completeEndProgress"
        from: 0
        to: 1
        duration: updater.completeEndDuration
        onFinished: {
            if (root.animState === "completing")
                root.animState = "stopped";
        }
    }

    component Updater: QtObject {
        readonly property int duration: 5400 * Appearance.anim.durations.scale
        readonly property int expandDuration: 667 * Appearance.anim.durations.scale
        readonly property int collapseDuration: 667 * Appearance.anim.durations.scale
        readonly property int completeEndDuration: 333 * Appearance.anim.durations.scale
        readonly property int tailDegOffset: -20
        readonly property int extraDegPerCycle: 250
        readonly property int constantRotDeg: 1520
        readonly property list<int> expandDelay: [0, 1350, 2700, 4050].map(d => d * Appearance.anim.durations.scale)
        readonly property list<int> collapseDelay: [667, 2017, 3367, 4717].map(d => d * Appearance.anim.durations.scale)

        property real progress: 0
        property real startFraction: 0
        property real endFraction: 0
        property real rotation: 0
        property real completeEndProgress: 0

        onProgressChanged: update(progress)

        function update(p: real): void {
            const playtime = p * duration;
            let startDeg = constantRotDeg * p + tailDegOffset;
            let endDeg = constantRotDeg * p;

            for (let i = 0; i < 4; i++) {
                const expandFraction = getFractionInRange(playtime, expandDelay[i], expandDuration);
                endDeg += fastOutSlowIn(expandFraction) * extraDegPerCycle;

                const collapseFraction = getFractionInRange(playtime, collapseDelay[i], collapseDuration);
                startDeg += fastOutSlowIn(collapseFraction) * extraDegPerCycle;
            }

            // Gap closing
            startDeg += (endDeg - startDeg) * completeEndProgress;

            startFraction = startDeg / 360;
            endFraction = endDeg / 360;
        }

        function getFractionInRange(currentTime: real, delay: int, duration: int): real {
            if (currentTime < delay)
                return 0;
            if (currentTime > delay + duration)
                return 1;
            return (currentTime - delay) / duration;
        }

        function lerp(a: real, b: real, t: real): real {
            return a + (b - a) * t;
        }

        function cubic(a: real, b: real, c: real, d: real, t: real): real {
            return ((1 - t) ** 3) * a + 3 * ((1 - t) ** 2) * t * b + 3 * (1 - t) * (t ** 2) * c + (t ** 3) * d;
        }

        function cubicBezier(p1x: real, p1y: real, p2x: real, p2y: real, t: real): real {
            return cubic(0, p1y, p2y, 1, t);
        }

        function fastOutSlowIn(t: real): real {
            return cubicBezier(0.4, 0.0, 0.2, 1.0, t);
        }
    }
}
