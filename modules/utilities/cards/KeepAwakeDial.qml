pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// A circular drag-to-set duration dial for the Keep Awake card. One full
// lap of the ring maps from minMinutes to maxMinutes; the current
// selection is echoed as "Xh Ym" text in the centre, matching the ring's
// themed colours (CircularProgress, already used elsewhere in this shell).
Item {
    id: root

    property int minMinutes: 15
    property int maxMinutes: 240
    property int stepMinutes: 15
    property int minutes: 60

    // Read-only countdown mode: the ring/text are driven by overrideValue
    // and overrideMinutes (computed live by the parent from
    // IdleInhibitor.until) instead of drag/scroll input.
    property bool readOnly: false
    property real overrideValue: 0
    property int overrideMinutes: 0
    property string hintText: qsTr("until")

    readonly property real value: readOnly ? overrideValue : (minutes - minMinutes) / (maxMinutes - minMinutes)

    readonly property int displayMinutes: readOnly ? overrideMinutes : minutes

    signal confirmed(minutes: int)

    function angleToMinutes(mx: real, my: real): int {
        const cx = width / 2;
        const cy = height / 2;
        let angle = Math.atan2(my - cy, mx - cx) * 180 / Math.PI + 90;
        if (angle < 0)
            angle += 360;
        const frac = angle / 360;
        const raw = minMinutes + frac * (maxMinutes - minMinutes);
        const stepped = Math.round(raw / stepMinutes) * stepMinutes;
        return Math.max(minMinutes, Math.min(maxMinutes, stepped));
    }

    implicitWidth: 180
    implicitHeight: 180

    CircularProgress {
        id: ring

        anchors.fill: parent
        value: root.value
        startAngle: -90
        sweepAngle: 360
        strokeWidth: 12
        fgColour: Colours.palette.m3primary
        bgColour: Colours.palette.m3secondaryContainer
        hasEndIndicator: true

        Behavior on value {
            Anim {}
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: {
                const h = Math.floor(root.displayMinutes / 60);
                const m = root.displayMinutes % 60;
                return (h > 0 ? qsTr("%1h ").arg(h) : "") + qsTr("%1m").arg(m);
            }
            font: Tokens.font.headline.medium
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.readOnly ? root.hintText : qsTr("drag or scroll")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    CustomMouseArea {
        function onWheel(event: WheelEvent): void {
            const delta = event.angleDelta.y > 0 ? root.stepMinutes : -root.stepMinutes;
            root.minutes = Math.max(root.minMinutes, Math.min(root.maxMinutes, root.minutes + delta));
        }

        anchors.fill: parent
        enabled: !root.readOnly
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => root.minutes = root.angleToMinutes(mouse.x, mouse.y)
        onPositionChanged: mouse => {
            if (pressed)
                root.minutes = root.angleToMinutes(mouse.x, mouse.y);
        }
    }
}
