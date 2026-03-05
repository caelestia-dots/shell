import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.live
import qs.components.controls
import qs.config

ScrollablePage {
    id: root

    // Join Us
    PageSection {
        id: joinUsSection

        sectionId: "joinUs"
        sectionName: qsTr("Join Us")
        sectionIcon: "forum"

        sectionHeader.title: qsTr("Join Us")
        sectionHeader.subtitle: qsTr("Join our thriving community on Discord.")

        SectionContentArea {
            title: qsTr("Need help or support?")
            subtitle: qsTr("Want to chat with other Caelestia users?")

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            id: joinUsContent

                            Layout.fillWidth: true
                            Layout.rightMargin: Appearance.padding.large
                            text: qsTr("The official Caelestia Discord community is an active community that is growing daily! Why not stop in and say hi?")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        TextButton {
                            Layout.alignment: Qt.AlignVCenter
                            text: qsTr("Join Discord")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://discord.gg/BGDCFCmMBk")
                        }
                    }
                }
            }
        }
    }

    // Get Involved
    PageSection {
        id: getInvolvedSection

        sectionId: "getInvolved"
        sectionName: qsTr("Get Involved")
        sectionIcon: "code"

        sectionHeader.title: qsTr("Get Involved")
        sectionHeader.subtitle: qsTr("Become a contributor.")

        SectionContentArea {
            content: Component {
                ColumnLayout {
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Caelestia might have had humble beginnings, but today we have a growing number of contributors. Whether you have a bug to report, a bugfix you want to contribute, or a feature request, we'd love to hear from you!")
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        SectionContentArea {
            title: qsTr("Caelestia CLI")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Caelestia CLI is the main control script for Caelestia. Written in Python, CLI is responsible for the caelestia command, which acts as a handler for functionality such as schemes, wallpaper management, and screen capture and recording.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        TextButton {
                            text: qsTr("Caelestia CLI")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/cli")
                        }
                    }
                }
            }
        }

        SectionContentArea {
            title: qsTr("Caelestia Shell")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Caelestia Shell provides the actual UI elements and much of the underlying functionality of Caelestia. It is primarily written in QML, and built around Quickshell.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        TextButton {
                            text: qsTr("Caelestia Shell")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/shell")
                        }
                    }
                }
            }
        }

        SectionContentArea {
            title: qsTr("Caelestia Dots")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Caelestia Dots is the main repo for Caelestia, and handles all of the application configs, as well as the Caelestia install script. This is the primary point of entry for most users, and serves as the primary installation guide for Caelestia.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        TextButton {
                            text: qsTr("Caelestia Dots")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/caelestia")
                        }
                    }
                }
            }
        }

        SectionContentArea {
            title: qsTr("Caelestia Live")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Caelestia Live is the unofficial community project to build a Caelestia-based live image. If you're reading this, congratulations! You're running Caelestia Live! Caelestia Live was built by Evertiro, and at this time, he provides all live-image specific support.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        TextButton {
                            text: qsTr("Caelestia Dots")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://github.com/caelestia-community/live")
                        }
                    }
                }
            }
        }
    }
}
