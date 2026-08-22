import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var lock
    required property bool isPortrait
    required property real lockHeight

    // Portrait layout
    ColumnLayout {
        anchors.fill: parent
        visible: root.isPortrait
        spacing: Tokens.spacing.medium

        WeatherInfo {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Center {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraLargeIncreased
            Layout.bottomMargin: Tokens.spacing.large
            isPortrait: true
            lock: root.lock
            lockHeight: root.lockHeight
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: Tokens.spacing.largeIncreased

            Fetch {
                Layout.fillWidth: true
                Layout.fillHeight: true
                rootHeight: root.height
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                bottomRightRadius: Tokens.rounding.extraLarge
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainer

                NotifDock {
                    lock: root.lock
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: Tokens.spacing.largeIncreased

            Media {
                Layout.fillWidth: true
                Layout.fillHeight: true
                lock: root.lock
            }

            Resources {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    // Landscape layout
    RowLayout {
        anchors.fill: parent
        visible: !root.isPortrait
        spacing: Tokens.spacing.largeIncreased * 2

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            WeatherInfo {
                Layout.fillWidth: true
                rootHeight: root.height
            }

            Fetch {
                Layout.fillWidth: true
                rootHeight: root.height
            }

            Media {
                Layout.fillWidth: true
                Layout.fillHeight: true

                lock: root.lock
            }
        }

        Center {
            lock: root.lock
            lockHeight: root.lockHeight
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Resources {
                Layout.fillWidth: true
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                bottomRightRadius: Tokens.rounding.extraLarge
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainer

                NotifDock {
                    lock: root.lock
                }
            }
        }
    }
}
