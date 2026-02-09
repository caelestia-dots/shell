import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import "../components"

ColumnLayout {
    id: root

    spacing: 24

    // Hero section
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 16

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "waving_hand"
            font.pointSize: 64
            color: Colours.palette.m3primary
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome to Caelestia"
            font.pointSize: 32
            font.bold: true
            color: Colours.palette.m3onBackground
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "A modern, beautiful desktop shell for Wayland"
            font.pointSize: 14
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // Info cards
    GridLayout {
        Layout.topMargin: 32
        columns: 2
        rowSpacing: 16
        columnSpacing: 16

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