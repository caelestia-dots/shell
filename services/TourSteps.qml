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

    readonly property var launcherApps: ({
        elementId: "launcher-apps",
        drawer: "launcher",
        title: qsTr("App Launcher"),
        tooltip: qsTr("The Caelestia launcher provides quick access to your applications and the Caelestia command palette. It is accessible through the OS icon in the taskbar, or the Super (Windows) key on your keyboard. Apps can be flagged as favorites or hidden through the settings."),
        tooltipPosition: "left"
    })

    readonly property var launcherSearch: ({
        elementId: "launcher-search",
        drawer: "launcher",
        title: qsTr("Launcher Search"),
        tooltip: qsTr("The launcher includes a convenient search field allowing you to quickly filter your apps list. You can also switch the launcher to command mode by entering \">\" in the search field."),
        tooltipPosition: "left"
    })

    readonly property var launcherCommands: ({
        elementId: "launcher-apps",
        drawer: "launcher",
        action: ["quickshell", "ipc", "-c", "caelestia", "call", "tour", "showCommands"],
        title: qsTr("Launcher Commands"),
        tooltip: qsTr("In command mode, the launcher allows you to set your wallpaper and colorscheme, toggle dark mode, access the Settings panel, and interact with the session."),
        tooltipPosition: "left"
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
        "launcher-tour": {
            id: "launcher-tour",
            title: qsTr("Launcher Tour"),
            description: qsTr("Learn about the Caelestia launcher and its features."),
            steps: [
                launcherApps,
                launcherSearch,
                launcherCommands
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
