pragma Singleton

import Quickshell

Singleton {
    readonly property var tours: ({

        "bar-launcher": {
            id: "bar-launcher",
            steps: [
                {
                    elementId: "bar-launcher",
                    title: qsTr("OS Icon"),
                    tooltip: qsTr("Clicking the OS icon opens the launcher, allowing you to quickly search and launch applications."),
                    tooltipPosition: "right"
                }
            ]
        },
        "bar-basics": {
            id: "bar-basics",
            title: "Bar Basics",
            description: "Learn about the workspace indicator and bar features",
            steps: [
                {
                    elementId: "bar-launcher",
                    drawer: null,
                    title: "App Launcher",
                    tooltip: "Click to search and launch applications quickly.",
                    tooltipPosition: "right"
                },
                {
                    elementId: "bar-workspaces",
                    drawer: null,
                    title: "Workspace Indicator",
                    tooltip: "Shows your current workspace and allows quick switching between workspaces.",
                    tooltipPosition: "right"
                },
                {
                    elementId: "bar-system-tray",
                    drawer: null,
                    title: "System Tray",
                    tooltip: "Access system indicators and background applications.",
                    tooltipPosition: "right"
                }
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
