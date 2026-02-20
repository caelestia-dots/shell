import "./deps/widgets"
import "./deps/services"
import "./deps/config"
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: 0

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Time.format("HH")
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge * 1.5
            font.family: Appearance.font.family.mono
            font.weight: 800
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: ":"
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.extraLarge * 1.5
            font.family: Appearance.font.family.mono
            font.weight: 800
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Time.format("mm")
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge * 1.5
            font.family: Appearance.font.family.mono
            font.weight: 800
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: Appearance.padding.large * 2

        text: Time.format("dddd, d MMMM yyyy")
        color: Colours.palette.m3tertiary
        font.pointSize: Appearance.font.size.large
        font.family: Appearance.font.family.mono
        font.bold: true
    }
}
