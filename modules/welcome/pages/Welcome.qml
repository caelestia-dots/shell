import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.config
import "../components"

ColumnLayout {
    id: root

    spacing: Appearance.padding.large

    // Hero section
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.larger

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "waving_hand"
            font.pointSize: 64
            color: Colours.palette.m3primary
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome to Caelestia"
            font.pointSize: Appearance.font.size.extraLarge
            font.bold: true
            color: Colours.palette.m3onBackground
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "A modern, beautiful desktop shell for Wayland"
            font.pointSize: Appearance.font.size.larger
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // Info cards
    GridLayout {
        Layout.topMargin: Appearance.padding.large
        columns: 2
        rowSpacing: Appearance.spacing.larger
        columnSpacing: Appearance.spacing.larger

        InfoCard {
            Layout.fillWidth: true
            icon: "rocket_launch"
            title: "Getting Started"
            description: "Learn the basics and set up your shell"
        }

        InfoCard {
            Layout.fillWidth: true
            icon: "palette"
            title: "Customize"
            description: "Make Caelestia your own with themes and colors"
        }

        InfoCard {
            Layout.fillWidth: true
            icon: "widgets"
            title: "Modules"
            description: "Explore drawers, widgets, and more"
        }

        InfoCard {
            Layout.fillWidth: true
            icon: "help"
            title: "Resources"
            description: "Documentation, community, and support"
        }
    }

    Item { Layout.fillHeight: true }
}