pragma Singleton

import Quickshell

Singleton {
    readonly property var taskbarLauncher: ({
        elementId: "taskbar-launcher",
        title: qsTr("OS Icon"),
        tooltip: qsTr("Clicking the OS icon opens the launcher, allowing you to quickly search and launch applications."),
        tooltipPosition: "right"
    })

    readonly property var taskbarWorkspaces: ({
        elementId: "taskbar-workspaces",
        title: qsTr("Workspace Indicator"),
        tooltip: qsTr("The workspace indicator shows your current workspace and allows quick switching between workspaces."),
        tooltipPosition: "right"
    })

    readonly property var taskbarActiveWindow: ({
        elementId: "taskbar-active-window",
        title: qsTr("Active Window Indicator"),
        tooltip: qsTr("Displays the current window title. Hovering over the title displays a live preview pop-out."),
        tooltipPosition: "right"
    })

    readonly property var taskbarSystemTray: ({
        elementId: "taskbar-system-tray",
        title: qsTr("System Tray"),
        tooltip: qsTr("The system tray provides easy access to background applications which support system tray icons."),
        tooltipPosition: "right"
    })

    readonly property var taskbarStatusIcons: ({
        elementId: "taskbar-status-icons",
        title: qsTr("Status Icons"),
        tooltip: qsTr("The status icons component provides quick access to the system info you need at a glance, including network connectivity, volume, bluetooth devices, battery and more."),
        tooltipPosition: "right"
    })

    readonly property var taskbarPowerButton: ({
        elementId: "taskbar-power-button",
        title: qsTr("Power Button"),
        tooltip: qsTr("The power button acts as a trigger for the session drawer, which allows you to Logout, Shutdown, Hibernate, or Restart your PC."),
        tooltipPosition: "right"
    })

    readonly property var tours: ({
        "taskbar-launcher": {
            id: "taskbar-launcher",
            steps: [taskbarLauncher]
        },
        "taskbar-workspaces": {
            id: "taskbar-workspaces",
            steps: [taskbarWorkspaces]
        },
        "taskbar-active-window": {
            id: "taskbar-active-window",
            steps: [taskbarActiveWindow]
        },
        "taskbar-system-tray": {
            id: "taskbar-system-tray",
            steps: [taskbarSystemTray]
        },
        "taskbar-status-icons": {
            id: "taskbar-status-icons",
            steps: [taskbarStatusIcons]
        },
        "taskbar-power-button": {
            id: "taskbar-power-button",
            steps: [taskbarPowerButton]
        },
        "taskbar-tour": {
            id: "taskbar-tour",
            title: qsTr("Taskbar Tour"),
            description: qsTr("Learn about the Caelestia taskbar and its features."),
            steps: [
                taskbarLauncher,
                taskbarWorkspaces,
                taskbarActiveWindow,
                taskbarSystemTray,
                taskbarStatusIcons,
                taskbarPowerButton
            ]
        },
        "utilities-tour": {
            id: "utilities-tour",
            title: "Utilities Drawer",
            description: "Explore the utilities drawer and its features",
            steps: [
                {
                    elementId: "utilities-idle-inhibit",
                    drawer: "utilities",
                    title: "Idle Inhibit",
                    tooltip: "Prevent your system from going idle or sleeping while you're working.",
                    tooltipPosition: "left"
                },
                {
                    elementId: "utilities-recorder",
                    drawer: "utilities",
                    title: "Screen Recorder",
                    tooltip: "Record your screen with options for fullscreen, window, or area capture.",
                    tooltipPosition: "left"
                },
                {
                    elementId: "utilities-toggles",
                    drawer: null,
                    title: "Quick Toggles",
                    tooltip: "Control WiFi, Bluetooth, Do Not Disturb, and other system settings instantly.",
                    tooltipPosition: "left"
                }
            ]
        }
    })

    function getTour(tourId: string): var {
        return tours[tourId] || null;
    }

    function getTourStep(tourId: string, stepIndex: int): var {
        const tour = getTour(tourId);
        if (!tour || stepIndex < 0 || stepIndex >= tour.steps.length) {
            return null;
        }
        return tour.steps[stepIndex];
    }

    function getTourStepCount(tourId: string): int {
        const tour = getTour(tourId);
        return tour ? tour.steps.length : 0;
    }
}
