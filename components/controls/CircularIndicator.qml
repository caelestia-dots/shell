import ".."
import qs.services
import qs.config
import Caelestia.Internal
import QtQuick
import QtQuick.Templates

BusyIndicator {
    id: root

    enum AnimType {
        Advance = 0,
        Retreat
    }

    enum AnimState {
        Stopped,
        Running,
        Completing
    }

    property real implicitSize: Appearance.font.size.normal * 3
    property real strokeWidth: Appearance.padding.small * 0.8
    property color fgColour: Colours.palette.m3primary
    property color bgColour: Colours.palette.m3secondaryContainer

    property alias type: manager.indeterminateAnimationType
    readonly property alias progress: manager.progress

    property real internalStrokeWidth: strokeWidth
    property int animState

    padding: 0
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Component.onCompleted: {
        if (running) {
            running = false;
            running = true;
        }
    }

    onRunningChanged: {
        if (running) {
            manager.completeEndProgress = 0;
            animState = CircularIndicator.Running;
        } else {
            if (animState == CircularIndicator.Running)
                animState = CircularIndicator.Completing;
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
        Anim {
            properties: "opacity,internalStrokeWidth"
            duration: manager.completeEndDuration * Appearance.anim.durations.scale
        }
    }

    contentItem: CircularProgress {
        anchors.fill: parent
        strokeWidth: root.internalStrokeWidth
        fgColour: root.fgColour
        bgColour: root.bgColour
        padding: root.padding
        rotation: manager.rotation
        startAngle: manager.startFraction * 360
        value: manager.endFraction - manager.startFraction
    }

    CircularIndicatorManager {
        id: manager
    }

    NumberAnimation {
        running: root.animState !== CircularIndicator.Stopped
        loops: Animation.Infinite
        target: manager
        property: "progress"
        from: 0
        to: 1
        duration: manager.duration * Appearance.anim.durations.scale
    }

    NumberAnimation {
        running: root.animState === CircularIndicator.Completing
        target: manager
        property: "completeEndProgress"
        from: 0
        to: 1
        duration: manager.completeEndDuration * Appearance.anim.durations.scale
        onFinished: {
            if (root.animState === CircularIndicator.Completing)
                root.animState = CircularIndicator.Stopped;
        }
    }
}
