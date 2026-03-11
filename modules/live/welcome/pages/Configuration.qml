pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.controls
import qs.components.live
import qs.config

ScrollablePage {
    id: root

    PageSection {
        id: settingsSection

        sectionId: "settings"
        sectionName: qsTr("Settings App")
        sectionIcon: "settings"

        sectionHeader.title: qsTr("Settings App")
        sectionHeader.subtitle: qsTr("Quick configuration for the most common shell options.")

        SectionContentArea {
            content: Component {
                SectionList {
                    items: [
                        {
                            title: qsTr("Network"),
                            desc: qsTr("This page is dedicated to setting up your network access and VPN.")
                        },
                        {
                            title: qsTr("Bluetooth"),
                            desc: qsTr("Configure and look for bluetooth devices here.")
                        },
                        {
                            title: qsTr("Audio"),
                            desc: qsTr("Plugged in speakers or headphones? set up app specific volume limits.")
                        },
                        {
                            title: qsTr("Appearance"),
                            desc: qsTr("Adjust transparency, fonts, and color variants.")
                        },
                        {
                            title: qsTr("Taskbar"),
                            desc: qsTr("Infinitely configurable system statuses (WiFi, Battery) with expanded hover menus, or hidden completely.")
                        },
                        {
                            title: qsTr("Launcher"),
                            desc: qsTr("Make sure your favorite apps stay at the top! Or hide apps you don't need visible.")
                        },
                        {
                            title: qsTr("Dashboard"),
                            desc: qsTr("Choose to disable or adjust sensitivity. Can also change what is displayed.")
                        }
                    ]
                }
            }
        }
    }
    // Configuration
    PageSection {
        id: configSection

        sectionId: "configuation"
        sectionName: qsTr("Configuration")
        sectionIcon: "handyman"
        sectionHeader.title: qsTr("Configuration")
        sectionHeader.subtitle: qsTr("Your ability to make make changes is only limited by your imagination!")

        SectionContentArea {
            title: qsTr("Intro into config changes TITLE")
            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    RowLayout {
                        StyledText {
                            Layout.fillWidth: true
                            anchors.centerIn: parent
                            text: qsTr("Adjusting these files will take some knowledge. Please enjoy exploring and making changes but use caution!")
                            font.pointSize: Appearance.font.size.normal
                            font.italic: true
                            color: Colours.palette.m3error
                            horizontalAlignment: Text.AlignHCenter
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
                title: qsTr("Caelestia CLI")

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
                            text: qsTr("Caelestia Command Line Inteface that allows direct commands")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            IconTextButton {
                                text: qsTr("Button")
                                icon: "info"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("www.google.com")
                            }

                        }

                    }

                }

            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Caelestia Shell")

                content: Component {
                    ColumnLayout {
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Modules, drawers, .qml, Qt(Quick), etc")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            IconTextButton {
                                text: qsTr("resource link?")
                                icon: "info"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("www.google.com")
                            }

                            IconTextButton {
                                text: qsTr("qml or quickshell link maybe?")
                                icon: "help"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("www.google.com")
                            }

                        }

                    }

                }

            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Hyprland")

                content: Component {
                    ColumnLayout {
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("window rules, workspaces, gaps, etc")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            IconTextButton {
                                text: qsTr("resource link")
                                icon: "info"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("www.google.com")
                            }

                            IconTextButton {
                                text: qsTr("another resource link")
                                icon: "help"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("www.google.com")
                            }

                        }

                    }

                }

            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Settings configurations")

                content: Component {
                    ColumnLayout {
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("making changes in setting menu effects shell.json, but you can expand on that by going direct to that file and making changes...")
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            IconTextButton {
                                text: qsTr("shell.json in folder?")
                                icon: "info"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("www.google.com")
                            }

                            IconTextButton {
                                text: qsTr("maybe link to example file?")
                                icon: "help"
                                radius: Appearance.rounding.small
                                verticalPadding: Appearance.padding.small
                                inactiveColour: Colours.palette.m3primary
                                inactiveOnColour: Colours.palette.m3onPrimary
                                onClicked: Qt.openUrlExternally("www.google.com")
                            }

                        }

                    }

                }

            }

        }

    }

}
