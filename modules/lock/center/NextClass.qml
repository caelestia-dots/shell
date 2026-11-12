import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Next timed event of today (khal), under the date
Row {
    id: root

    property real maxWidth: Infinity
    readonly property var next: {
        const now = clock.date;
        const mins = now.getHours() * 60 + now.getMinutes();
        for (const e of Events.eventsOn(now)) {
            const [h, m] = (e.start || "").split(":").map(n => parseInt(n));
            if (!e.allDay && !isNaN(h) && h * 60 + (m || 0) > mins)
                return e;
        }
        return null;
    }

    function load(): void {
        const start = new Date(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate());
        const end = new Date(start);
        end.setDate(end.getDate() + 1);
        Events.loadRange("lock", start, end);
    }

    visible: !!next
    spacing: Tokens.spacing.small

    Component.onCompleted: load()

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
        onDateChanged: {
            if (date.getHours() === 0 && date.getMinutes() === 0)
                root.load();
        }
    }

    MaterialIcon {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        text: "school"
        color: Hallownest.gold
        fontStyle: Tokens.font.icon.small
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.maxWidth - icon.implicitWidth - root.spacing)
        elide: Text.ElideRight
        text: root.next ? Tr.tr("Next: %1 · %2").arg(root.next.title).arg(root.next.start) + (root.next.location ? ` · ${root.next.location}` : "") : ""
        color: Hallownest.text
        font.pointSize: Tokens.font.body.medium.pointSize
    }
}
