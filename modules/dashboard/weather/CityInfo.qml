import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    Layout.leftMargin: Tokens.padding.large
    Layout.rightMargin: Tokens.padding.large
    Layout.fillWidth: true

    Column {
        spacing: Tokens.spacing.small / 2

        StyledText {
            text: Weather.city || qsTr("Loading...")
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 600
            color: Colours.palette.m3onSurface
        }

        StyledText {
            text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
            font.pointSize: Tokens.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Row {
        spacing: Tokens.spacing.large

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

        spacing: Tokens.spacing.small

        MaterialIcon {
            text: weatherStat.icon
            font.pointSize: Tokens.font.size.extraLarge
            color: weatherStat.colour
        }

        Column {
            StyledText {
                text: weatherStat.label
                font.pointSize: Tokens.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: weatherStat.value
                font.pointSize: Tokens.font.size.small
                font.weight: 600
                color: Colours.palette.m3onSurface
            }
        }
    }
}
