import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

RowLayout {
    id: bigInfo

    spacing: Appearance.spacing.small
    implicitHeight: hourlyForecast.implicitHeight

    Layout.fillWidth: true

    // Main column
    ColumnLayout {
        spacing: Appearance.spacing.small
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledRect {
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                id: bigInfoRow

                anchors.centerIn: parent
                spacing: Appearance.spacing.large
                Layout.fillWidth: true
                Layout.fillHeight: true

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: Weather.icon
                    font.pointSize: Appearance.font.size.extraLarge * 3
                    color: Colours.palette.m3secondary
                    animate: true
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -Appearance.spacing.small

                    StyledText {
                        text: Weather.temp
                        font.pointSize: Appearance.font.size.extraLarge * 2
                        font.weight: 500
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.leftMargin: Appearance.padding.small
                        text: Weather.description
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        RowLayout {
            id: detailCardRow

            Layout.fillWidth: true
            spacing: Appearance.spacing.smaller

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
    }

    component DetailCard: StyledRect {
        id: detailRoot

        property string icon
        property string label
        property string value
        property color colour

        Layout.fillWidth: true
        Layout.preferredHeight: 60
        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: detailRoot.icon
                color: detailRoot.colour
                font.pointSize: Appearance.font.size.large
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    text: detailRoot.label
                    font.pointSize: Appearance.font.size.smaller
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
