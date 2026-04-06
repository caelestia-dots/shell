import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services


RowLayout {
    id: bigInfo

    // anchors.centerIn: parent
    spacing: Appearance.spacing.normal
        implicitHeight: detailCardColumn + Appearance.padding.small * 2


    StyledRect {
        Layout.fillWidth: true
        height: detailCardColumn.implicitHeight
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: bigInfoRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.large

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

    ColumnLayout {
        id: detailCardColumn
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

    component DetailCard: StyledRect {
        id: detailRoot

        property string icon
        property string label
        property string value
        property color colour

        Layout.preferredWidth: 150
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