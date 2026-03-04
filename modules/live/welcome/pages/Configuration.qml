pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.live
import qs.components.containers
import qs.config

Item {
    id: root

    readonly property list<var> subsections: [
        {
            id: "settings",
            name: qsTr("Settings App"),
            icon: "settings"
        },
        {
            id: "cli",
            name: qsTr("CLI"),
            icon: "terminal"
        },
        {
            id: "shell",
            name: qsTr("Shell"),
            icon: "desktop_windows"
        },
        {
            id: "hyprland",
            name: qsTr("Hyprland"),
            icon: "select_window"
        },
    ]

    property string currentSubsection: subsections[0].id

    function scrollToSubsection(subsectionId: string): void {
        const sectionIndex = subsections.findIndex(s => s.id === subsectionId);

        if (sectionIndex === -1) {
            contentFlickable.contentY = 0;
            return;
        }

        const targetY = sectionIndex * contentFlickable.height;
        contentFlickable.contentY = targetY;
    }

    onCurrentSubsectionChanged: scrollToSubsection(currentSubsection)

    RowLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.large

        ColumnLayout {
            VerticalNav {
                id: verticalNav

                Layout.alignment: Qt.AlignTop

                sections: root.subsections
                activeSection: root.currentSubsection
                onSectionChanged: sectionId => root.currentSubsection = sectionId
            }

            Item {
                Layout.fillHeight: true
            }
        }

        StyledFlickable {
            id: contentFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.height
            flickableDirection: Flickable.VerticalFlick
            clip: true

            Behavior on contentY {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            // Settings App
            ColumnLayout {
                id: contentColumn

                width: parent.width
                spacing: 0

                ColumnLayout {
                    id: settingsSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        title: qsTr("Settings App")
                        subtitle: qsTr("Quick configuration for the most common shell options.")
                    }

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
                                        desc: qsTr("Make sure your favorite apps stay at the top! Or hide apps you dont need visible.")
                                    },
                                    {
                                        title: qsTr("Dashboard"),
                                        desc: qsTr("Choose to disable or adjust sensitivity. Can also change what is displayed.")
                                    }
                                ]
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // CLI
                ColumnLayout {
                    id: cliSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        title: qsTr("CLI Configuration")
                        subtitle: qsTr("Customize the behavior of the caelestia CLI app.")
                    }

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

                    Item {
                        Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    id: shellSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        title: qsTr("Shell Configuration")
                        subtitle: qsTr("Take your rice further with in-depth customization of the shell.")
                    }

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

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Hyprland
                ColumnLayout {
                    id: hyprlandSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        title: qsTr("Hyprland Configuration")
                        subtitle: qsTr("Tweak the underlying Hyprland configuration to suit your needs.")
                    }

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

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
