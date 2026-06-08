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
            font: Tokens.font.title.large
            color: Colours.palette.m3onSurface
        }

        StyledText {
            text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
            font: Tokens.font.body.small
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
            font: Tokens.font.icon.extraLarge
            color: weatherStat.colour
        }

        Column {
            StyledText {
                text: weatherStat.label
                font: Tokens.font.body.builders.small.scale(.8).build()
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: weatherStat.value
                font: Tokens.font.body.builders.small.weight(600).build()
                color: Colours.palette.m3onSurface
            }
        }
    }
}
