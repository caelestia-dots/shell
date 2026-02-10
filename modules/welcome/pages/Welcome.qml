import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.containers
import qs.config
import "../components"

Item {
    id: root

    StyledFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: Appearance.padding.large

            Item {
                Layout.preferredHeight: Appearance.padding.larger
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacing.larger

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "waving_hand"
                    font.pointSize: 64
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Welcome to Caelestia"
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                    color: Colours.palette.m3onBackground
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "A modern, beautiful desktop shell for Wayland"
                    font.pointSize: Appearance.font.size.larger
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.padding.large
                Layout.leftMargin: Appearance.padding.larger
                Layout.rightMargin: Appearance.padding.larger
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

            Item {
                Layout.preferredHeight: Appearance.padding.larger
            }
        }
    }
}
