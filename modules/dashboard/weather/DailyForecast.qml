import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    StyledText {
        Layout.topMargin: Tokens.spacing.medium
        Layout.leftMargin: Tokens.padding.medium
        visible: dailyRepeater.count > 0
        text: qsTr("7-Day Forecast")
        font: Tokens.font.body.builders.medium.weight(600).build()
        color: Colours.palette.m3onSurface
    }

    RowLayout {
        id: dailyForecast

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: dailyRepeater

            model: Weather.forecast

            DailyForecastItem {}
        }
    }

    component DailyForecastItem: StyledRect {
        id: dailyForecastItem

        required property int index
        required property var modelData

        property var date: modelData?.date
        property var icon: modelData?.icon ?? "cloud_alert"
        property var maxTemp: modelData?.maxTemp ?? 0
        property var minTemp: modelData?.minTemp ?? 0

        Layout.fillWidth: true
        implicitHeight: forecastItemColumn.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: forecastItemColumn

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: dailyForecastItem.index === 0 ? qsTr("Today") : new Date(dailyForecastItem.date).toLocaleDateString(Qt.locale(), "ddd")
                font: Tokens.font.body.builders.medium.weight(600).build()
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.topMargin: -Tokens.spacing.small / 2
                Layout.alignment: Qt.AlignHCenter
                text: new Date(dailyForecastItem.date).toLocaleDateString(Qt.locale(), "MMM d")
                font: Tokens.font.body.small
                opacity: 0.7
                color: Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: dailyForecastItem.icon
                font: Tokens.font.icon.extraLarge
                color: Colours.palette.m3secondary
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small / 2

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `${dailyForecastItem.maxTemp}°`
                    font: Tokens.font.body.builders.small.weight(600).build()
                    color: Colours.palette.m3tertiary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `(${dailyForecastItem.minTemp}°)`
                    font: Tokens.font.body.small
                    opacity: 0.7
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
