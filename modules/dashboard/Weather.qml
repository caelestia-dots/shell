import qs.components
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitWidth: weather_dashboard.implicitWidth > 800 ? weather_dashboard.implicitWidth + (Appearance.padding.large * 2) : 850
    implicitHeight: weather_dashboard.implicitHeight + (Appearance.padding.large * 2)

    readonly property var today: Weather.forecast && Weather.forecast.length > 0 ? Weather.forecast[0] : null

    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: weather_dashboard
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            
            Column {
                Layout.alignment: Qt.AlignLeft
                spacing: 0
                StyledText {
                    text: Weather.city || "Loading..."
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

            Item { Layout.fillWidth: true }

            Row {
                spacing: Appearance.spacing.large
                
                WeatherStat { 
                    icon: "wb_twilight"
                    label: "Sunrise"
                    value: Weather.cc ? Weather.cc.sunrise : "--:--"
                    colour: Colours.palette.m3tertiary
                }
                WeatherStat { 
                    icon: "bedtime"
                    label: "Sunset"
                    value: Weather.cc ? Weather.cc.sunset : "--:--"
                    colour: Colours.palette.m3tertiary
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 160
            radius: Appearance.rounding.normal
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Appearance.spacing.large

                MaterialIcon {
                    text: Weather.icon
                    font.pointSize: Appearance.font.size.extraLarge * 3.5
                    color: Colours.palette.m3secondary
                    animate: true
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    StyledText {
                        text: Weather.temp
                        font.pointSize: Appearance.font.size.extraLarge * 2
                        font.weight: 700
                        color: Colours.palette.m3primary
                    }
                    StyledText {
                        text: Weather.description
                        font.pointSize: Appearance.font.size.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

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
            text: qsTr("7-Day Forecast")
            font.pointSize: Appearance.font.size.medium
            font.weight: 600
            color: Colours.palette.m3onSurface
            Layout.topMargin: Appearance.spacing.medium
        }

        StyledRect {
            implicitWidth: forecastRow.implicitWidth
            implicitHeight: forecastRow.implicitHeight

            Row {
                id: forecastRow
                spacing: Appearance.spacing.normal

                Repeater {
                    model: Weather.forecast
                    
                    StyledRect {
                        width: 110
                        height: 150
                        radius: Appearance.rounding.normal
                        color: Colours.palette.m3surfaceContainer

                        Column {
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: index === 0 ? qsTr("Today") : new Date(modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                                font.pointSize: Appearance.font.size.medium
                                font.weight: 600
                                color: Colours.palette.m3primary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: new Date(modelData.date).toLocaleDateString(Qt.locale(), "MMM d")
                                font.pointSize: Appearance.font.size.small
                                opacity: 0.7
                                color: Colours.palette.m3onSurfaceVariant
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            MaterialIcon {
                                text: modelData.icon
                                font.pointSize: Appearance.font.size.extraLarge
                                color: Colours.palette.m3secondary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: Config.services.useFahrenheit ? 
                                    modelData.maxTempF + "°" + " / " + modelData.minTempF + "°": 
                                    modelData.maxTempC + "°" + " / " + modelData.minTempC + "°"
                                font.weight: 600
                                color: Colours.palette.m3tertiary
                            }
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
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainer

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: icon
                color: colour
                font.pointSize: Appearance.font.size.large
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: -2

                StyledText { 
                    text: label
                    font.pointSize: Appearance.font.size.smaller
                    opacity: 0.7 
                    horizontalAlignment: Text.AlignLeft 
                }
                StyledText { 
                    text: value
                    font.weight: 600
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }

    component WeatherStat: Row {
        property string icon
        property string label
        property string value
        property color colour
        spacing: Appearance.spacing.small
        
        MaterialIcon { 
            text: icon
            font.pointSize: Appearance.font.size.extraLarge
            color: colour
        }
        Column {
            StyledText { 
                text: label
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }
            StyledText { 
                text: value
                font.pointSize: Appearance.font.size.small
                font.weight: 600
                color: Colours.palette.m3onSurface
            }
        }
    }
}