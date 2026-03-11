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

    // CLI
    PageSection {
        id: cliSection

        sectionId: "cli"
        sectionName: qsTr("CLI")
        sectionIcon: "terminal"

        sectionHeader.title: qsTr("CLI Configuration")
        sectionHeader.subtitle: qsTr("Customize the behavior of the caelestia CLI app.")

        SectionContentArea {
            content: Component {
                ColumnLayout {
                    StyledText {
                        Layout.fillWidth: true
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        text: qsTr("Content coming soon.")
                    }
                }
            }
        }
    }

    // Shell
    PageSection {
        id: shellSection

        sectionId: "shell"
        sectionName: qsTr("Shell")
        sectionIcon: "desktop_windows"

        sectionHeader.title: qsTr("Shell Configuration")
        sectionHeader.subtitle: qsTr("Take your rice further with in-depth customization of the shell.")

        SectionContentArea {
            content: Component {
                ColumnLayout {
                    StyledText {
                        Layout.fillWidth: true
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        text: qsTr("Caelestia has loads of user configurable shell options. These can be found in the shell.json file located in you ~/.config/caelestia directory.")
                    }
                }
            }
        }
    }

    // Hyprland
    PageSection {
        id: hyprlandSection

        sectionId: "hyprland"
        sectionName: qsTr("Hyprland")
        sectionIcon: "select_window"

        sectionHeader.title: qsTr("Hyprland Configuration")
        sectionHeader.subtitle: qsTr("Tweak the underlying Hyprland configuration to suit your needs.")

        SectionContentArea {
            content: Component {
                ColumnLayout {
                    StyledText {
                        Layout.fillWidth: true
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        text: qsTr("Caelestia provides you with two files to configure Hyprland. hypr-user.conf and hypr-vars.conf. these are also located in ~/.config/caelestia. hypr-user.conf is for general configuration changes like keybinds and window rules, while hypr-vars.conf is for overriding the default variables such as borders and window gaps.")
                    }
                    Item { Layout.fillHeight: true }
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: requirementsNote.implicitHeight + Appearance.padding.larger * 2
                        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
                        radius: Appearance.rounding.small
                        Layout.topMargin: Appearance.padding.normal

                        StyledText {
                            id: hyprlandNote
                            anchors.centerIn: parent
                            height: parent.height -14
                            width: parent.width - 24
                            text: qsTr("Adjusting these files will take some knowledge, so use caution and visit the hyprland wiki to learn and understand what you are doing.")
                            font.pointSize: Appearance.font.size.small
                            font.italic: true
                            color: Colours.palette.m3error
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                    IconTextButton {
                            text: qsTr("Hyprland Wiki")
                            icon: "open_in_new"
                            radius: Appearance.rounding.small
                            verticalPadding: Appearance.padding.small
                            inactiveColour: Colours.palette.m3primary
                            inactiveOnColour: Colours.palette.m3onPrimary
                            onClicked: Qt.openUrlExternally("https://wiki.hypr.land/")
                        }
                    }
                }
            }
        }

}
