import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

RowLayout {
    Layout.leftMargin: Appearance.padding.large
    Layout.rightMargin: Appearance.padding.large
    Layout.fillWidth: true

    Column {
        spacing: Appearance.spacing.small / 2

        StyledText {
            text: Weather.city || qsTr("Loading...")
            font.pointSize: Appearance.font.size.extraLarge
            font.weight: 600
            color: Colours.palette.m3onSurface
        }

        StyledText {
            text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Row {
        spacing: Appearance.spacing.large

        WeatherStat {
            icon: "wb_twilight"
            label: "Sunrise"
            value: Weather.sunrise
            colour: Colours.palette.m3tertiary
        }

        WeatherStat {
            icon: "bedtime"
            label: "Sunset"
            value: Weather.sunset
            colour: Colours.palette.m3tertiary
        }
    }

    component WeatherStat: Row {
        id: weatherStat

        property string icon
        property string label
        property string value
        property color colour

        spacing: Appearance.spacing.small

        MaterialIcon {
            text: weatherStat.icon
            font.pointSize: Appearance.font.size.extraLarge
            color: weatherStat.colour
        }

        Column {
            StyledText {
                text: weatherStat.label
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: weatherStat.value
                font.pointSize: Appearance.font.size.small
                font.weight: 600
                color: Colours.palette.m3onSurface
            }
        }
    }
}
