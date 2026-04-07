import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

ListView {
    id: hourlyForecastList

    spacing: Appearance.spacing.small
    width: contentItem.childrenRect.width
    height: (contentItem.children[0]?.height ?? 60) * 3 + spacing * 2
    clip: true

    model: Weather.hourlyForecast
    delegate: HourlyForecastItem {}

    component HourlyForecastItem: StyledRect {
        id: hourlyForecastItem

        required property var modelData

        property var timestamp: modelData?.timestamp
        property var hour: modelData?.hour ?? 0
        property var icon: modelData?.icon ?? "cloud_alert"
        property var tempF: modelData?.tempF ?? 0
        property var tempC: modelData?.tempC ?? 0
        property var precipitationProbability: modelData?.precipitationProbability ?? "?"

        implicitHeight: hourlyForecastItemRow.implicitHeight + Appearance.padding.normal * 2
        implicitWidth: hourlyForecastItemRow.implicitWidth + Appearance.padding.normal * 2
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: hourlyForecastItemRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            Column {
                Layout.alignment: Qt.AlignCenter

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: hourlyForecastItem.hour > 12 ? `${(hourlyForecastItem.hour - 12).toString().padStart(2, "0")}PM` : `${hourlyForecastItem.hour.toString().padStart(2, "0")}AM`
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 600
                    color: Colours.palette.m3primary
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: new Date(hourlyForecastItem.timestamp).toLocaleDateString(Qt.locale(), "(ddd)")
                    font.pointSize: Appearance.font.size.small
                    opacity: 0.7
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: hourlyForecastItem.icon
                font.pointSize: Appearance.font.size.extraLarge
                color: Colours.palette.m3secondary
            }

            Column {
                Layout.alignment: Qt.AlignCenter

                StyledText {
                    anchors.right: parent.right
                    text: Config.services.useFahrenheit ? `${hourlyForecastItem.tempF}°F` : `${hourlyForecastItem.tempC}°C`
                    font.weight: 600
                    color: Colours.palette.m3tertiary
                }

                StyledText {
                    anchors.right: parent.right
                    Layout.alignment: Qt.AlignHCenter
                    text: `${hourlyForecastItem.precipitationProbability}%`
                    font.weight: 600
                    color: Colours.palette.m3tertiary
                }
            }
        }
    }
}
