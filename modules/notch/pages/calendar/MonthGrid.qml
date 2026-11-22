pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.hallownest
import qs.services
import qs.modules.calendar
import qs.modules.notch

CustomMouseArea {
    id: root

    required property ScreenState screenState

    property date currentDate: screenState.calendarDate
    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()
    readonly property int nonAnimCurrMonth: screenState.calendarDate.getMonth()
    readonly property int nonAnimCurrYear: screenState.calendarDate.getFullYear()
    readonly property bool isCurrentMonth: nonAnimCurrMonth === Time.date.getMonth() && nonAnimCurrYear === Time.date.getFullYear()
    readonly property string selectedKey: DayView.shown ? Events.dayKey(DayView.date) : ""
    readonly property int todayEventCount: Events.eventsOn(Time.date).length

    readonly property int animDirection: screenState.calendarDate > currentDate ? -1 : 1
    property real animTranslate
    property real animOpacity: 1

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            screenState.calendarDate = new Date(nonAnimCurrYear, nonAnimCurrMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            screenState.calendarDate = new Date(nonAnimCurrYear, nonAnimCurrMonth + 1, 1);
    }

    acceptedButtons: Qt.MiddleButton
    onClicked: root.screenState.calendarDate = new Date()

    Component.onCompleted: Events.loadMonth(nonAnimCurrYear, nonAnimCurrMonth)
    onNonAnimCurrMonthChanged: Events.loadMonth(nonAnimCurrYear, nonAnimCurrMonth)
    onNonAnimCurrYearChanged: Events.loadMonth(nonAnimCurrYear, nonAnimCurrMonth)

    Anim {
        id: trOutAnim

        running: false
        target: root
        property: "animTranslate"
        to: root.Tokens.padding.large * root.animDirection
        type: Anim.FastSpatial
    }

    Behavior on currentDate {
        SequentialAnimation {
            ParallelAnimation {
                ScriptAction {
                    script: Qt.callLater(() => trOutAnim.start())
                }
                Anim {
                    target: root
                    property: "animOpacity"
                    to: 0
                    type: Anim.FastEffects
                }
            }
            ScriptAction {
                script: {
                    trOutAnim.complete();
                    root.animTranslate = root.Tokens.padding.large * -root.animDirection;
                }
            }
            PropertyAction {}
            ParallelAnimation {
                Anim {
                    target: root
                    property: "animTranslate"
                    to: 0
                    type: Anim.DefaultSpatial
                }
                Anim {
                    target: root
                    property: "animOpacity"
                    to: 1
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium + 2
        spacing: Tokens.spacing.small

        RowLayout {
            id: monthNavigationRow

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            NavButton {
                icon: "chevron_left"
                onClicked: root.screenState.calendarDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth - 1, 1)
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 9
                color: !root.isCurrentMonth && monthTitleArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.5) : "transparent"

                Behavior on color {
                    CAnim {}
                }

                StyledText {
                    id: monthYearDisplay

                    anchors.centerIn: parent
                    opacity: root.animOpacity
                    text: grid.title
                    color: Hallownest.soul
                    font.family: Hallownest.serif
                    font.pointSize: 10.5
                    font.weight: Font.Bold
                    font.capitalization: Font.Capitalize
                    font.letterSpacing: 0.4

                    transform: Translate {
                        x: root.animTranslate
                    }
                }

                MouseArea {
                    id: monthTitleArea

                    anchors.fill: parent
                    enabled: !root.isCurrentMonth
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.screenState.calendarDate = new Date()
                }
            }

            NavButton {
                icon: "chevron_right"
                onClicked: root.screenState.calendarDate = new Date(root.nonAnimCurrYear, root.nonAnimCurrMonth + 1, 1)
            }
        }

        HkDivider {
            Layout.fillWidth: true
            opacity: 0.55
        }

        DayOfWeekRow {
            id: daysRow

            Layout.fillWidth: true
            locale: grid.locale

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.pointSize: 7.5
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.5
                color: (model.day === 0 || model.day === 6) ? Qt.alpha(Hallownest.gold, 0.85) : Hallownest.subtext
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            opacity: root.animOpacity
            transform: Translate {
                x: root.animTranslate
            }

            MonthGrid {
                id: grid

                anchors.fill: parent
                month: root.currMonth
                year: root.currYear
                spacing: 3
                locale: Qt.locale()

                delegate: Rectangle {
                    id: dayItem

                    required property var model

                    readonly property list<var> events: Events.eventsOn(model.date)
                    readonly property bool isToday: model.today
                    readonly property bool inMonth: model.month === grid.month
                    readonly property bool isSelected: root.selectedKey !== "" && Events.dayKey(model.date) === root.selectedKey
                    readonly property bool isWeekend: {
                        const d = model.date.getDay();
                        return d === 0 || d === 6;
                    }

                    radius: 9
                    color: isToday ? Hallownest.lifeblood : isSelected ? Qt.alpha(Hallownest.soul, 0.12) : dayArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"
                    border.width: isSelected && !isToday ? 1 : 0
                    border.color: Qt.alpha(Hallownest.soul, 0.55)

                    Behavior on color {
                        CAnim {}
                    }

                    MouseArea {
                        id: dayArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DayView.open(dayItem.model.date)
                    }

                    StyledText {
                        id: dayText

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: dayItem.events.length > 0 ? -3 : 0
                        horizontalAlignment: Text.AlignHCenter
                        text: grid.locale.toString(dayItem.model.day)
                        color: dayItem.isToday ? Hallownest.void_ : dayItem.isSelected ? Hallownest.soul : dayItem.isWeekend ? Qt.alpha(Hallownest.gold, 0.9) : Hallownest.text
                        opacity: dayItem.isToday || dayItem.isSelected || dayItem.inMonth ? 1 : 0.3
                        font.family: Hallownest.mono
                        font.pointSize: 8.5
                        font.weight: dayItem.isToday || dayItem.isSelected ? Font.Bold : Font.Medium
                    }

                    // Event indicators: small Soul diamonds (max 3)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        spacing: 3
                        visible: dayItem.events.length > 0
                        opacity: dayItem.isToday || dayItem.inMonth ? 1 : 0.35

                        Repeater {
                            model: Math.min(dayItem.events.length, 3)

                            Rectangle {
                                required property int index

                                width: 4
                                height: 4
                                rotation: 45
                                color: dayItem.isToday ? Hallownest.void_ : (dayItem.events[index].colour || Hallownest.lifeblood)
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 24

            Rectangle {
                anchors.centerIn: parent
                visible: !root.isCurrentMonth
                width: todayLabel.implicitWidth + 18
                height: 22
                radius: 11
                color: todayArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.6) : Qt.alpha(Hallownest.soul, 0.06)
                border.width: 1
                border.color: Hallownest.border

                Behavior on color {
                    CAnim {}
                }

                StyledText {
                    id: todayLabel

                    anchors.centerIn: parent
                    text: Tr.tr("Back to today")
                    color: todayArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                    font.pointSize: 8
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: todayArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.screenState.calendarDate = new Date()
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.isCurrentMonth
                text: root.todayEventCount === 0 ? Tr.tr("No events today") : root.todayEventCount === 1 ? Tr.tr("1 event today") : Tr.tr("%1 events today").arg(root.todayEventCount)
                color: root.todayEventCount > 0 ? Hallownest.subtext : Hallownest.faint
                font.pointSize: 8
            }
        }
    }

    component NavButton: Rectangle {
        id: nav

        property string icon

        signal clicked

        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        color: navArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.55) : "transparent"
        scale: navArea.pressed ? 0.92 : 1

        Behavior on color {
            CAnim {}
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: nav.icon
            color: navArea.containsMouse ? Hallownest.soul : Hallownest.steel
            fontStyle: Tokens.font.icon.small
        }

        MouseArea {
            id: navArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }
}
