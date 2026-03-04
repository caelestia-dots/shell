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
            id: "side-bar",
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

            ColumnLayout {
                id: contentColumn

                width: parent.width
                spacing: 0

                // Taskbar
                ColumnLayout {
                    id: taskbarSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.spacing.larger

                    WelcomeSectionHeader {
                        title: qsTr("Taskbar")
                        subtitle: qsTr("The central hub for system information, located on the left side of the shell.")
                    }

                    WelcomeSectionContentArea {
                        content: Component {
                            ColumnLayout {
                                spacing: Appearance.spacing.larger

                                Repeater {
                                    id: taskbarItems

                                    model: [
                                        {
                                            title: qsTr("OS Icon"),
                                            desc: qsTr("A decorative brand icon that opens the launcher when clicked.")
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

                                    delegate: ColumnLayout {
                                        id: taskbarItem

                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true

                                        spacing: Appearance.spacing.small

                                        StyledText {
                                            font.bold: true
                                            font.pointSize: Appearance.font.size.small
                                            color: Colours.palette.m3primary
                                            text: taskbarItem.modelData.title
                                        }

                                        StyledText {
                                            Layout.fillWidth: true

                                            font.pointSize: Appearance.font.size.small
                                            color: Colours.palette.m3onSurface
                                            wrapMode: Text.WordWrap
                                            opacity: 0.8
                                            text: taskbarItem.modelData.desc
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Colours.palette.m3outlineVariant
                                            opacity: 0.3
                                            visible: taskbarItem.index < taskbarItems.count - 1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Launcher
                ColumnLayout {
                    id: launcherSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    WelcomeSectionHeader {
                        title: qsTr("Launcher")
                        subtitle: qsTr("Caelestia's primary gateway to your applications and tools.")
                    }

                    WelcomeSectionContentArea {
                        content: Component {
                            ColumnLayout {
                                spacing: Appearance.spacing.larger

                                Repeater {
                                    id: launcherItems

                                    model: [
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

                                    delegate: ColumnLayout {
                                        id: launcherItem

                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true

                                        spacing: Appearance.spacing.small

                                        StyledText {
                                            font.bold: true
                                            font.pointSize: Appearance.font.size.small
                                            color: Colours.palette.m3primary
                                            text: launcherItem.modelData.title
                                        }

                                        StyledText {
                                            Layout.fillWidth: true

                                            font.pointSize: Appearance.font.size.small
                                            color: Colours.palette.m3onSurface
                                            wrapMode: Text.WordWrap
                                            opacity: 0.8
                                            text: launcherItem.modelData.desc
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Colours.palette.m3outlineVariant
                                            opacity: 0.3
                                            visible: launcherItem.index < launcherItems.count - 1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Sidebar
                ColumnLayout {
                    id: sidebarSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    WelcomeSectionHeader {
                        title: qsTr("Sidebar")
                        subtitle: qsTr("Access notifications, system toggles, and tools via the right-side panel.")
                    }

                    WelcomeSectionContentArea {
                        content: Component {
                            ColumnLayout {
                                spacing: Appearance.spacing.larger

                                Repeater {
                                    id: sidebarItems

                                    model: [
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

                                    delegate: ColumnLayout {
                                        id: sidebarItem

                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true

                                        spacing: Appearance.spacing.small

                                        StyledText {
                                            font.bold: true
                                            font.pointSize: Appearance.font.size.small
                                            color: Colours.palette.m3primary
                                            text: sidebarItem.modelData.title
                                        }

                                        StyledText {
                                            Layout.fillWidth: true

                                            font.pointSize: Appearance.font.size.small
                                            color: Colours.palette.m3onSurface
                                            wrapMode: Text.WordWrap
                                            opacity: 0.8
                                            text: sidebarItem.modelData.desc
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Colours.palette.m3outlineVariant
                                            opacity: 0.3
                                            visible: sidebarItem.index < sidebarItems.count - 1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Dashboard
                ColumnLayout {
                    id: dashboardSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.larger

                    WelcomeSectionHeader {
                        title: qsTr("Dashboard")
                        subtitle: qsTr("An overview of system performance, media, and local environment.")
                    }

                    WelcomeSectionContentArea {
                        content: Component {
                            ColumnLayout {
                                spacing: Appearance.spacing.larger

                                Repeater {
                                    id: dashboardItems

                                    model: [
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

                                    delegate: ColumnLayout {
                                        id: dashboardItem

                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true

                                        spacing: Appearance.spacing.small

                                        StyledText {
                                            font.bold: true
                                            font.pointSize: Appearance.font.size.small
                                            color: Colours.palette.m3primary
                                            text: dashboardItem.modelData.title
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            font.pointSize: Appearance.font.size.small
                                            wrapMode: Text.WordWrap
                                            opacity: 0.8
                                            text: dashboardItem.modelData.desc
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Colours.palette.m3outlineVariant
                                            opacity: 0.3
                                            visible: dashboardItem.index < dashboardItems.count - 1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Workspaces
                ColumnLayout {
                    id: workspacesSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.spacing.large

                    WelcomeSectionHeader {
                        title: qsTr("Workspaces")
                        subtitle: qsTr("Master the art of tiling and multitasking.")
                    }

                    // Standard Workspaces
                    WelcomeSectionContentArea {
                        content: Component {
                            ColumnLayout {
                                spacing: Appearance.spacing.large

                                StyledGridView {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: implicitHeight

                                    model: [
                                        {
                                            key: qsTr("Super + <#>"),
                                            label: qsTr("Switch to workspace")
                                        },
                                        {
                                            key: qsTr("Super + Alt + <#>"),
                                            label: qsTr("Move window to workspace"),
                                        },
                                        {
                                            key: qsTr("Super + Alt + <Up|Down|Left|Right>"),
                                            label: qsTr("Move window directionally")
                                        },
                                        {
                                            key: qsTr("Super + F"),
                                            label: qsTr("Toggle fullscreen")
                                        }
                                    ]

                                    spacing: 12
                                    paddingX: 16

                                    cellContent: Component {
                                        Item {
                                            id: standardWorkspacesItem

                                            property var modelData
                                            property real gridMeasureWidth: firstStepsKeybinding.implicitWidth

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: Appearance.padding.small
                                                spacing: Appearance.spacing.small

                                                Keybinding {
                                                    id: firstStepsKeybinding

                                                    key: standardWorkspacesItem.modelData.key
                                                    label: standardWorkspacesItem.modelData.label
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    WelcomeSectionHeader {
                        title: qsTr("Special Workspaces")
                        subtitle: qsTr("Keep important things close, but out of the way.")
                    }

                    // Special Workspaces
                    WelcomeSectionContentArea {
                        content: Component {
                            ColumnLayout {
                                spacing: Appearance.spacing.large

                                StyledGridView {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: implicitHeight

                                    model: [
                                        {
                                            key: qsTr("Super + D"),
                                            label: qsTr("Communications Hub"),
                                            desc: qsTr("Discord")
                                        },
                                        {
                                            key: qsTr("Super + M"),
                                            label: qsTr("Music & Media"),
                                            desc: qsTr("Spotify")
                                        },
                                        {
                                            key: qsTr("Super + A"),
                                            label: qsTr("ToDo List"),
                                            desc: qsTr("Todoist")
                                        },
                                        {
                                            key: qsTr("Super + S"),
                                            label: qsTr("Special"),
                                            desc: qsTr("Scratchpad Workspace")
                                        }
                                    ]

                                    spacing: 12
                                    paddingX: 16

                                    cellContent: Component {
                                        Item {
                                            id: specialWorkspacesItem

                                            property var modelData
                                            property real gridMeasureWidth: specialWorkspacesKeybinding.implicitWidth

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: Appearance.padding.small
                                                spacing: Appearance.spacing.small

                                                Keybinding {
                                                    id: specialWorkspacesKeybinding

                                                    key: specialWorkspacesItem.modelData.key
                                                    label: specialWorkspacesItem.modelData.label
                                                    desc: specialWorkspacesItem.modelData.desc
                                                }
                                            }
                                        }
                                    }
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
