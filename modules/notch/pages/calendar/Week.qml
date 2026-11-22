pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.calendar
import qs.modules.notch

// Week schedule: one column per day with timed events laid out on an hour grid
Item {
    id: root

    property date weekStart: startOfWeek(new Date())
    readonly property list<date> days: [0, 1, 2, 3, 4, 5, 6].map(i => new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + i))
    readonly property bool isCurrentWeek: Events.dayKey(weekStart) === Events.dayKey(startOfWeek(Time.date))
    readonly property string selectedKey: DayView.shown ? Events.dayKey(DayView.date) : ""

    // Events per day, split into all-day and timed (with lanes for overlapping events)
    readonly property var weekEvents: days.map(d => {
        const all = Events.eventsOn(d);
        return {
            allDay: all.filter(e => e.allDay),
            timed: layoutDay(all.filter(e => !e.allDay && e.start))
        };
    })
    readonly property bool hasAllDay: weekEvents.some(d => d.allDay.length > 0)
    readonly property var allTimed: weekEvents.reduce((acc, d) => acc.concat(d.timed), [])

    // Visible hour span: 8-20 by default, widened to fit the week's events
    readonly property int startHour: Math.min(8, ...allTimed.map(e => Math.floor(e.startMin / 60)))
    readonly property int endHour: Math.max(20, ...allTimed.map(e => Math.ceil(e.endMin / 60)))
    readonly property real hourHeight: grid.height / (endHour - startHour)

    function startOfWeek(date: date): date {
        const offset = (date.getDay() - Qt.locale().firstDayOfWeek + 7) % 7;
        return new Date(date.getFullYear(), date.getMonth(), date.getDate() - offset);
    }

    function shiftWeek(weeks: int): void {
        weekStart = new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + weeks * 7);
    }

    function toMinutes(time: string): int {
        const [h, m] = time.split(":").map(n => parseInt(n));
        return h * 60 + m;
    }

    // Assigns overlapping events to side-by-side lanes
    function layoutDay(events: list<var>): list<var> {
        const items = events.map(e => {
            const startMin = toMinutes(e.start);
            let endMin = e.end ? toMinutes(e.end) : startMin + 60;
            // Events ending at/after midnight or with no length: clamp to the end of the day / min length
            if (endMin <= startMin)
                endMin = Math.min(24 * 60, startMin + 30);
            return Object.assign({}, e, {
                startMin,
                endMin
            });
        }).sort((a, b) => a.startMin - b.startMin || b.endMin - a.endMin);

        let cluster = [];
        let clusterEnd = -1;
        const flush = () => {
            const lanes = Math.max(...cluster.map(e => e.lane)) + 1;
            for (const e of cluster)
                e.lanes = lanes;
            cluster = [];
        };

        for (const e of items) {
            if (cluster.length && e.startMin >= clusterEnd)
                flush();

            const used = cluster.filter(c => c.endMin > e.startMin).map(c => c.lane);
            let lane = 0;
            while (used.includes(lane))
                lane++;
            e.lane = lane;
            cluster.push(e);
            clusterEnd = Math.max(clusterEnd, e.endMin);
        }
        if (cluster.length)
            flush();

        return items;
    }

    function loadWeek(): void {
        const end = new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + 6);
        Events.loadRange("week", weekStart, end);
    }

    implicitWidth: 640

    Component.onCompleted: loadWeek()
    onWeekStartChanged: loadWeek()

    Connections {
        function onDateChanged(): void {
            if (DayView.shown)
                root.weekStart = root.startOfWeek(DayView.date);
        }

        target: DayView
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium + 2
        spacing: Tokens.spacing.small

        // Header: week range and ghost navigation controls
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: {
                    const first = root.days[0];
                    const last = root.days[6];
                    if (first.getMonth() === last.getMonth())
                        return `${first.getDate()} – ${Qt.locale().toString(last, "d MMMM yyyy")}`;
                    return `${Qt.locale().toString(first, "d MMM")} – ${Qt.locale().toString(last, "d MMM yyyy")}`;
                }
                color: Hallownest.soul
                font.family: Hallownest.serif
                font.pointSize: 10.5
                font.weight: Font.Bold
                font.capitalization: Font.Capitalize
                font.letterSpacing: 0.4
                elide: Text.ElideRight
            }

            GhostNav {
                visible: !root.isCurrentWeek
                text: Tr.tr("Today")
                onClicked: root.weekStart = root.startOfWeek(new Date())
            }

            GhostNav {
                icon: "upload_file"
                disabled: !Events.available
                onClicked: ScheduleImporter.open()
            }

            Rectangle {
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                implicitWidth: 1
                implicitHeight: 14
                color: Hallownest.border
            }

            GhostNav {
                icon: "chevron_left"
                onClicked: root.shiftWeek(-1)
            }

            GhostNav {
                icon: "chevron_right"
                onClicked: root.shiftWeek(1)
            }
        }

        HkDivider {
            Layout.fillWidth: true
            opacity: 0.55
        }

        // Day headers
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: hourLabels.width
            spacing: 0

            Repeater {
                model: root.days

                Rectangle {
                    id: dayHeader

                    required property date modelData
                    readonly property bool isToday: Events.dayKey(modelData) === Events.dayKey(Time.date)
                    readonly property bool isWeekend: {
                        const d = modelData.getDay();
                        return d === 0 || d === 6;
                    }

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: headerCol.implicitHeight + 6
                    radius: 9
                    color: headerArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.45) : "transparent"

                    Behavior on color {
                        CAnim {}
                    }

                    MouseArea {
                        id: headerArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DayView.open(dayHeader.modelData)
                    }

                    Column {
                        id: headerCol

                        anchors.centerIn: parent
                        spacing: 2

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.locale().toString(dayHeader.modelData, "ddd")
                            color: dayHeader.isToday ? Hallownest.lifeblood : dayHeader.isWeekend ? Qt.alpha(Hallownest.gold, 0.85) : Hallownest.subtext
                            font.pointSize: 7.5
                            font.weight: Font.DemiBold
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 0.5
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: dayHeader.isToday ? Hallownest.lifeblood : "transparent"

                            StyledText {
                                anchors.centerIn: parent
                                text: dayHeader.modelData.getDate()
                                color: dayHeader.isToday ? Hallownest.void_ : Hallownest.text
                                font.family: Hallownest.mono
                                font.pointSize: 9
                                font.weight: dayHeader.isToday ? Font.Bold : Font.Medium
                            }
                        }
                    }
                }
            }
        }

        // All-day events strip
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: hourLabels.width
            visible: root.hasAllDay
            spacing: 0

            Repeater {
                model: root.weekEvents

                ColumnLayout {
                    id: allDayCol

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 2

                    Repeater {
                        model: allDayCol.modelData.allDay.slice(0, 2)

                        EventChip {
                            id: allDayChip

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.leftMargin: 2
                            Layout.rightMargin: 2
                            implicitHeight: chipText.implicitHeight + 4
                            event: modelData
                            date: root.days[allDayCol.index]

                            StyledText {
                                id: chipText

                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 4
                                verticalAlignment: Text.AlignVCenter
                                text: allDayChip.event.title
                                color: Hallownest.soul
                                font.pointSize: 7.5
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: allDayCol.modelData.allDay.length > 2
                        horizontalAlignment: Text.AlignHCenter
                        text: Tr.tr("+%1 more").arg(allDayCol.modelData.allDay.length - 2)
                        color: Hallownest.subtext
                        font.pointSize: 7.5
                    }
                }
            }
        }

        // Hour grid
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Hour labels (every 2 hours to avoid vertical crowding)
            Item {
                id: hourLabels

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: hourMetrics.width + Tokens.padding.small + 4

                TextMetrics {
                    id: hourMetrics

                    font.family: Hallownest.mono
                    font.pointSize: 7.5
                    text: "00:00"
                }

                Repeater {
                    model: root.endHour - root.startHour + 1

                    StyledText {
                        required property int index
                        readonly property int hour: root.startHour + index

                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.padding.small
                        y: index * root.hourHeight - height / 2
                        visible: index > 0 && index < root.endHour - root.startHour && hour % 2 === 0
                        text: `${String(hour).padStart(2, "0")}:00`
                        color: Hallownest.faint
                        font.family: Hallownest.mono
                        font.pointSize: 7.5
                    }
                }
            }

            Item {
                id: grid

                readonly property real dayWidth: width / 7

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: hourLabels.right
                anchors.right: parent.right

                // Subtle hour lines (stronger on even hours, faint on odd hours)
                Repeater {
                    model: root.endHour - root.startHour + 1

                    Rectangle {
                        required property int index
                        readonly property bool major: (root.startHour + index) % 2 === 0

                        x: 0
                        y: Math.round(index * root.hourHeight)
                        width: grid.width
                        height: 1
                        color: Hallownest.border
                        opacity: index === 0 || index === root.endHour - root.startHour ? 0 : major ? 0.38 : 0.14
                    }
                }

                // Day columns
                Repeater {
                    model: root.weekEvents

                    Item {
                        id: dayCol

                        required property var modelData
                        required property int index
                        readonly property date date: root.days[index]
                        readonly property bool isToday: Events.dayKey(date) === Events.dayKey(Time.date)

                        x: index * grid.dayWidth
                        width: grid.dayWidth
                        height: grid.height

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: dayCol.isToday ? Qt.alpha(Hallownest.lifeblood, 0.055) : colArea.containsMouse ? Qt.alpha(Hallownest.soul, 0.03) : "transparent"

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        MouseArea {
                            id: colArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DayView.open(dayCol.date)
                        }

                        Rectangle {
                            visible: dayCol.index > 0
                            width: 1
                            height: parent.height
                            color: Hallownest.border
                            opacity: 0.24
                        }

                        Repeater {
                            model: dayCol.modelData.timed

                            EventChip {
                                id: block

                                required property var modelData

                                readonly property real laneWidth: (dayCol.width - 4) / modelData.lanes

                                event: modelData
                                date: dayCol.date
                                x: 2 + modelData.lane * laneWidth
                                y: (modelData.startMin - root.startHour * 60) / 60 * root.hourHeight + 1
                                width: laneWidth - 1
                                height: Math.max((modelData.endMin - modelData.startMin) / 60 * root.hourHeight - 2, 14)
                                clip: true

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    anchors.leftMargin: 6
                                    spacing: 0

                                    StyledText {
                                        width: parent.width
                                        text: block.modelData.title
                                        color: Hallownest.soul
                                        font.pointSize: 7.5
                                        font.weight: Font.DemiBold
                                        wrapMode: Text.Wrap
                                        maximumLineCount: block.height > 48 ? 3 : block.height > 30 ? 2 : 1
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        id: timeText

                                        width: parent.width
                                        visible: block.height > implicitHeight * 2.4
                                        text: `${block.modelData.start}–${block.modelData.end}`
                                        color: Hallownest.subtext
                                        font.family: Hallownest.mono
                                        font.pointSize: 7
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // Current time indicator: fine crimson line with Hallownest diamond
                        Rectangle {
                            readonly property int nowMin: Time.hours * 60 + Time.minutes

                            visible: dayCol.isToday && nowMin >= root.startHour * 60 && nowMin <= root.endHour * 60
                            y: (nowMin - root.startHour * 60) / 60 * root.hourHeight - 0.75
                            width: parent.width
                            height: 1.5
                            color: Hallownest.grimm

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: -3
                                width: 6
                                height: 6
                                rotation: 45
                                color: Hallownest.grimm
                            }
                        }
                    }
                }
            }
        }
    }

    component GhostNav: Rectangle {
        id: nav

        property string icon
        property string text
        property bool disabled

        signal clicked

        implicitWidth: text ? navRow.implicitWidth + 16 : 28
        implicitHeight: 28
        radius: text ? 9 : 14
        color: navArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"
        opacity: disabled ? 0.35 : 1
        scale: navArea.pressed ? 0.93 : 1

        Behavior on color {
            CAnim {}
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Row {
            id: navRow

            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: nav.icon !== ""
                text: nav.icon
                color: navArea.containsMouse ? Hallownest.soul : Hallownest.steel
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: nav.text !== ""
                text: nav.text
                color: navArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                font.pointSize: 8.5
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: navArea

            anchors.fill: parent
            enabled: !nav.disabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    component EventChip: Rectangle {
        id: chip

        required property var event
        required property date date
        readonly property color accent: event.colour || Hallownest.lifeblood

        radius: 6
        color: Qt.alpha(accent, chipArea.containsMouse ? 0.24 : 0.14)
        border.width: 1
        border.color: Qt.alpha(accent, chipArea.containsMouse ? 0.48 : 0.26)

        Behavior on color {
            CAnim {}
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 1
            width: 2.5
            radius: 1.5
            color: chip.accent
        }

        MouseArea {
            id: chipArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: DayView.open(chip.date)
        }
    }
}
