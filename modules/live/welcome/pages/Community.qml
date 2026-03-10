import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.components.live
import qs.config
import qs.services

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

    // Credits
    PageSection {
        id: creditsSection

        sectionId: "credits"
        sectionName: qsTr("Credits")
        sectionIcon: "person"
        sectionHeader.title: qsTr("Credits")
        sectionHeader.subtitle: qsTr("Thanks to everyone who made this possible!")

        SectionContentArea {
            title: qsTr("On the shoulders of Giants.")
            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("The world of Linux is full of storybook heroes come to life. There is no way we can thank everybody from Bell Labs all the way to the smallest contributors, but we have a few special people to note.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                    }

                }

            }

        }

        SectionGrid {
            targetColumns: 2
            minColumns: 1
            maxColumns: 2
            responsiveBreakpoint: 900
            columnSpacing: Appearance.padding.large
            rowSpacing: Appearance.padding.large
            Layout.topMargin: Appearance.padding.large

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Outfoxxed - Developer for Quickshell")

                content: Component {
                    ColumnLayout {
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("A huge thanks to Outfoxxed, who developed the foundation that Caelestia Shell is built on.")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            IconTextButton {
                                text: qsTr("Website")
                                icon: "language"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("https://quickshell.org")
                            }

                            IconTextButton {
                                text: qsTr("GitHub")
                                icon: "code"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("https://github.com/outfoxxed")
                            }

                        }

                    }

                }

            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Soramane - Developer for Caelestia")

                content: Component {
                    ColumnLayout {
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Soramane (Soramanew) is the Developer behind Caelestia. Every drawer, popout, bar, etc. He was directly involved with all of it!")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            IconTextButton {
                                text: qsTr("Buy Soramane a Coffee")
                                icon: "local_cafe"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("https://buymeacoffee.com/soramane")
                            }

                            IconTextButton {
                                text: qsTr("GitHub")
                                icon: "code"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("https://github.com/soramanew")
                            }

                        }

                    }

                }

            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Evertiro - Developer for Caelestia Live")

                content: Component {
                    ColumnLayout {
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Evertiro is the man directly responsible for you seeing this page at all! Relentlessly dedicated to making dreams come true!")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            IconTextButton {
                                text: qsTr("Website")
                                icon: "language"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("https://evertiro.com")
                            }

                            IconTextButton {
                                text: qsTr("GitHub")
                                icon: "code"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("https://github.com/evertiro")
                            }

                        }

                    }

                }

            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Everyone Else!")

                content: Component {
                    ColumnLayout {
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("So many people in so many places! Making pull requests on GitHub, brainstorming ideas on Discord, teaching one another and thriving in a pretty small community. Too many to name, but too few to forget. Thank you to every last one of you who will give Caelestia Live a shot!")
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
