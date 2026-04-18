pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property int rootHeight

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Tokens.padding.large * 2

    spacing: Tokens.spacing.small

    Loader {
        asynchronous: true
        Layout.topMargin: Tokens.padding.large * 2
        Layout.bottomMargin: -Tokens.padding.large
        Layout.alignment: Qt.AlignHCenter

        active: root.rootHeight > 610
        visible: active

        sourceComponent: StyledText {
            text: qsTr("Weather")
            color: Colours.palette.m3primary
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 500
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.large

        MaterialIcon {
            animate: true
            text: Weather.icon
            color: Colours.palette.m3secondary
            font.pointSize: Tokens.font.size.extraLarge * 2.5
        }

        ColumnLayout {
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true

                animate: true
                text: Weather.description
                color: Colours.palette.m3secondary
                font.pointSize: Tokens.font.size.large
                font.weight: 500
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true

                animate: true
                text: qsTr("Humidity: %1%").arg(Weather.humidity)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal
                elide: Text.ElideRight
            }
        }

        Loader {
            asynchronous: true
            Layout.rightMargin: Tokens.padding.smaller
            active: root.width > 400
            visible: active

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true

                    animate: true
                    text: Weather.temp
                    color: Colours.palette.m3primary
                    horizontalAlignment: Text.AlignRight
                    font.pointSize: Tokens.font.size.extraLarge
                    font.weight: 500
                    elide: Text.ElideLeft
                }

                StyledText {
                    Layout.fillWidth: true

                    animate: true
                    text: qsTr("Feels like: %1").arg(Weather.feelsLike)
                    color: Colours.palette.m3outline
                    horizontalAlignment: Text.AlignRight
                    font.pointSize: Tokens.font.size.smaller
                    elide: Text.ElideLeft
                }
            }
        }
    }

    Loader {
        id: forecastLoader

        asynchronous: true
        Layout.topMargin: Tokens.spacing.smaller
        Layout.bottomMargin: Tokens.padding.large * 2
        Layout.fillWidth: true

        active: root.rootHeight > 820
        visible: active

        sourceComponent: RowLayout {
            spacing: Tokens.spacing.large

            Repeater {
                model: {
                    const forecast = Weather.hourlyForecast;
                    const count = root.width < 320 ? 3 : root.width < 400 ? 4 : 5;
                    if (!forecast)
                        return Array.from({
                            length: count
                        }, () => null);

                    return forecast.slice(0, count);
                }

                ColumnLayout {
                    id: forecastHour

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            const hour = forecastHour.modelData?.hour ?? 0;
                            return hour > 12 ? `${(hour - 12).toString().padStart(2, "0")} PM` : `${hour.toString().padStart(2, "0")} AM`;
                        }
                        color: Colours.palette.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        font.pointSize: Tokens.font.size.larger
                    }

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: forecastHour.modelData?.icon ?? "cloud_alert"
                        font.pointSize: Tokens.font.size.extraLarge * 1.5
                        font.weight: 500
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: GlobalConfig.services.useFahrenheit ? `${forecastHour.modelData?.tempF ?? 0}°F` : `${forecastHour.modelData?.tempC ?? 0}°C`
                        color: Colours.palette.m3secondary
                        font.pointSize: Tokens.font.size.larger
                    }
                }
            }
        }
    }

    Timer {
        running: true
        triggeredOnStart: true
        repeat: true
        interval: 900000 // 15 minutes
        onTriggered: Weather.reload()
    }
}
