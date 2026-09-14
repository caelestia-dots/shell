import QtQuick
import Quickshell
import M3Shapes
import qs.components
import qs.services

MaterialShape {
    id: root

    property list<int> shapes: {
        if (containsIcon)
            return [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval];
        return [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval];
    }
    property int shapeIndex
    property real cRotation
    property real lRotation
    property real thisLRotation
    property bool containsIcon

    property bool animated: true
    property int morphAnimRotation: 60
    property real morphScale: 0.14
    property alias rotateAnimDuration: rotateAnim.duration

    property real stiffness: 180
    property real dampingRatio: 0.6
    property real visibilityThreshold: 0.075

    readonly property real springDuration: {
        const wn = Math.sqrt(stiffness);
        const r = -dampingRatio * wn;
        const c = 1 / Math.sqrt(1 - dampingRatio * dampingRatio);
        return Math.log(visibilityThreshold / c) / r;
    }
    readonly property real springMaxVelocity: {
        const wn = Math.sqrt(stiffness);
        const factor = Math.exp(-z * Math.acos(z) / Math.sqrt(1 - z * z));
        return wn * factor;
    }
    property bool springSettled: true

    function spring(t: real): var {
        const wn = Math.sqrt(stiffness);
        const za = dampingRatio * wn;

        const wd = wn * Math.sqrt(1 - dampingRatio * dampingRatio);
        const r = za / wd;
        const pos = 1 - Math.exp(-za * t) * (Math.cos(wd * t) + r * Math.sin(wd * t));
        const vel = Math.exp(-za * t) * (wn * wn / wd) * Math.sin(wd * t);

        return [pos, vel];
    }

    implicitSize: 38
    color: Colours.palette.m3primary
    toShape: shapes[0]

    ElapsedTimer {
        id: timer
    }

    FrameAnimation {
        running: root.animated && !root.springSettled
        onTriggered: {
            const t = timer.elapsed();

            if (t >= root.springDuration) {
                root.springSettled = true;
            } else {
                const [pos, vel] = root.spring(t);
                root.morphProgress = Math.min(1, pos); // Overshooting the morph looks weird
                root.thisLRotation = pos * root.morphAnimRotation;
                root.scale = 1 + vel * root.morphScale / root.springMaxVelocity;
            }
        }
    }

    Timer {
        interval: 650
        repeat: true
        triggeredOnStart: true
        running: root.animated
        onTriggered: {
            root.beginBatchUpdate();
            root.fromShape = root.toShape;
            root.shapeIndex = (root.shapeIndex + 1) % root.shapes.length;
            root.toShape = root.shapes[root.shapeIndex];
            root.morphProgress = 0;

            root.rotation = root.rotation;
            root.lRotation = (root.lRotation + root.thisLRotation) % 360;
            root.thisLRotation = 0;
            root.rotation = Qt.binding(() => root.cRotation + root.lRotation + root.thisLRotation);

            root.springSettled = false;
            timer.restart();
            root.endBatchUpdate();
        }
    }

    RotationAnimation on cRotation {
        id: rotateAnim

        running: root.animated
        from: 0
        to: 360
        easing.type: Easing.Linear
        loops: Animation.Infinite
        duration: 4666
    }

    Behavior on color {
        CAnim {}
    }
}
