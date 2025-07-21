pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls

Column {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    padding: Appearance.padding.large
    spacing: Appearance.spacing.small

    DayOfWeekRow {
        id: days

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding

        delegate: StyledText {
            required property var model

            horizontalAlignment: Text.AlignHCenter
            text: model.shortName
            font.family: Appearance.font.family.sans
            font.weight: 500
        }
    }

    MonthGrid {
        id: grid

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: parent.padding

        spacing: 3

        delegate: Item {
            id: day

            required property var model

            implicitWidth: implicitHeight
            implicitHeight: text.implicitHeight + Appearance.padding.small * 2

            StyledRect {
                anchors.centerIn: parent

                implicitWidth: parent.implicitHeight
                implicitHeight: parent.implicitHeight

                radius: Appearance.rounding.full
                color: model.today ? Colours.palette.m3primary : "transparent"

                StyledText {
                    id: text

                    anchors.centerIn: parent

                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(day.model.date, "d")
                    color: day.model.today ? Colours.palette.m3onPrimary : day.model.month === grid.month ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3outline
                }
            }
        }
    }
}
