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
    property int currMonth: currentDate.getMonth()
    property int currYear: currentDate.getFullYear()

    RowLayout {
        id: monthNavigationRow

        width: parent.width - (root.padding * 2)
        spacing: Appearance.spacing.small

        Item {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30

            StyledRect {
                anchors.centerIn: parent

                implicitWidth: implicitHeight
                implicitHeight: prevMonthText.implicitHeight + Appearance.padding.small * 2

                radius: Appearance.rounding.full
                color: prevMonthMouseArea.containsMouse ? Colours.palette.m3primary : "transparent"
            }

            MaterialIcon {
                id: prevMonthText
                anchors.centerIn: parent
                text: "chevron_left"
                color: prevMonthMouseArea.containsMouse ? Colours.palette.m3onPrimary : Colours.palette.m3primary 
                font.pointSize: Appearance.font.size.normal
                font.weight: 700
            }

            MouseArea {
                id: prevMonthMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
                }
            }
        }

        StyledText {
            id: monthYearDisplay

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: grid.title
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.normal
            font.weight: 500
            font.capitalization: Font.Capitalize
        }

        Item {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30

            StyledRect {
                anchors.centerIn: parent

                implicitWidth: implicitHeight
                implicitHeight: nextMonthText.implicitHeight + Appearance.padding.small * 2

                radius: Appearance.rounding.full
                color: nextMonthMouseArea.containsMouse ? Colours.palette.m3primary : "transparent"
            }

            MaterialIcon {
                id: nextMonthText
                anchors.centerIn: parent
                text: "chevron_right"
                color: nextMonthMouseArea.containsMouse ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                font.pointSize: Appearance.font.size.normal
                font.weight: 700
            }

            MouseArea {
                id: nextMonthMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
                }
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
            font.family: Appearance.font.family.sans
            font.weight: 500
            color: (model.day === 0 || model.day === 6) ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
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
                    var dayOfWeek = dayItem.model.date.getUTCDay();
                    if (dayItem.model.today) {
                        return Colours.palette.m3onPrimary;
                    } else if (dayOfWeek === 0 || dayOfWeek === 6) {
                        return Colours.palette.m3primary;
                    } else if (dayItem.model.month === grid.month) {
                        return Colours.palette.m3onSurfaceVariant;
                    } else {
                        return Colours.palette.m3outline;
                    }
                }
                opacity: dayItem.model.month === grid.month ? 1.0 : 0.4
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
            }
        }
    }
}
