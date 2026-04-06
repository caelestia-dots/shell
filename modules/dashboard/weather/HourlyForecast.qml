import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

ColumnLayout {

    StyledText {
        Layout.topMargin: Appearance.spacing.normal
        Layout.leftMargin: Appearance.padding.normal
        visible: hourlyRepeater.count > 0
        text: qsTr("Hourly Forecast")
        font.pointSize: Appearance.font.size.normal
        font.weight: 600
        color: Colours.palette.m3onSurface

    }

    Flickable {
        id: hourlyFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        contentHeight: hourlyRow.implicitHeight
        contentWidth: hourlyRow.implicitWidth
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        RowLayout {
            id: hourlyRow
            spacing: Appearance.spacing.normal

            Repeater {
                id: hourlyRepeater
                model: Weather.hourlyForecast

                HourlyForecastItem {}

            }

        }

    }

    component HourlyForecastItem: StyledRect {
        required property var modelData

        property var timestamp: modelData?.timestamp
        property var hour: modelData?.hour ?? 0
        property var icon: modelData?.icon ?? "cloud_alert"
        property var tempF: modelData?.tempF ?? 0
        property var tempC: modelData?.tempC ?? 0
        property var precipitationProbability: modelData?.precipitationProbability ?? "?"

        Layout.fillWidth: true
        implicitHeight: hourlyForecastItemColumn.implicitHeight + Appearance.padding.normal * 2
        implicitWidth: Appearance.padding.large * 8
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: hourlyForecastItemColumn
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            RowLayout {

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        const hourLocalized = hour > 12 ? `${(hour - 12).toString().padStart(2, "0")}PM` : `${hour.toString().padStart(2, "0")}AM`;
                        return hourLocalized
                    }
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 600
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: new Date(timestamp).toLocaleDateString(Qt.locale(), "(ddd)")
                    font.pointSize: Appearance.font.size.small
                    opacity: 0.7
                    color: Colours.palette.m3onSurfaceVariant
                }

            }

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: icon
                font.pointSize: Appearance.font.size.extraLarge
                color: Colours.palette.m3secondary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    var temp = Config.services.useFahrenheit ? `${tempF}°F` : `${tempC}°C`
                    var rain = `${precipitationProbability}%`
                    return `${temp} / ${rain}`
                }
                font.weight: 600
                color: Colours.palette.m3tertiary

            }

        }

    }

}