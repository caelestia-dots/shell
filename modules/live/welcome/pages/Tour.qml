import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.modules.live.components
import qs.components.containers
import qs.config
import "../../components"

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

        
        VerticalNav {
            id: verticalNav
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: 175
            Layout.preferredWidth: 200

            sections: root.subsections
            activeSection: root.currentSubsection
            onSectionChanged: sectionId => root.currentSubsection = sectionId
        }
        Item {
                        Layout.fillHeight: true
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
//-----page break
ColumnLayout {
    id: taskbarSection
    Layout.minimumHeight: contentFlickable.height
    Layout.leftMargin: Appearance.padding.larger
    Layout.rightMargin: Appearance.padding.larger
    Layout.topMargin: Appearance.padding.larger
    spacing: Appearance.padding.large
    ColumnLayout {
        spacing: 4
        StyledText {
            text: "Taskbar"
            font.pointSize: Appearance.font.size.extraLarge
            font.bold: true
            color: Colours.palette.m3onBackground
        }
        StyledText {
            text: qsTr("The central hub for system information, located on the left side of the shell.")
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: taskbarContent.implicitHeight + 60
        color: Colours.palette.m3surfaceContainerLow
        radius: Appearance.rounding.normal
        border.color: Colours.palette.m3outlineVariant

        ColumnLayout {
            id: taskbarContent
            anchors.fill: parent
            anchors.margins: 30
            spacing: 24

            Repeater {
                model: [
                    { title: "OS Icon", desc: "A decorative brand icon that opens the launcher when clicked." },
                    { title: "Workspaces", desc: "A modular monitor showing active spaces. Behavior can be modified in settings." },
                    { title: "Active Window", desc: "Displays the current window title. Hovering provides a live preview pop-out." },
                    { title: "System Tray", desc: "Interact with background applications and special workspace utilities." },
                    { title: "Status Icons", desc: "Quick-look system health (WiFi, Battery) with expanded hover menus." },
                    { title: "Power Menu", desc: "Access the power drawer for Logout, Restart, and Shutdown options." }
                ]

                delegate: ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    StyledText {
                        text: modelData.title
                        font.bold: true
                        font.pointSize: 11
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.desc
                        font.pointSize: 10
                        color: Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.3
                        visible: index < 5
                    }
                }
            }
        }
    }
    Item {
        Layout.fillHeight: true

    }
}
//-----page break
ColumnLayout {
    id: launcherSection

    Layout.fillWidth: true
    Layout.minimumHeight: contentFlickable.height
    Layout.leftMargin: Appearance.padding.larger
    Layout.rightMargin: Appearance.padding.larger
    Layout.topMargin: Appearance.padding.larger
    spacing: Appearance.padding.large


    ColumnLayout {
        spacing: 4
        StyledText {
            text: "Launcher"
            font.pointSize: Appearance.font.size.extraLarge
            font.bold: true
            color: Colours.palette.m3onBackground
        }
        StyledText {
            text: qsTr("Caelestia's primary gateway to your applications and tools.")
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurfaceVariant
        }
    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: launcherContent.implicitHeight + 60
        color: Colours.palette.m3surfaceContainerLow
        radius: Appearance.rounding.normal
        border.color: Colours.palette.m3outlineVariant

        ColumnLayout {
            id: launcherContent
            anchors.fill: parent
            anchors.margins: 30
            spacing: 24

            Repeater {
                model: [
                    { title: "Fuzzy Search", desc: "Start typing to find apps instantly. No need for perfect spelling." },
                    { title: "Configuration", desc: "Modify look and feel directly via Caelestia's config files." },
                    { title: "Keyboard Centric", desc: "Designed to be triggered and navigated entirely with the keyboard." },
                    { title: "Theme Integration", desc: "Automatically matches your system color scheme and transparency settings." }
                ]

                delegate: ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    StyledText {
                        text: modelData.title
                        font.bold: true
                        font.pointSize: 11
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.desc
                        font.pointSize: 10
                        color: Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.3
                        visible: index < 3
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
//-----page break
ColumnLayout {
    id: sidebarSection
    Layout.fillWidth: true
    Layout.minimumHeight: contentFlickable.height
    Layout.leftMargin: Appearance.padding.larger
    Layout.rightMargin: Appearance.padding.larger
    Layout.topMargin: Appearance.padding.larger
    spacing: Appearance.padding.large

    ColumnLayout {
        spacing: 4
        StyledText {
            text: "SideBar"
            font.pointSize: Appearance.font.size.extraLarge
            font.bold: true
            color: Colours.palette.m3onBackground
        }
        StyledText {
            text: qsTr("Access notifications, system toggles, and tools via the right-side panel.")
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: sidebarContent.implicitHeight + 60
        color: Colours.palette.m3surfaceContainerLow
        radius: Appearance.rounding.normal
        border.color: Colours.palette.m3outlineVariant

        ColumnLayout {
            id: sidebarContent
            anchors.fill: parent
            anchors.margins: 30
            spacing: 24

            Repeater {
                model: [
                    { title: "Notifications", desc: "A dedicated hub for all application and system alerts." },
                    { title: "Keep Awake", desc: "An integrated idle inhibitor to prevent the system from locking." },
                    { title: "Screen Recorder", desc: "Capture regions, windows, or the full screen with instant file access." },
                    { title: "Quick Toggles", desc: "Fast access to Game Mode, system settings, and hardware controls." }
                ]
                delegate: ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    StyledText {
                        text: modelData.title
                        font.bold: true
                        font.pointSize: 11
                        color: Colours.palette.m3primary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.desc
                        font.pointSize: 10
                        color: Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.3
                        visible: index < 3
                    }
                }
            }
        }
    }
    Item {
        Layout.fillHeight: true

    }
}
//-----page break
ColumnLayout {
    id: dashboardSection
    Layout.fillWidth: true
    Layout.minimumHeight: contentFlickable.height
    Layout.leftMargin: Appearance.padding.larger
    Layout.rightMargin: Appearance.padding.larger
    Layout.topMargin: Appearance.padding.larger
    spacing: Appearance.padding.large


    ColumnLayout {
        spacing: 4
        StyledText {
            text: "Dashboard"
            font.pointSize: Appearance.font.size.extraLarge
            font.bold: true
            color: Colours.palette.m3onBackground
        }
        StyledText {
            text: qsTr("An overview of system performance, media, and local environment.")
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: dashboardContent.implicitHeight + 60
        color: Colours.palette.m3surfaceContainerLow
        radius: Appearance.rounding.normal
        border.color: Colours.palette.m3outlineVariant

        ColumnLayout {
            id: dashboardContent
            anchors.fill: parent
            anchors.margins: 30
            spacing: 24

            Repeater {
                model: [
                    { title: "Media Control", desc: "Switch players and control playback for all active media." },
                    { title: "Performance", desc: "Monitor real-time CPU/GPU temperatures and system usage." },
                    { title: "Weather", desc: "Detailed local conditions with a comprehensive seven-day forecast." },
                    { title: "System Info", desc: "A quick snapshot of your hardware and session details." }
                ]
                delegate: ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    StyledText { text: modelData.title; font.bold: true; font.pointSize: 11; color: Colours.palette.m3primary }
                    StyledText { text: modelData.desc; Layout.fillWidth: true; font.pointSize: 10; wrapMode: Text.WordWrap; opacity: 0.8 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant; opacity: 0.3; visible: index < 3 }
                }
            }
        }
    }
    Item {
        Layout.fillHeight: true

    }
}
//-----page break
            }
        }
    }

}
