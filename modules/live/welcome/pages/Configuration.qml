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

    property bool programmaticScroll: false

    Timer {
        id: scrollTimer
        interval: Appearance.anim.durations.normal + 50
        onTriggered: root.programmaticScroll = false
    }

    function scrollToSubsection(subsectionId: string): void {
        let targetY = 0

        switch(subsectionId) {
            case "settings":
                targetY = settingsSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "cli":
                targetY = cliSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "shell":
                targetY = shellSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "hyprland":
                targetY = hyprlandSectionHeader.mapToItem(contentColumn, 0, 0).y
            default:
                targetY = 0
        }

        programmaticScroll = true
        root.currentSubsection = subsectionId
        contentFlickable.contentY = targetY
        scrollTimer.restart()
    }

    function updateCurrentSection(): void {
        if (programmaticScroll)
            return

        const sections = [
            {
                id: "settings",
                header: settingsSectionHeader
            },
            {
                id: "cli",
                header: cliSectionHeader
            },
            {
                id: "shell",
                header: shellSectionHeader
            },
            {
                id: "hyprland",
                header: hyprlandSectionHeader
            }
        ]

        const scrollY = contentFlickable.contentY
        const viewportCenter = scrollY + (contentFlickable.height / 3)

        let currentSection = sections[0].id
        let minDistance = Infinity

        for (let i = 0; i < sections.length; i++) {
            const sectionY = sections[i].header.mapToItem(contentColumn, 0, 0).y
            const distance = Math.abs(sectionY - scrollY)

            if (sectionY <= viewportCenter && distance < minDistance) {
                minDistance = distance
                currentSection = sections[i].id
            }
        }

        root.currentSubsection = currentSection
    }

    RowLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.large

        ColumnLayout {
            VerticalNav {
                id: verticalNav

                Layout.alignment: Qt.AlignTop

                sections: root.subsections
                activeSection: root.currentSubsection
                onSectionChanged: sectionId => root.scrollToSubsection(sectionId)
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

            onContentYChanged: root.updateCurrentSection()

            Behavior on contentY {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            ColumnLayout {
                id: contentColumn

                width: parent.width
                spacing: 0

                // Settings
                ColumnLayout {
                    id: settingsSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        id: settingsSectionHeader

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

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                // CLI
                ColumnLayout {
                    id: cliSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        id: cliSectionHeader

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
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                ColumnLayout {
                    id: shellSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        id: shellSectionHeader

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
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                // Hyprland
                ColumnLayout {
                    id: hyprlandSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        id: hyprlandSectionHeader

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
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }
            }
        }
    }
}
