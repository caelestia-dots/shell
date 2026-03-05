pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.live
import qs.components.containers
import qs.components.controls
import qs.config

ScrollablePage {
    id: root

  
    // Taskbar
    PageSection {
        id: taskbarSection

        sectionId: "taskbar"
        sectionName: qsTr("Taskbar")
        sectionIcon: "dock_to_right"

        sectionHeader.title: qsTr("Taskbar")
        sectionHeader.subtitle: qsTr("Similar to the taskbar from other environments, the bar is the focal point for interacting with your desktop. It is located on the left side of the shell.")

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
    }

    // Launcher
    PageSection {
        id: launcherSection

        sectionId: "launcher"
        sectionName: qsTr("Launcher")
        sectionIcon: "dock_to_bottom"

        sectionHeader.title: qsTr("Launcher")
        sectionHeader.subtitle: qsTr("Your quick-access application menu, accessible via the OS icon or Super key.")

        SectionGrid {
            targetColumns: 3
            minColumns: 1
            maxColumns: 3
            responsiveBreakpoint: 900

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Fuzzy Search")
                
                content: Component {
                    StyledText {
                        text: qsTr("Start typing to find apps instantly. No need for perfect spelling.")
                        wrapMode: Text.Wrap
                    }
                }
            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Configuration")
                
                content: Component {
                    StyledText {
                        text: qsTr("Modify look and feel directly via Caelestia's config files.")
                        wrapMode: Text.Wrap
                    }
                }
            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Keyboard Centric")
                
                content: Component {
                    StyledText {
                        text: qsTr("Designed to be triggered and navigated entirely with the keyboard.")
                        wrapMode: Text.Wrap
                    }
                }
            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Theme Integration")
                
                content: Component {
                    StyledText {
                        text: qsTr("Automatically matches your system color scheme and transparency settings.")
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    // Sidebar
    PageSection {
        id: sidebarSection

        sectionId: "sidebar"
        sectionName: qsTr("Sidebar")
        sectionIcon: "dock_to_left"

        sectionHeader.title: qsTr("Sidebar")
        sectionHeader.subtitle: qsTr("Access notifications, system toggles, and tools via the right-side panel.")

        SectionContentArea {
            content: Component {
                SectionList {
                    items: [
                        {
                            title: qsTr("Notifications"),
                            desc: qsTr("View and manage system notifications in a clean, organized feed.")
                        },
                        {
                            title: qsTr("Quick Toggles"),
                            desc: qsTr("Fast access to Game Mode, system settings, and hardware controls.")
                        }
                    ]
                }
            }
        }
    }

    // Dashboard
    PageSection {
        id: dashboardSection

        sectionId: "dashboard"
        sectionName: qsTr("Dashboard")
        sectionIcon: "dashboard"

        sectionHeader.title: qsTr("Dashboard")
        sectionHeader.subtitle: qsTr("An overview of system performance, media, and local environment.")

        SectionContentArea {
            content: Component {
                SectionList {
                    items: [
                        {
                            title: qsTr("System Info"),
                            desc: qsTr("A quick snapshot of your hardware and session details.")
                        }
                    ]
                }
            }
        }
    }

    // Workspaces
    PageSection {
        id: workspacesSection

        sectionId: "workspaces"
        sectionName: qsTr("Workspaces")
        sectionIcon: "stack"

        sectionHeader.title: qsTr("Workspaces")
        sectionHeader.subtitle: qsTr("Master the art of tiling and multitasking.")

        KeybindingSection {
            targetColumns: 2
            responsiveBreakpoint: 800

            groups: [
                {
                    title: qsTr("Standard Workspaces"),
                    bindings: [
                        {
                            label: qsTr("Switch to workspace"),
                            keys: ["Super", "#"]
                        },
                        {
                            label: qsTr("Move window to workspace"),
                            keys: ["Super", "Alt", "#"]
                        },
                        {
                            label: qsTr("Move window directionally"),
                            keys: ["Super", "Alt", "icon:arrow_back icon:arrow_upward icon:arrow_forward icon:arrow_downward"]
                        },
                        {
                            label: qsTr("Toggle fullscreen"),
                            keys: ["Super", "F"]
                        }
                    ]
                },
                {
                    title: qsTr("Special Workspaces"),
                    bindings: [
                        {
                            label: qsTr("Communications Hub"),
                            desc: qsTr("Discord"),
                            keys: ["Super", "D"]
                        },
                        {
                            label: qsTr("Music & Media"),
                            desc: qsTr("Spotify"),
                            keys: ["Super", "M"]
                        },
                        {
                            label: qsTr("ToDo List"),
                            desc: qsTr("Todoist"),
                            keys: ["Super", "A"]
                        },
                        {
                            label: qsTr("Special"),
                            desc: qsTr("Scratchpad Workspace"),
                            keys: ["Super", "S"]
                        }
                    ]
                }
            ]
        }
    }

      // Guided Tours
    PageSection {
        id: guidedToursSection

        sectionId: "guided-tours"
        sectionName: qsTr("Guided Tours")
        sectionIcon: "tour"

        sectionHeader.title: qsTr("Guided Tours")
        sectionHeader.subtitle: qsTr("Interactive step-by-step tours to learn Caelestia features.")

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
    }

}
