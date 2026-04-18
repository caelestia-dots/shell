import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    required property var lock

    spacing: Tokens.spacing.large * 2

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: weather.implicitHeight

            topLeftRadius: Tokens.rounding.large
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            WeatherInfo {
                id: weather

                rootHeight: root.height
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Fetch {}
        }

        StyledClippingRect {
            Layout.fillWidth: true
            implicitHeight: media.implicitHeight

            bottomLeftRadius: Tokens.rounding.large
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Media {
                id: media

                lock: root.lock
            }
        }
    }

    Center {
        lock: root.lock
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: resources.implicitHeight

            topRightRadius: Tokens.rounding.large
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Resources {
                id: resources
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            bottomRightRadius: Tokens.rounding.large
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            NotifDock {
                lock: root.lock
            }
        }
    }
}
