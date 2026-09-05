import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var lock
    required property real lockHeight

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
