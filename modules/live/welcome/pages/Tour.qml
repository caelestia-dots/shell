pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.live
import qs.components.controls
import qs.config

ScrollablePage {
    id: root

    // Guided Tours
    PageSection {
        id: guidedToursSection

        sectionId: "guided-tours"
        sectionName: qsTr("Guided Tours")
        sectionIcon: "tour"

        sectionHeader.title: qsTr("Guided Tours")
        sectionHeader.subtitle: qsTr("Interactive step-by-step tours to introduce you to Caelestia.")

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
                            text: qsTr("Taskbar Tour")
                            radius: Appearance.rounding.small
                            onClicked: Tour.startTour("taskbar-tour")
                        }

                        TextButton {
                            text: qsTr("Launcher Tour")
                            radius: Appearance.rounding.small
                            onClicked: Tour.startTour("launcher-tour")
                        }

                        TextButton {
                            text: qsTr("Sidebar Tour")
                            radius: Appearance.rounding.small
                            onClicked: Tour.startTour("sidebar-tour")
                        }
                    }
                }
            }
        }
    }

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
                            tourId: "taskbar-launcher"
                        },
                        {
                            title: qsTr("Workspace Indicator"),
                            desc: qsTr("The workspace indicator shows your your current workspace and allows quick switching between workspaces and special workspaces. The appearance and behavior can be modified in settings."),
                            tourId: "taskbar-workspaces"
                        },
                        {
                            title: qsTr("Active Window Indicator"),
                            desc: qsTr("Displays the current window title. Hovering over the title displays a live preview pop-out, and clicking the arrow in the top right opens a dialog with further information about the current window. The pop-out can be set to either hover or click action in settings."),
                            tourId: "taskbar-active-window"
                        },
                        {
                            title: qsTr("System Tray"),
                            desc: qsTr("The system tray provides easy access to background applications which support system tray icons. Individual icons can be overridden or hidden and system tray appearance can be modified through settings."),
                            tourId: "taskbar-system-tray"
                        },
                        {
                            title: qsTr("Status Icons"),
                            desc: qsTr("The status icons component provides quick access to the system info you need at a glance, including network connectivity, volume, bluetooth devices, battery and more. Hovering over an icon provides further details and configurations."),
                            tourId: "taskbar-status-icons"
                        },
                        {
                            title: qsTr("Power Button"),
                            desc: qsTr("The power button acts as a trigger for the session drawer, which allows you to Logout, Shutdown, Hibernate, or Restart your PC. The session menu is also easily accessible by pressing Ctrl+Alt+Delete."),
                            tourId: "taskbar-power-button"
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
        sectionHeader.subtitle: qsTr("Your quick-access application menu, accessible via the OS icon or Super (Windows) key.")

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
                title: qsTr("Favorite Apps")

                content: Component {
                    StyledText {
                        text: qsTr("Apps are intelligently sorted by use, but apps can be marked as favorites to keep them always front and center.")
                        wrapMode: Text.Wrap
                    }
                }
            }

            SectionContentArea {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Hidden Apps")

                content: Component {
                    StyledText {
                        text: qsTr("Sometimes apps add launcher icons for things that you'll just never need. Keep your launcher clean by hiding apps through the Settings panel.")
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
                title: qsTr("Configuration")

                content: Component {
                    StyledText {
                        text: qsTr("Change wallpapers and colorschemes on the fly, or make more in-depth changes to the system through Caelestia's Settings app.")
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
                        text: qsTr("Automatically matches your system colorscheme and transparency settings.")
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
        sectionHeader.subtitle: qsTr("Access notifications, system toggles, and tools via the right-side panel. The full sidebar can be opened by dragging left from the right edge. Additionally, toggles and tools can be accessed by moving your cursor to the bottom-right corner of the screen.")

        SectionContentArea {
            content: Component {
                SectionList {
                    items: [
                        {
                            title: qsTr("Notifications"),
                            desc: qsTr("View and manage system notifications in a clean, organized feed."),
                            tourId: "sidebar-notifications"
                        },
                        {
                            title: qsTr("Keep Awake"),
                            desc: qsTr("Prevent your system from going idle or sleeping while you're working."),
                            tourId: "sidebar-keep-awake"
                        },
                        {
                            title: qsTr("Screen Recorder"),
                            desc: qsTr("Record your screen with options for fullscreen, window, or area capture."),
                            tourId: "sidebar-screen-recorder"
                        },
                        {
                            title: qsTr("Quick Toggles"),
                            desc: qsTr("Fast access to Game Mode, system settings, and hardware controls."),
                            tourId: "sidebar-quick-toggles"
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
            responsiveBreakpoint: 1000

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
                            keys: ["Super", "R"]
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
}
