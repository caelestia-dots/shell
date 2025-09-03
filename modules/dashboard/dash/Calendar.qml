pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    padding: Appearance.padding.large
    spacing: Appearance.spacing.small

    property date currentDate: new Date()
    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()

    RowLayout {
        id: monthNavigationRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding
        spacing: Appearance.spacing.small

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: prevMonthText.implicitHeight + Appearance.padding.small * 2

            radius: Appearance.rounding.full

            StateLayer {
                id: prevMonthStateLayer

                function onClicked(): void {
                    root.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
                }
            }

            MaterialIcon {
                id: prevMonthText

                anchors.centerIn: parent
                text: "chevron_left"
                color: Colours.palette.m3tertiary
                font.pointSize: Appearance.font.size.normal
                font.weight: 700
            }
        }

        Item {
            Layout.fillWidth: true

            implicitWidth: monthYearDisplay.implicitWidth + Appearance.padding.small * 2
            implicitHeight: monthYearDisplay.implicitHeight + Appearance.padding.small * 2

            StateLayer {
                anchors.fill: monthYearDisplay
                anchors.margins: -Appearance.padding.small
                anchors.leftMargin: -Appearance.padding.normal
                anchors.rightMargin: -Appearance.padding.normal

                radius: Appearance.rounding.full
                disabled: root.currentDate.toDateString() == new Date().toDateString()

                function onClicked(): void {
                    root.currentDate = new Date();
                }
            }

            StyledText {
                id: monthYearDisplay

                anchors.centerIn: parent
                text: grid.title
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
                font.capitalization: Font.Capitalize
            }
        }

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: nextMonthText.implicitHeight + Appearance.padding.small * 2

            radius: Appearance.rounding.full

            StateLayer {
                id: nextMonthStateLayer

                function onClicked(): void {
                    root.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
                }
            }

            MaterialIcon {
                id: nextMonthText

                anchors.centerIn: parent
                text: "chevron_right"
                color: Colours.palette.m3tertiary
                font.pointSize: Appearance.font.size.normal
                font.weight: 700
            }
        }
    }

    DayOfWeekRow {
        id: daysRow

        locale: grid.locale

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding

        delegate: StyledText {
            required property var model

            horizontalAlignment: Text.AlignHCenter
            text: model.shortName
            font.weight: 500
            color: (model.day === 0 || model.day === 6) ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant
        }
    }

    MonthGrid {
        id: grid

        month: root.currMonth
        year: root.currYear

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding

        spacing: 3
        locale: Qt.locale()

        delegate: Item {
            id: dayItem

            required property var model

            implicitWidth: implicitHeight
            implicitHeight: text.implicitHeight + Appearance.padding.small * 2

            StyledRect {
                anchors.centerIn: parent

                implicitWidth: parent.implicitHeight
                implicitHeight: parent.implicitHeight

                radius: Appearance.rounding.full
                color: dayItem.model.today ? Colours.palette.m3primary : "transparent"
            }

            StyledText {
                id: text

                anchors.centerIn: parent

                horizontalAlignment: Text.AlignHCenter
                text: grid.locale.toString(dayItem.model.day)
                color: {
                    if (dayItem.model.today)
                        return Colours.palette.m3onPrimary;

                    const dayOfWeek = dayItem.model.date.getUTCDay();
                    if (dayOfWeek === 0 || dayOfWeek === 6)
                        return Colours.palette.m3secondary;

                    return Colours.palette.m3onSurfaceVariant;
                }
                opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
            }
        }
    }
}
