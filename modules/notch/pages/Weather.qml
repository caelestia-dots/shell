pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services
import qs.utils
import qs.modules.notch
import qs.modules.notch.pages.weather

NotchPage {
    id: root

    property bool showHourly

    function hourlyIcon(item: var): string {
        if (!item)
            return "";
        const h = item.hour ?? 12;
        if (h < 6 || h >= 20) {
            if (item.icon === "clear_day")
                return "clear_night";
            if (item.icon === "partly_cloudy_day")
                return "partly_cloudy_night";
        }
        return item.icon;
    }

    implicitWidth: 620
    implicitHeight: layout.implicitHeight

    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.small + 2

        Item {
            Layout.fillWidth: true
            implicitHeight: hero.implicitHeight + Tokens.padding.large * 2

            WeatherScene {
                id: scene

                anchors.fill: parent
                kind: mainIcon.kind
                night: Weather.isNight
            }

            // Fallback obsidian card when animated weather scenes are turned off
            HkCard {
                anchors.fill: parent
                visible: !NotchSettings.values.animWeather
                ornate: true
            }

            RowLayout {
                id: hero

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                HoverHandler {
                    id: mainHover
                }

                WeatherIcon {
                    id: mainIcon

                    icon: Weather.icon
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                    colour: Hallownest.soul
                    animate: true
                    active: mainHover.hovered
                }

                ColumnLayout {
                    spacing: 2

                    StyledText {
                        text: Weather.temp
                        color: Hallownest.soul
                        font.family: Hallownest.mono
                        font.pointSize: 32
                        font.weight: Font.Bold
                    }

                    StyledText {
                        text: Weather.description
                        color: Hallownest.text
                        font.pointSize: 10
                        font.weight: Font.Medium
                    }

                    Row {
                        spacing: 5

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "location_on"
                            color: Hallownest.subtext
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.city || Tr.tr("Loading...")
                            color: Hallownest.subtext
                            font.pointSize: 8.5
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: scene.biomeName !== "" && NotchSettings.values.animWeather
                            width: 3.5
                            height: 3.5
                            rotation: 45
                            color: Qt.alpha(scene.accent, 0.75)
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: scene.biomeName !== "" && NotchSettings.values.animWeather
                            text: scene.biomeName
                            color: Hallownest.subtext
                            font.family: Hallownest.serif
                            font.pointSize: 8.5
                            font.letterSpacing: 0.4
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                GridLayout {
                    columns: 2
                    rowSpacing: Tokens.spacing.small
                    columnSpacing: Tokens.spacing.large

                    Stat {
                        icon: "thermostat"
                        value: Weather.feelsLike
                        colour: Hallownest.lifeblood
                    }

                    Stat {
                        icon: "water_drop"
                        value: Strings.percent(Weather.humidity)
                        colour: Hallownest.crystal
                    }

                    Stat {
                        icon: "air"
                        value: Weather.windSpeed ? Tr.tr("%1 km/h").arg(Weather.windSpeed) : "--"
                        colour: Hallownest.steel
                    }

                    Stat {
                        icon: "wb_twilight"
                        value: `${Weather.sunrise}–${Weather.sunset}`
                        colour: Hallownest.gold
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: root.showHourly ? Tr.tr("Next hours") : Tr.tr("7-day forecast")
                color: Hallownest.faint
                font.pointSize: 7.5
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.8
            }

            HkDivider {
                Layout.fillWidth: true
                opacity: 0.5
            }

            Rectangle {
                visible: Weather.hourlyForecast.length > 0
                implicitWidth: modeRow.implicitWidth + 6
                implicitHeight: 24
                radius: 12
                color: Hallownest.void_
                border.width: 1
                border.color: Hallownest.border

                Row {
                    id: modeRow

                    anchors.centerIn: parent
                    spacing: 2

                    ModeTab {
                        label: Tr.tr("Daily")
                        active: !root.showHourly
                        onClicked: root.showHourly = false
                    }

                    ModeTab {
                        label: Tr.tr("Hourly")
                        active: root.showHourly
                        onClicked: root.showHourly = true
                    }
                }
            }
        }

        // 7-day forecast row
        RowLayout {
            Layout.fillWidth: true
            visible: !root.showHourly
            spacing: Tokens.spacing.small

            Repeater {
                model: Weather.forecast

                Rectangle {
                    id: day

                    required property int index
                    required property var modelData
                    readonly property bool isToday: index === 0

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: dayColumn.implicitHeight + Tokens.padding.small * 2 + 4
                    radius: 12
                    color: dayHover.hovered ? Hallownest.raise(Hallownest.card, 1.35) : Hallownest.card
                    border.width: 1
                    border.color: isToday ? Qt.alpha(Hallownest.soul, 0.28) : Hallownest.border

                    Behavior on color {
                        CAnim {}
                    }

                    // Subtle top rim highlight on Today and hover
                    Rectangle {
                        visible: day.isToday || dayHover.hovered
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: day.radius
                        anchors.rightMargin: day.radius
                        height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal

                            GradientStop {
                                position: 0
                                color: "transparent"
                            }
                            GradientStop {
                                position: 0.5
                                color: Qt.alpha(Hallownest.soul, Hallownest.light ? 0.18 : 0.14)
                            }
                            GradientStop {
                                position: 1
                                color: "transparent"
                            }
                        }
                    }

                    HoverHandler {
                        id: dayHover
                    }

                    ColumnLayout {
                        id: dayColumn

                        anchors.centerIn: parent
                        spacing: 4

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: day.isToday ? Tr.trCtx("Today", "forecast column") : new Date(day.modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                                color: day.isToday ? Hallownest.soul : Hallownest.subtext
                                font.pointSize: 7.5
                                font.weight: Font.DemiBold
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.5
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: day.isToday
                                width: 4
                                height: 4
                                rotation: 45
                                color: Hallownest.soul
                            }
                        }

                        WeatherIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: day.modelData.icon
                            colour: day.isToday || dayHover.hovered ? Hallownest.soul : Hallownest.text
                            active: dayHover.hovered
                        }

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4

                            StyledText {
                                text: Weather.formatTemp(day.modelData.maxTempC, true)
                                color: Hallownest.soul
                                font.family: Hallownest.mono
                                font.pointSize: 8.5
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                text: Weather.formatTemp(day.modelData.minTempC, true)
                                color: Hallownest.faint
                                font.family: Hallownest.mono
                                font.pointSize: 8
                            }
                        }
                    }
                }
            }
        }

        // Next 7 hours forecast row
        RowLayout {
            Layout.fillWidth: true
            visible: root.showHourly
            spacing: Tokens.spacing.small

            Repeater {
                model: Weather.hourlyForecast.slice(0, 7)

                Rectangle {
                    id: slot

                    required property int index
                    required property var modelData
                    readonly property bool isNext: index === 0

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: slotColumn.implicitHeight + Tokens.padding.small * 2 + 4
                    radius: 12
                    color: slotHover.hovered ? Hallownest.raise(Hallownest.card, 1.35) : Hallownest.card
                    border.width: 1
                    border.color: isNext ? Qt.alpha(Hallownest.soul, 0.28) : Hallownest.border

                    Behavior on color {
                        CAnim {}
                    }

                    HoverHandler {
                        id: slotHover
                    }

                    ColumnLayout {
                        id: slotColumn

                        anchors.centerIn: parent
                        spacing: 4

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: `${String(slot.modelData.hour).padStart(2, "0")}:00`
                            color: slot.isNext ? Hallownest.soul : Hallownest.subtext
                            font.family: Hallownest.mono
                            font.pointSize: 7.5
                            font.weight: slot.isNext ? Font.Bold : Font.Medium
                        }

                        WeatherIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: root.hourlyIcon(slot.modelData)
                            colour: slot.isNext || slotHover.hovered ? Hallownest.soul : Hallownest.text
                            active: slotHover.hovered
                        }

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4

                            StyledText {
                                text: Weather.formatTemp(slot.modelData.tempC, true)
                                color: Hallownest.soul
                                font.family: Hallownest.mono
                                font.pointSize: 8.5
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                visible: (slot.modelData.precipChance ?? 0) > 0
                                text: `${slot.modelData.precipChance}%`
                                color: Hallownest.lifeblood
                                font.family: Hallownest.mono
                                font.pointSize: 7.5
                            }
                        }
                    }
                }
            }
        }
    }

    component Stat: Row {
        id: stat

        property string icon
        property string value
        property color colour

        spacing: Tokens.spacing.small

        WeatherIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: stat.icon
            colour: stat.colour
            size: 18
            glow: false
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: stat.value
            color: Hallownest.text
            font.family: Hallownest.mono
            font.pointSize: 8.5
            font.weight: Font.Medium
        }
    }

    component ModeTab: Rectangle {
        id: tab

        property string label
        property bool active

        signal clicked

        implicitWidth: tabText.implicitWidth + 14
        implicitHeight: 18
        radius: 9
        color: active ? Qt.alpha(Hallownest.soul, 0.14) : tabArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.45) : "transparent"

        Behavior on color {
            CAnim {}
        }

        StyledText {
            id: tabText

            anchors.centerIn: parent
            text: tab.label
            color: tab.active || tabArea.containsMouse ? Hallownest.soul : Hallownest.subtext
            font.pointSize: 7.5
            font.weight: tab.active ? Font.DemiBold : Font.Medium
        }

        MouseArea {
            id: tabArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tab.clicked()
        }
    }
}
