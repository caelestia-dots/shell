pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property int rootHeight

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Appearance.padding.large * 2

    spacing: Appearance.spacing.small

    Loader {
        Layout.topMargin: Appearance.padding.large * 2
        Layout.bottomMargin: -Appearance.padding.large
        Layout.alignment: Qt.AlignHCenter

        asynchronous: true
        active: root.rootHeight > 610
        visible: active

        sourceComponent: StyledText {
            text: qsTr("Weather")
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.extraLarge
            font.weight: 500
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.large

        MaterialIcon {
            animate: true
            text: Weather.icon
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge * 2.5
        }

        ColumnLayout {
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true

                animate: true
                text: Weather.description
                color: Colours.palette.m3secondary
                font.pointSize: Appearance.font.size.large
                font.weight: 500
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true

                animate: true
                text: qsTr("Humidity: %1%").arg(Weather.humidity)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
            }
        }

        Loader {
            Layout.rightMargin: Appearance.padding.smaller
            asynchronous: true
            active: root.width > 400
            visible: active

            sourceComponent: ColumnLayout {
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.fillWidth: true

                    animate: true
                    text: Weather.temp
                    color: Colours.palette.m3primary
                    horizontalAlignment: Text.AlignRight
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                    elide: Text.ElideLeft
                }

                StyledText {
                    Layout.fillWidth: true

                    animate: true
                    text: qsTr("Feels like: %1").arg(Weather.feelsLike)
                    color: Colours.palette.m3outline
                    horizontalAlignment: Text.AlignRight
                    font.pointSize: Appearance.font.size.smaller
                    elide: Text.ElideLeft
                }
            }
        }
    }

    Loader {
        id: forecastLoader

        Layout.topMargin: Appearance.spacing.smaller
        Layout.bottomMargin: Appearance.padding.large * 2
        Layout.fillWidth: true

        asynchronous: true
        active: root.rootHeight > 820
        visible: active

        sourceComponent: RowLayout {
            spacing: Appearance.spacing.large

            Repeater {
                model: {
                    const forecast = Weather.forecast;
                    let count = root.width < 320 ? 3 : root.width < 400 ? 4 : 5;
                    if (!forecast)
                        return Array.from({
                            length: count
                        }, () => null);

                    const hours = [];
                    const hour = new Date().getHours();

                    const today = forecast[0].hourly;
                    const arr = [...today, ...forecast[1].hourly];
                    for (let i = 0; i < arr.length; i++) {
                        const time = parseInt(arr[i].time, 10) / 100;

                        if (i > today.length ? time < hour : time > hour) {
                            hours.push(arr[i]);
                            count--;
                        }

                        if (count === 0)
                            break;
                    }

                    return hours;
                }

                ColumnLayout {
                    id: forecastHour

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            if (!forecastHour.modelData)
                                return "00 AM";
                            const hour = parseInt(forecastHour.modelData.time, 10) / 100;
                            return hour > 12 ? `${(hour - 12).toString().padStart(2, "0")} PM` : `${hour.toString().padStart(2, "0")} AM`;
                        }
                        color: Colours.palette.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        font.pointSize: Appearance.font.size.larger
                    }

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: forecastHour.modelData ? Icons.getWeatherIcon(forecastHour.modelData.weatherCode) : "cloud_alert"
                        font.pointSize: Appearance.font.size.extraLarge * 1.5
                        font.weight: 500
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Config.services.useFahrenheit ? `${forecastHour.modelData?.tempF ?? 0}°F` : `${forecastHour.modelData?.tempC ?? 0}°C`
                        color: Colours.palette.m3secondary
                        font.pointSize: Appearance.font.size.larger
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
