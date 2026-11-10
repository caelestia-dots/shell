pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property bool compact: false

    readonly property bool isCelsius: Weather.isCelsius

    implicitWidth: layout.implicitWidth + (compact ? Tokens.padding.extraSmall : Tokens.padding.small) * 2
    implicitHeight: layout.implicitHeight + (compact ? Tokens.padding.extraSmall / 2 : Tokens.padding.small) * 2

    radius: height / 2
    color: Colours.tPalette.m3surfaceContainerHigh

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: root.compact ? 2 : Tokens.spacing.extraSmall

        StyledRect {
            id: cBtn

            implicitWidth: cText.implicitWidth + (root.compact ? Tokens.padding.small : Tokens.padding.medium) * 2
            implicitHeight: cText.implicitHeight + (root.compact ? Tokens.padding.extraSmall : Tokens.padding.small) * 2
            radius: height / 2
            color: root.isCelsius ? Colours.palette.m3primary : "transparent"

            StyledText {
                id: cText

                anchors.centerIn: parent
                text: "°C"
                font: root.isCelsius ? Tokens.font.body.builders.small.weight(Font.Bold).build() : Tokens.font.body.small
                color: root.isCelsius ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            }

            StateLayer {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Weather.setUnit(TemperatureUnit.Celsius)
            }
        }

        StyledRect {
            id: fBtn

            implicitWidth: fText.implicitWidth + (root.compact ? Tokens.padding.small : Tokens.padding.medium) * 2
            implicitHeight: fText.implicitHeight + (root.compact ? Tokens.padding.extraSmall : Tokens.padding.small) * 2
            radius: height / 2
            color: !root.isCelsius ? Colours.palette.m3primary : "transparent"

            StyledText {
                id: fText

                anchors.centerIn: parent
                text: "°F"
                font: !root.isCelsius ? Tokens.font.body.builders.small.weight(Font.Bold).build() : Tokens.font.body.small
                color: !root.isCelsius ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            }

            StateLayer {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Weather.setUnit(TemperatureUnit.Fahrenheit)
            }
        }
    }
}
