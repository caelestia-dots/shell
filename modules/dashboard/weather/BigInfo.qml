import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: bigInfo

    property int visibleHourlyForecastItemsCount: 3

    spacing: Tokens.spacing.small
    implicitHeight: hourlyForecast.implicitHeight
    Layout.fillWidth: true

    ColumnLayout {
        spacing: Tokens.spacing.small
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledRect {
            radius: Tokens.rounding.large * 2

            color: Colours.tPalette.m3surfaceContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                id: bigInfoRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.large
                Layout.fillWidth: true
                Layout.fillHeight: true

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: Weather.icon
                    font: Tokens.font.icon.builders.extraLarge.scale(3).weight(500).build()
                    color: Colours.palette.m3secondary
                    animate: true
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -Tokens.spacing.small

                    StyledText {
                        text: Weather.temp
                        font: Tokens.font.body.builders.large.scale(2).weight(500).build()
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.leftMargin: Tokens.padding.small
                        text: Weather.description
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        RowLayout {
            id: detailCardRow

            Layout.fillWidth: true
            // Match the size of one `hourlyForecastItem`.
            Layout.preferredHeight: {
                var totalHeight = bigInfo.implicitHeight;
                var itemCount = bigInfo.visibleHourlyForecastItemsCount;
                var totalSpacing = (itemCount - 1) * Tokens.spacing.small;
                return (totalHeight - totalSpacing) / itemCount;
            }
            spacing: Tokens.spacing.small

            DetailCard {
                icon: "water_drop"
                label: "Humidity"
                value: Weather.humidity + "%"
                colour: Colours.palette.m3secondary
            }

            DetailCard {
                icon: "thermostat"
                label: "Feels Like"
                value: Weather.feelsLike
                colour: Colours.palette.m3primary
            }

            DetailCard {
                icon: "air"
                label: "Wind"
                value: Weather.windSpeed ? Weather.windSpeed + " km/h" : "--"
                colour: Colours.palette.m3tertiary
            }
        }
    }

    HourlyForecast {
        id: hourlyForecast

        visibleItemsCount: bigInfo.visibleHourlyForecastItemsCount
    }

    component DetailCard: StyledRect {
        id: detailRoot

        property string icon
        property string label
        property string value
        property color colour

        Layout.fillWidth: true
        Layout.preferredHeight: parent.height
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer

        Row {
            anchors.centerIn: parent
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: detailRoot.icon
                color: detailRoot.colour
                font: Tokens.font.icon.large
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    text: detailRoot.label
                    font: Tokens.font.body.small
                    opacity: 0.7
                    horizontalAlignment: Text.AlignLeft
                }

                StyledText {
                    text: detailRoot.value
                    font.weight: 600
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }
}
