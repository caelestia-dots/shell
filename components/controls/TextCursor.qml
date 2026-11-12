import QtQuick
import Caelestia.Config
import Caelestia.Scheme
import qs.components

StyledRect {
    id: root

    required property var editor
    property bool disableBlink

    readonly property list<real> animCurve: [0.2, 1, 0.21, 1, 1, 1] // Damped variant of fast spatial curve
    readonly property int animDuration: Tokens.anim.durations.expressiveFastEffects

    x: editor.cursorRectangle.x
    y: editor.cursorRectangle.y
    implicitWidth: 1.5
    implicitHeight: editor.cursorRectangle.height

    color: Colours.palette.primary
    radius: Tokens.rounding.large

    Connections {
        function onCursorPositionChanged(): void {
            if (root.editor.activeFocus && root.editor.cursorVisible) {
                root.opacity = 1;
                root.disableBlink = true;
                enableBlink.restart();
            }
        }

        target: root.editor
    }

    Timer {
        id: enableBlink

        interval: 500
        onTriggered: root.disableBlink = false
    }

    Timer {
        running: root.editor.activeFocus && root.editor.cursorVisible && !root.disableBlink
        repeat: true
        triggeredOnStart: true
        interval: 500
        onTriggered: root.opacity = root.opacity === 1 ? 0 : 1
    }

    Binding {
        when: !root.editor.activeFocus || !root.editor.cursorVisible
        root.opacity: 0
    }

    Behavior on x {
        Anim {
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.animCurve
            duration: root.animDuration
        }
    }

    Behavior on y {
        Anim {
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.animCurve
            duration: root.animDuration
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
