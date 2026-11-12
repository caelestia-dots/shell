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

    implicitWidth: 700

    Component.onCompleted: loadWeek()
    onWeekStartChanged: loadWeek()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        // Header: week range and navigation
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                text: {
                    const first = root.days[0];
                    const last = root.days[6];
                    if (first.getMonth() === last.getMonth())
                        return `${first.getDate()} – ${Qt.locale().toString(last, "d MMMM yyyy")}`;
                    return `${Qt.locale().toString(first, "d MMM")} – ${Qt.locale().toString(last, "d MMM yyyy")}`;
                }
                color: Hallownest.lifeblood
                font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                elide: Text.ElideRight
            }

            HkButton {
                implicitHeight: 28
                visible: !root.isCurrentWeek
                text: Tr.tr("Today")
                onClicked: root.weekStart = root.startOfWeek(new Date())
            }

            HkButton {
                implicitHeight: 28
                icon: "upload_file"
                disabled: !Events.available
                onClicked: ScheduleImporter.open()
            }

            HkButton {
                implicitHeight: 28
                icon: "chevron_left"
                onClicked: root.shiftWeek(-1)
            }

            HkButton {
                implicitHeight: 28
                icon: "chevron_right"
                onClicked: root.shiftWeek(1)
            }
        }

        // Day headers
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: hourLabels.width
            spacing: 0

            Repeater {
                model: root.days

                Item {
                    id: dayHeader

                    required property date modelData
                    readonly property bool isToday: Events.dayKey(modelData) === Events.dayKey(Time.date)

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: headerCol.implicitHeight + Tokens.padding.small * 2

                    StateLayer {
                        color: Hallownest.text
                        radius: Tokens.rounding.medium
                        onClicked: DayView.open(dayHeader.modelData)
                    }

                    Column {
                        id: headerCol

                        anchors.centerIn: parent
                        spacing: 2

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.locale().toString(dayHeader.modelData, "ddd")
                            color: dayHeader.isToday ? Hallownest.lifeblood : Hallownest.subtext
                            font: Tokens.font.label.builders.small.capitalisation(Font.Capitalize).build()
                        }

                        StyledRect {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitWidth: Math.max(dayNum.implicitWidth, dayNum.implicitHeight) + Tokens.padding.small
                            implicitHeight: implicitWidth
                            radius: Tokens.rounding.full
                            color: dayHeader.isToday ? Hallownest.lifeblood : "transparent"

                            StyledText {
                                id: dayNum

                                anchors.centerIn: parent
                                text: dayHeader.modelData.getDate()
                                color: dayHeader.isToday ? Hallownest.void_ : Hallownest.text
                                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
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
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.leftMargin: 1
                            Layout.rightMargin: 1
                            implicitHeight: chipText.implicitHeight + 4
                            event: modelData
                            date: root.days[allDayCol.index]

                            StyledText {
                                id: chipText

                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.small
                                anchors.rightMargin: Tokens.padding.small
                                verticalAlignment: Text.AlignVCenter
                                text: parent.event.title
                                color: Hallownest.soul
                                font: Tokens.font.label.small
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
                        font: Tokens.font.label.small
                    }
                }
            }
        }

        // Hour grid
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Hour labels
            Item {
                id: hourLabels

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: hourMetrics.width + Tokens.padding.medium

                TextMetrics {
                    id: hourMetrics

                    font: Tokens.font.label.small
                    text: "00:00"
                }

                Repeater {
                    model: root.endHour - root.startHour + 1

                    StyledText {
                        required property int index

                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.padding.small
                        y: index * root.hourHeight - height / 2
                        visible: index > 0 && index < root.endHour - root.startHour
                        text: `${String(root.startHour + index).padStart(2, "0")}:00`
                        color: Hallownest.faint
                        font: Tokens.font.label.small
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

                // Hour lines
                Repeater {
                    model: root.endHour - root.startHour + 1

                    StyledRect {
                        required property int index

                        x: 0
                        y: Math.round(index * root.hourHeight)
                        width: grid.width
                        height: 1
                        color: Hallownest.border
                        opacity: index === 0 || index === root.endHour - root.startHour ? 0 : 0.5
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

                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.small
                            color: dayCol.isToday ? Qt.alpha(Hallownest.lifeblood, 0.06) : "transparent"
                        }

                        StyledRect {
                            visible: dayCol.index > 0
                            width: 1
                            height: parent.height
                            color: Hallownest.border
                            opacity: 0.5
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
                                height: Math.max((modelData.endMin - modelData.startMin) / 60 * root.hourHeight - 2, 12)
                                clip: true

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    anchors.leftMargin: 5
                                    spacing: 0

                                    StyledText {
                                        width: parent.width
                                        text: block.modelData.title
                                        color: Hallownest.soul
                                        font: Tokens.font.label.builders.small.weight(Font.Medium).build()
                                        wrapMode: Text.Wrap
                                        maximumLineCount: block.height > 48 ? 3 : block.height > 32 ? 2 : 1
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        id: timeText

                                        width: parent.width
                                        visible: block.height > implicitHeight * 2.5
                                        text: `${block.modelData.start}–${block.modelData.end}`
                                        color: Hallownest.soul
                                        opacity: 0.8
                                        font: Tokens.font.label.small
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // Current time indicator
                        StyledRect {
                            readonly property int nowMin: Time.hours * 60 + Time.minutes

                            visible: dayCol.isToday && nowMin >= root.startHour * 60 && nowMin <= root.endHour * 60
                            y: (nowMin - root.startHour * 60) / 60 * root.hourHeight - 1
                            width: parent.width
                            height: 2
                            color: Hallownest.grimm

                            StyledRect {
                                anchors.verticalCenter: parent.verticalCenter
                                x: -3
                                implicitWidth: 6
                                implicitHeight: 6
                                radius: 3
                                color: Hallownest.grimm
                            }
                        }
                    }
                }
            }
        }
    }

    component EventChip: StyledRect {
        id: chip

        required property var event
        required property date date

        radius: Tokens.rounding.extraSmall
        color: Qt.alpha(Hallownest.lifeblood, 0.18)

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            radius: 1.5
            color: chip.event.colour || Hallownest.lifeblood
        }

        StateLayer {
            color: Hallownest.soul
            radius: chip.radius
            onClicked: DayView.open(chip.date)
        }
    }
}
