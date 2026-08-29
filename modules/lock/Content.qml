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

    // Both arrangements are built and shown by orientation rather than swapped
    // through a Loader - a monitor doesn't rotate while the screen is locked,
    // and this keeps the two plainly side by side.
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

    // Weather across the top, the clock and password below it, then the
    // modules that flank the centre in landscape paired two to a row so the
    // column doesn't run out of height. Gaps are Tokens.spacing.medium
    // throughout - the same value the landscape columns already use between
    // their own modules.
    ColumnLayout {
        anchors.fill: parent
        visible: root.isPortrait
        spacing: Tokens.spacing.small

        WeatherInfo {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Center {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraLargeIncreased
            Layout.bottomMargin: Tokens.spacing.extraLarge

            isPortrait: true
            lock: root.lock
            lockHeight: root.lockHeight
        }

        // Fetch and the notifications take whatever height is left below the
        // centre - they're the two that benefit from it. Both fill the row, so
        // they stay level with each other.
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.medium

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

        // Media and the gauges sit at their natural height rather than
        // stretching to match the row above; both still fill this row, so they
        // stay level with each other.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: Tokens.spacing.medium

            Media {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentPadding: Tokens.padding.large
                lock: root.lock
            }

            Resources {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
