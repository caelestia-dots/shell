pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property string gameKey
    property var sessions: []
    property var dailyMinutes: ({}) // { "YYYY-MM-DD": minutes }
    property var markerTimes: [] // unix times highlighted with a dot (achievement unlocks)
    property real contentHeight: 4 * 44 + 3 * Tokens.spacing.small
    property int monthOffset: 0
    readonly property int maxMonthsBack: 24

    readonly property var qlocale: Qt.locale(Tr.locale.name)
    readonly property int firstDow: (qlocale.firstDayOfWeek ?? 1) % 7
    readonly property date monthStart: {
        const d = new Date();
        return new Date(d.getFullYear(), d.getMonth() + monthOffset, 1);
    }
    readonly property int daysInMonth: new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 0).getDate()
    readonly property int leading: (monthStart.getDay() - firstDow + 7) % 7
    readonly property real monthFrom: monthStart.getTime() / 1000
    readonly property real monthTo: new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 1).getTime() / 1000

    readonly property var monthSessions: sessions.filter(s => s.start >= monthFrom && s.start < monthTo)
    readonly property var dayMinutes: {
        const secs = new Array(daysInMonth).fill(0);
        for (const s of sessions) {
            let cur = Math.max(s.start, monthFrom);
            const end = Math.min(s.end, monthTo);
            while (cur < end) {
                const d = new Date(cur * 1000);
                const nextMidnight = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime() / 1000;
                const until = Math.min(nextMidnight, end);
                secs[d.getDate() - 1] += until - cur;
                cur = until;
            }
        }
        const prefix = `${monthStart.getFullYear()}-${String(monthStart.getMonth() + 1).padStart(2, "0")}-`;
        return secs.map((s, i) => Math.round(s / 60) + (dailyMinutes?.[prefix + String(i + 1).padStart(2, "0")] ?? 0));
    }
    readonly property var dayMarkers: {
        const out = new Array(daysInMonth).fill(0);
        for (const t of markerTimes)
            if (t >= monthFrom && t < monthTo)
                out[new Date(t * 1000).getDate() - 1]++;
        return out;
    }
    readonly property var cells: {
        const out = [];
        for (let i = 0; i < leading; i++)
            out.push(null);
        for (let d = 1; d <= daysInMonth; d++)
            out.push({
                day: d,
                minutes: dayMinutes[d - 1],
                markers: dayMarkers[d - 1]
            });
        return out;
    }

    readonly property int totalMinutes: dayMinutes.reduce((a, m) => a + m, 0)
    readonly property int longestMinutes: monthSessions.reduce((m, s) => Math.max(m, Math.round((s.end - s.start) / 60)), 0)
    readonly property int monthMarkers: dayMarkers.reduce((a, n) => a + n, 0)
    readonly property bool hasPlay: totalMinutes > 0 || monthSessions.length > 0

    onGameKeyChanged: monthOffset = 0

    readonly property real gap: Tokens.spacing.extraSmall
    readonly property real labelHeight: 14
    readonly property real cellSize: Math.floor((contentHeight - labelHeight - gap * 6) / 6)

    function level(minutes: int): int {
        if (minutes <= 0)
            return 0;
        if (minutes < 60)
            return 1;
        if (minutes < 120)
            return 2;
        return 3;
    }

    function levelColour(lvl: int): color {
        if (lvl === 0)
            return Colours.palette.m3surfaceContainerHighest;
        if (lvl === 1)
            return Qt.alpha(Colours.palette.m3primary, 0.35);
        if (lvl === 2)
            return Qt.alpha(Colours.palette.m3primary, 0.65);
        return Colours.palette.m3primary;
    }

    implicitHeight: col.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "calendar_month"
                color: Colours.palette.m3tertiary
                fill: 1
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    const sameYear = root.monthStart.getFullYear() === new Date().getFullYear();
                    return Tr.tr("Activity in %1").arg(Tr.formatDateTime(root.monthStart, sameYear ? "MMMM" : "MMMM yyyy"));
                }
                font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            IconButton {
                Layout.topMargin: -Tokens.padding.extraSmall
                Layout.bottomMargin: -Tokens.padding.extraSmall
                type: IconButton.Text
                icon: "chevron_left"
                disabled: root.monthOffset <= -root.maxMonthsBack
                onClicked: root.monthOffset--
            }

            IconButton {
                Layout.topMargin: -Tokens.padding.extraSmall
                Layout.bottomMargin: -Tokens.padding.extraSmall
                type: IconButton.Text
                icon: "chevron_right"
                disabled: root.monthOffset >= 0
                onClicked: root.monthOffset++
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.contentHeight
            spacing: Tokens.spacing.medium

            Column {
                Layout.alignment: Qt.AlignTop
                spacing: root.gap

                Row {
                    spacing: root.gap

                    Repeater {
                        model: 7

                        StyledText {
                            required property int index

                            width: root.cellSize
                            height: root.labelHeight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: root.qlocale.dayName((root.firstDow + index) % 7, Locale.NarrowFormat).toUpperCase()
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                        }
                    }
                }

                Grid {
                    columns: 7
                    spacing: root.gap

                    Repeater {
                        model: root.cells

                        Item {
                            id: cell

                            required property var modelData
                            required property int index

                            readonly property bool isToday: !!modelData && root.monthOffset === 0 && modelData.day === new Date().getDate()
                            readonly property bool isFuture: !!modelData && root.monthOffset === 0 && modelData.day > new Date().getDate()
                            readonly property int lvl: modelData ? Math.max(root.level(modelData.minutes), modelData.markers > 0 ? 1 : 0) : 0

                            width: root.cellSize
                            height: root.cellSize

                            StyledRect {
                                anchors.fill: parent
                                visible: !!cell.modelData
                                radius: Tokens.rounding.small
                                color: root.levelColour(cell.lvl)
                                opacity: cell.isFuture ? 0.4 : 1
                                border.width: cell.isToday ? 2 : 0
                                border.color: Colours.palette.m3tertiary

                                scale: 0.6
                                Component.onCompleted: scale = 1

                                Behavior on scale {
                                    SequentialAnimation {
                                        PauseAnimation {
                                            duration: cell.index * 8
                                        }
                                        Anim {
                                            type: Anim.FastSpatial
                                        }
                                    }
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: (cell.modelData?.markers ?? 0) > 0 ? -2 : 0
                                    text: cell.modelData?.day ?? ""
                                    font: Tokens.font.label.small
                                    color: cell.lvl >= 2 ? Colours.palette.m3onPrimary : cell.lvl === 1 ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                }

                                StyledRect {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 3
                                    visible: (cell.modelData?.markers ?? 0) > 0
                                    implicitWidth: 4
                                    implicitHeight: 4
                                    radius: Tokens.rounding.full
                                    color: Colours.palette.m3tertiary
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Tokens.spacing.small

                Stat {
                    label: Tr.tr("Sessions")
                    value: root.monthSessions.length
                }

                Stat {
                    label: Tr.tr("Total")
                    value: root.totalMinutes > 0 ? Steam.formatPlaytime(root.totalMinutes) : "–"
                }

                Stat {
                    label: Tr.tr("Longest")
                    value: root.longestMinutes > 0 ? Steam.formatPlaytime(root.longestMinutes) : "–"
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        rightPadding: 2
                        text: Tr.tr("Less")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }

                    Repeater {
                        model: 4

                        StyledRect {
                            required property int index

                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 10
                            implicitHeight: 10
                            radius: 3
                            color: root.levelColour(index)
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 2
                        text: Tr.tr("More")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !root.hasPlay
                    horizontalAlignment: Text.AlignHCenter
                    text: root.monthMarkers > 0 ? Tr.tr("Dots mark achievement days. Playtime is recorded from now on.") : Tr.tr("Playtime is recorded while the shell is running.")
                    font: Tokens.font.label.small
                    color: Colours.palette.m3outline
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    component Stat: StyledRect {
        id: stat

        property string label
        property var value

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Tokens.padding.small * 2
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: String(stat.value)
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: stat.label
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }
        }
    }
}
