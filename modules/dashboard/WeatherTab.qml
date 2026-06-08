import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    readonly property var today: Weather.forecast && Weather.forecast.length > 0 ? Weather.forecast[0] : null

    implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840
    implicitHeight: layout.implicitHeight
    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            Layout.fillWidth: true

            Column {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: Weather.city || qsTr("Loading...")
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
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
                spacing: Tokens.spacing.largeIncreased

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
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: bigInfoRow.implicitHeight + Tokens.padding.small

            radius: Tokens.rounding.extraLarge * 2
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: bigInfoRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: Weather.icon
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(3).build()
                    color: Colours.palette.m3secondary
                    animate: true
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -Tokens.spacing.small

                    StyledText {
                        text: Weather.temp
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Medium).build()
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.leftMargin: Tokens.padding.extraSmall
                        text: Weather.description
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

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

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            Layout.leftMargin: Tokens.padding.medium
            visible: forecastRepeater.count > 0
            text: qsTr("7-Day Forecast")
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Repeater {
                id: forecastRepeater

                model: Weather.forecast

                StyledRect {
                    id: forecastItem

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: forecastItemColumn.implicitHeight + Tokens.padding.medium * 2

                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: forecastItemColumn

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: forecastItem.index === 0 ? qsTr("Today") : new Date(forecastItem.modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.topMargin: -Tokens.spacing.extraSmall
                            Layout.alignment: Qt.AlignHCenter
                            text: new Date(forecastItem.modelData.date).toLocaleDateString(Qt.locale(), "MMM d")
                            font: Tokens.font.body.small
                            opacity: 0.7
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: forecastItem.modelData.icon
                            fontStyle: Tokens.font.icon.extraLarge
                            color: Colours.palette.m3secondary
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: GlobalConfig.services.useFahrenheit ? forecastItem.modelData.maxTempF + "°" + " / " + forecastItem.modelData.minTempF + "°" : forecastItem.modelData.maxTempC + "°" + " / " + forecastItem.modelData.minTempC + "°"
                            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                            color: Colours.palette.m3tertiary
                        }
                    }
                }
            }
        }
    }

    component DetailCard: StyledRect {
        id: detailRoot

        property string icon
        property string label
        property string value
        property color colour

        Layout.fillWidth: true
        Layout.preferredHeight: 60
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer

        Row {
            anchors.centerIn: parent
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: detailRoot.icon
                color: detailRoot.colour
                fontStyle: Tokens.font.icon.large
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
                    font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                    horizontalAlignment: Text.AlignLeft
                }
            }
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
            fontStyle: Tokens.font.icon.extraLarge
            color: weatherStat.colour
        }

        Column {
            StyledText {
                text: weatherStat.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
            StyledText {
                text: weatherStat.value
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
            }
        }
    }
}
