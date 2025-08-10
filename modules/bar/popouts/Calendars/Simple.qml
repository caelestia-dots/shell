pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.normal
    width: 320

    property date currentDate: new Date()
    property int currentYear: currentDate.getFullYear()
    property int currentMonth: currentDate.getMonth()

    opacity: 0
    scale: 0.9
    y: -10

    Component.onCompleted: {
        opacity = 1
        scale = 1
        y = 0
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutBack
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutCubic
        }
    }

    // Calendar grid
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Appearance.padding.small
        Layout.rightMargin: Appearance.padding.small
        Layout.preferredHeight: calendarGrid.implicitHeight + Appearance.padding.small * 2

        ColumnLayout {
            id: calendarGrid

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.small

            // Month navigation
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Appearance.spacing.small

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: prevIcon.implicitHeight + Appearance.padding.small * 1.5

                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primaryContainer

                    StateLayer {
                        color: Colours.palette.m3onPrimaryContainer

                        function onClicked(): void {
                            root.currentMonth = root.currentMonth - 1
                            if (root.currentMonth < 0) {
                                root.currentMonth = 11
                                root.currentYear = root.currentYear - 1
                            }
                        }
                    }

                    MaterialIcon {
                        id: prevIcon

                        anchors.centerIn: parent
                        text: "chevron_left"
                        color: Colours.palette.m3onPrimaryContainer
                    }
                }

                StyledText {
                    Layout.fillWidth: true

                    text: {
                        const monthNames = Array.from({ length: 12 }, (_, i) => Qt.locale().monthName(i, Qt.locale().LongFormat))
                        return monthNames[root.currentMonth] + " " + root.currentYear
                    }
                    horizontalAlignment: Text.AlignHCenter
                    font.weight: 600
                    font.pointSize: Appearance.font.size.normal
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: nextIcon.implicitHeight + Appearance.padding.small * 1.5
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primaryContainer

                    StateLayer {
                        color: Colours.palette.m3onPrimaryContainer
                        function onClicked(): void {
                            root.currentMonth = root.currentMonth + 1
                            if (root.currentMonth > 11) {
                                root.currentMonth = 0
                                root.currentYear = root.currentYear + 1
                            }
                        }
                    }

                    MaterialIcon {
                        id: nextIcon
                        anchors.centerIn: parent
                        text: "chevron_right"
                        color: Colours.palette.m3onPrimaryContainer
                    }
                }
            }

            // Day headers
            DayOfWeekRow {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.font.size.extraLarge

                padding: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                delegate: StyledText {
                    required property var model

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: model.shortName
                    color: Colours.palette.m3onSurfaceVariant

                    font.pointSize: Appearance.font.size.small
                    font.weight: 500
                }
            }

            // Calendar days grid
            MonthGrid {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.margins: Appearance.padding.smaller

                month: root.currentMonth
                year: root.currentYear
                spacing: Appearance.spacing.large

                delegate: Item {
                    id: dayItem
                    required property var model

                    implicitWidth: implicitHeight
                    implicitHeight: dayText.implicitHeight + Appearance.padding.small * 2

                    StyledRect {
                        anchors.centerIn: parent
                        implicitWidth: parent.implicitHeight
                        implicitHeight: parent.implicitHeight
                        radius: Appearance.rounding.full
                        color: dayItem.model.today ? Colours.palette.m3primary : "transparent"

                        StateLayer {
                            visible: dayItem.model.month === root.currentMonth
                            color: Colours.palette.m3onSurface
                            function onClicked(): void {}
                        }

                        StyledText {
                            id: dayText
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.formatDate(dayItem.model.date, "d")
                            color: dayItem.model.today ? Colours.palette.m3onPrimary : 
                                   dayItem.model.month === root.currentMonth ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3outline

                            font.pointSize: Appearance.font.size.small
                            font.weight: dayItem.model.today ? 600 : 400
                        }
                    }
                }
            }
        }
    }
}
