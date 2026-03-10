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

                        IconTextButton {
                            Layout.alignment: Qt.AlignVCenter
                            text: qsTr("Join Discord")
                            icon: "open_in_new"
                            radius: Appearance.rounding.small
                            verticalPadding: Appearance.padding.small
                            inactiveColour: Colours.palette.m3primary
                            inactiveOnColour: Colours.palette.m3onPrimary

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

                        IconTextButton {
                            text: qsTr("Caelestia CLI")
                            icon: "open_in_new"
                            radius: Appearance.rounding.small
                            verticalPadding: Appearance.padding.small
                            inactiveColour: Colours.palette.m3primary
                            inactiveOnColour: Colours.palette.m3onPrimary

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

                        IconTextButton {
                            text: qsTr("Caelestia Shell")
                            icon: "open_in_new"
                            radius: Appearance.rounding.small
                            verticalPadding: Appearance.padding.small
                            inactiveColour: Colours.palette.m3primary
                            inactiveOnColour: Colours.palette.m3onPrimary

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

                        IconTextButton {
                            text: qsTr("Caelestia Dots")
                            icon: "open_in_new"
                            radius: Appearance.rounding.small
                            verticalPadding: Appearance.padding.small
                            inactiveColour: Colours.palette.m3primary
                            inactiveOnColour: Colours.palette.m3onPrimary

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

                        IconTextButton {
                            text: qsTr("Caelestia Live")
                            icon: "open_in_new"
                            radius: Appearance.rounding.small
                            verticalPadding: Appearance.padding.small
                            inactiveColour: Colours.palette.m3primary
                            inactiveOnColour: Colours.palette.m3onPrimary

                            onClicked: Qt.openUrlExternally("https://github.com/caelestia-community/live")
                        }
                    }
                }
            }
        }
    }
    // Credit
    PageSection {
        id: creditsSection

        sectionId: "credits"
        sectionName: qsTr("Credits")
        sectionIcon: "attribution"

        sectionHeader.title: qsTr("Credits!")
        sectionHeader.subtitle: qsTr("A Thanks to everyone who made this possible!")

        SectionContentArea {
            title: qsTr("On the shoulders of Giants.")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("The world of Linux is full of storybook heros come to life. There is no way we can thank everybody from Bell Labs all the way to the smallest contibuters. But we have a few special people to note.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
        SectionContentArea {
            title: qsTr("Outfoxxed - Developer for Quickshell")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("A huge thanks to Outfoxxed who developed the foundation that Caelestia Shell is built on.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }
                        TextButton {
                            text: qsTr("Website 󰖟")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://quickshell.org")
                        }
                        TextButton {
                            text: qsTr("Github 󰊤")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://github.com/outfoxxed")
                        }
                    }
                }
            }
        }
        SectionContentArea {
            title: qsTr("Soramane - Developer for Caelestia")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Soramane(Soramanew) is the Developer behind Caelestia. Every drawer, popout, bar, etc. He was directly involved with all of it!")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }
                        TextButton {
                            text: qsTr("Buy Soramane a Coffee 󰅶")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://buymeacoffee.com/soramane")
                        }
                        TextButton {
                            text: qsTr("Github 󰊤")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://github.com/soramanew")
                        }
                    }
                }
            }
        }
        SectionContentArea {
            title: qsTr("Evertiro - Developer for Caelestia Live")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Evertiro is the man directly responsible for seeing this page at all! Relentlessly dedicated to making dreams come true!")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }
                        TextButton {
                            text: qsTr("Website 󰖟")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://evertiro.com")
                        }
                        TextButton {
                            text: qsTr("Github 󰊤")
                            radius: Appearance.rounding.small

                            onClicked: Qt.openUrlExternally("https://github.com/evertiro")
                        }

                    }
                }
            }
        }
        SectionContentArea {
            title: qsTr("Contributers")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Dozens of us! Making Pull Requests on Github, brainstorming ideas in Discord, teaching one another and thiving in a pretty small community. Too many to name but too few to forget.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
        SectionContentArea {
            title: qsTr("Everyone else!")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("So many people in so many places! Github commentors, Discord members, BuyMeACoffee subscribers. Thank you to every last one of you who will give Caelestia Live a shot!")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
