import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

ColumnLayout {
    StyledText {
        Layout.topMargin: Appearance.spacing.normal
        Layout.leftMargin: Appearance.padding.normal
        visible: dailyRepeater.count > 0
        text: qsTr("7-Day Forecast")
        font.pointSize: Appearance.font.size.normal
        font.weight: 600
        color: Colours.palette.m3onSurface
    }

    RowLayout {
        id: dailyForecast

        Layout.fillWidth: true
        spacing: Appearance.spacing.smaller

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
        property var maxTempF: modelData?.maxTempF ?? 0
        property var maxTempC: modelData?.maxTempC ?? 0
        property var minTempF: modelData?.minTempF ?? 0
        property var minTempC: modelData?.minTempC ?? 0

        Layout.fillWidth: true
        implicitHeight: forecastItemColumn.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: forecastItemColumn

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: dailyForecastItem.index === 0 ? qsTr("Today") : new Date(dailyForecastItem.date).toLocaleDateString(Qt.locale(), "ddd")
                font.pointSize: Appearance.font.size.normal
                font.weight: 600
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.topMargin: -Appearance.spacing.small / 2
                Layout.alignment: Qt.AlignHCenter
                text: new Date(dailyForecastItem.date).toLocaleDateString(Qt.locale(), "MMM d")
                font.pointSize: Appearance.font.size.small
                opacity: 0.7
                color: Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: dailyForecastItem.icon
                font.pointSize: Appearance.font.size.extraLarge
                color: Colours.palette.m3secondary
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacing.small / 2

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `${Config.services.useFahrenheit ? dailyForecastItem.maxTempF : dailyForecastItem.maxTempC}°`
                    font.weight: 600
                    color: Colours.palette.m3tertiary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `(${Config.services.useFahrenheit ? dailyForecastItem.minTempF : dailyForecastItem.minTempC}°)`
                    font.pointSize: Appearance.font.size.small
                    opacity: 0.7
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
