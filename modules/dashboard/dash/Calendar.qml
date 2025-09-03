pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root

    required property var state

    readonly property int currMonth: state.currentDate.getMonth()
    readonly property int currYear: state.currentDate.getFullYear()

    anchors.left: parent.left
    anchors.right: parent.right
    padding: Appearance.padding.large
    spacing: Appearance.spacing.small

    RowLayout {
        id: monthNavigationRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding
        spacing: Appearance.spacing.small

        Item {
            implicitWidth: implicitHeight
            implicitHeight: prevMonthText.implicitHeight + Appearance.padding.small * 2

            StateLayer {
                id: prevMonthStateLayer

                radius: Appearance.rounding.full

                function onClicked(): void {
                    root.state.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
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
                disabled: root.state.currentDate.toDateString() == new Date().toDateString()

                function onClicked(): void {
                    root.state.currentDate = new Date();
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

        Item {
            implicitWidth: implicitHeight
            implicitHeight: nextMonthText.implicitHeight + Appearance.padding.small * 2

            StateLayer {
                id: nextMonthStateLayer

                radius: Appearance.rounding.full

                function onClicked(): void {
                    root.state.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
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

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding

        implicitHeight: grid.implicitHeight

        MonthGrid {
            id: grid

            month: root.currMonth
            year: root.currYear

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 3
            locale: Qt.locale()

            delegate: Item {
                id: dayItem

                required property var model

                implicitWidth: implicitHeight
                implicitHeight: text.implicitHeight + Appearance.padding.small * 2

                StyledText {
                    id: text

                    anchors.centerIn: parent

                    horizontalAlignment: Text.AlignHCenter
                    text: grid.locale.toString(dayItem.model.day)
                    color: {
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

        StyledClippingRect {
            id: todayIndicator

            readonly property Item todayItem: grid.contentItem.children.find(c => c.model.today) ?? null
            property Item today

            onTodayItemChanged: {
                if (todayItem)
                    today = todayItem;
            }

            x: today ? today.x + (today.width - implicitWidth) / 2 : 0
            y: today?.y ?? 0

            implicitWidth: today?.implicitWidth ?? 0
            implicitHeight: today?.implicitHeight ?? 0

            radius: Appearance.rounding.full
            color: Colours.palette.m3primary

            opacity: todayItem ? 1 : 0
            scale: todayItem ? 1 : 0.7

            Colouriser {
                x: -todayIndicator.x
                y: -todayIndicator.y

                implicitWidth: grid.width
                implicitHeight: grid.height

                source: grid
                sourceColor: Colours.palette.m3onSurface
                colorizationColor: Colours.palette.m3onPrimary
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on x {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            Behavior on y {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        }
    }
}
