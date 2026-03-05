pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.live
import qs.components.containers
import qs.components.controls
import qs.config

Item {
    id: root

    readonly property list<var> subsections: [
        {
            id: "guided-tours",
            name: qsTr("Guided Tours"),
            icon: "tour"
        },
        {
            id: "taskbar",
            name: qsTr("Taskbar"),
            icon: "dock_to_right"
        },
        {
            id: "launcher",
            name: qsTr("Launcher"),
            icon: "dock_to_bottom"
        },
        {
            id: "sidebar",
            name: qsTr("SideBar"),
            icon: "dock_to_left"
        },
        {
            id: "dashboard",
            name: qsTr("Dashboard"),
            icon: "toolbar"
        },
        {
            id: "workspaces",
            name: qsTr("Workspaces"),
            icon: "stack"
        }

    ]

    property string currentSubsection: subsections[0].id

    property bool programmaticScroll: false

    Timer {
        id: scrollTimer
        interval: Appearance.anim.durations.normal + 50
        onTriggered: root.programmaticScroll = false
    }

    function scrollToSubsection(subsectionId: string): void {
        let targetY = 0;

        switch(subsectionId) {
            case "guided-tours":
                targetY = guidedToursSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "taskbar":
                targetY = taskbarSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "launcher":
                targetY = launcherSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "sidebar":
                targetY = sidebarSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "dashboard":
                targetY = dashboardSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "workspaces":
                targetY = workspacesSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
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
                id: "guided-tours",
                header: guidedToursSectionHeader
            },
            {
                id: "taskbar",
                header: taskbarSectionHeader
            },
            {
                id: "launcher",
                header: launcherSectionHeader
            },
            {
                id: "sidebar",
                header: sidebarSectionHeader
            },
            {
                id: "dashboard",
                header: dashboardSectionHeader
            },
            {
                id: "workspaces",
                header: workspacesSectionHeader
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

                // Guided Tours
                ColumnLayout {
                    id: guidedToursSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.spacing.large

                    SectionHeader {
                        id: guidedToursSectionHeader

                        title: qsTr("Guided Tours")
                        subtitle: qsTr("Interactive step-by-step tours to learn Caelestia features.")
                    }

                    SectionContentArea {
                        content: Component {
                            ColumnLayout {
                                spacing: Appearance.spacing.large

                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("Start a guided tour to learn about specific features. Each tour will highlight elements and guide you through their functionality.")
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3onSurface
                                    wrapMode: Text.WordWrap
                                    opacity: 0.9
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.normal

                                    TextButton {
                                        text: qsTr("Bar Basics Tour")
                                        radius: Appearance.rounding.small
                                        onClicked: Tour.startTour("bar-basics")
                                    }

                                    TextButton {
                                        text: qsTr("Utilities Drawer Tour")
                                        radius: Appearance.rounding.small
                                        onClicked: Tour.startTour("utilities-tour")
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                // Taskbar
                ColumnLayout {
                    id: taskbarSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.spacing.larger

                    SectionHeader {
                        id: taskbarSectionHeader

                        title: qsTr("Taskbar")
                        subtitle: qsTr("Similar to the taskbar from other environments, the bar is the focal point for interacting with your desktop. It is located on the left side of the shell.")
                    }

                    SectionContentArea {
                        content: Component {
                            SectionList {
                                items: [
                                    {
                                        title: qsTr("OS Icon"),
                                        desc: qsTr("The OS icon shows the Caelestia logo by default in CaelestiaLive, and the distro logo by default on a normal install. The icon can be changed through your shell.json file, and acts as a trigger for the application launcher."),
                                        tourId: "bar-launcher"
                                    },
                                    {
                                        title: qsTr("Workspaces"),
                                        desc: qsTr("A modular monitor showing active spaces. Behavior can be modified in settings.")
                                    },
                                    {
                                        title: qsTr("Active Window"),
                                        desc: qsTr("Displays the current window title. Hovering provides a live preview pop-out.")
                                    },
                                    {
                                        title: qsTr("System Tray"),
                                        desc: qsTr("Interact with background applications and special workspace utilities.")
                                    },
                                    {
                                        title: qsTr("Status Icons"),
                                        desc: qsTr("Quick-look system health (WiFi, Battery) with expanded hover menus.")
                                    },
                                    {
                                        title: qsTr("Power Menu"),
                                        desc: qsTr("Access the power drawer for Logout, Restart, and Shutdown options.")
                                    }
                                ]
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                // Launcher
                ColumnLayout {
                    id: launcherSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        id: launcherSectionHeader

                        title: qsTr("Launcher")
                        subtitle: qsTr("Your quick-access application menu, accessible via the OS icon or Super key.")
                    }

                    SectionContentArea {
                        content: Component {
                            SectionList {
                                items: [
                                    {
                                        title: qsTr("Fuzzy Search"),
                                        desc: qsTr("Start typing to find apps instantly. No need for perfect spelling.")
                                    },
                                    {
                                        title: qsTr("Configuration"),
                                        desc: qsTr("Modify look and feel directly via Caelestia's config files.")
                                    },
                                    {
                                        title: qsTr("Keyboard Centric"),
                                        desc: qsTr("Designed to be triggered and navigated entirely with the keyboard.")
                                    },
                                    {
                                        title: qsTr("Theme Integration"),
                                        desc: qsTr("Automatically matches your system color scheme and transparency settings.")
                                    }
                                ]
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                // Sidebar
                ColumnLayout {
                    id: sidebarSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        id: sidebarSectionHeader

                        title: qsTr("Sidebar")
                        subtitle: qsTr("Access notifications, system toggles, and tools via the right-side panel.")
                    }

                    SectionContentArea {
                        content: Component {
                            SectionList {
                                items: [
                                    {
                                        title: qsTr("Notifications"),
                                        desc: qsTr("A dedicated hub for all application and system alerts.")
                                    },
                                    {
                                        title: qsTr("Keep Awake"),
                                        desc: qsTr("An integrated idle inhibitor to prevent the system from locking.")
                                    },
                                    {
                                        title: qsTr("Screen Recorder"),
                                        desc: qsTr("Capture regions, windows, or the full screen with instant file access.")
                                    },
                                    {
                                        title: qsTr("Quick Toggles"),
                                        desc: qsTr("Fast access to Game Mode, system settings, and hardware controls.")
                                    }
                                ]
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                // Dashboard
                ColumnLayout {
                    id: dashboardSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        id: dashboardSectionHeader

                        title: qsTr("Dashboard")
                        subtitle: qsTr("An overview of system performance, media, and local environment.")
                    }

                    SectionContentArea {
                        content: Component {
                            SectionList {
                                items: [
                                    {
                                        title: qsTr("Media Control"),
                                        desc: qsTr("Switch players and control playback for all active media.")
                                    },
                                    {
                                        title: qsTr("Performance"),
                                        desc: qsTr("Monitor real-time CPU/GPU temperatures and system usage.")
                                    },
                                    {
                                        title: qsTr("Weather"),
                                        desc: qsTr("Detailed local conditions with a comprehensive seven-day forecast.")
                                    },
                                    {
                                        title: qsTr("System Info"),
                                        desc: qsTr("A quick snapshot of your hardware and session details.")
                                    }
                                ]
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                // Workspaces
                ColumnLayout {
                    id: workspacesSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    SectionHeader {
                        id: workspacesSectionHeader

                        title: qsTr("Workspaces")
                        subtitle: qsTr("Master the art of tiling and multitasking.")
                    }

                    SectionContentArea {
                        color: "transparent"

                        content: Component {
                            GridLayout {
                                columns: parent.width > 800 ? 2 : 1
                                columnSpacing: Appearance.spacing.large
                                rowSpacing: Appearance.spacing.large

                                // Standard Workspaces
                                SectionContentArea {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignTop
                                    title: qsTr("Standard Workspaces")

                                    content: Component {
                                        ColumnLayout {
                                            spacing: Appearance.spacing.normal

                                            KeybindingRow {
                                                label: qsTr("Switch to workspace")
                                                keys: ["Super", "#"]
                                            }

                                            KeybindingRow {
                                                label: qsTr("Move window to workspace")
                                                keys: ["Super", "Alt", "#"]
                                            }

                                            KeybindingRow {
                                                label: qsTr("Move window directionally")
                                                keys: ["Super", "Alt", "icon:arrow_back icon:arrow_upward icon:arrow_forward icon:arrow_downward"]
                                            }

                                            KeybindingRow {
                                                label: qsTr("Toggle fullscreen")
                                                keys: ["Super", "F"]
                                            }
                                        }
                                    }
                                }

                                // Special Workspaces
                                SectionContentArea {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignTop
                                    title: qsTr("Special Workspaces")

                                    content: Component {
                                        ColumnLayout {
                                            spacing: Appearance.spacing.normal

                                            KeybindingRow {
                                                label: qsTr("Communications Hub")
                                                desc: qsTr("Discord")
                                                keys: ["Super", "D"]
                                            }

                                            KeybindingRow {
                                                label: qsTr("Music & Media")
                                                desc: qsTr("Spotify")
                                                keys: ["Super", "M"]
                                            }

                                            KeybindingRow {
                                                label: qsTr("ToDo List")
                                                desc: qsTr("Todoist")
                                                keys: ["Super", "A"]
                                            }

                                            KeybindingRow {
                                                label: qsTr("Special")
                                                desc: qsTr("Scratchpad Workspace")
                                                keys: ["Super", "S"]
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                // Bottom padding to allow last section to scroll into active range
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentFlickable.height * 0.66
                }
            }
        }
    }
}
