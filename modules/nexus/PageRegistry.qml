pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<var> pages: [
        // Appearance
        {
            label: qsTr("Wallpaper & style"),
            icon: "palette",
            description: qsTr("Wallpaper, fonts, colours"),
            category: "appearance"
        },

        // Connectivity
        // TODO
        // {
        //     label: qsTr("Display"),
        //     icon: "monitor",
        //     description: qsTr("Output configuration"),
        //     category: "connectivity"
        // },
        {
            label: qsTr("Network"),
            icon: "wifi",
            description: qsTr("Wi-Fi, ethernet"),
            category: "connectivity"
        },
        {
            label: qsTr("Connected devices"),
            icon: "devices_other",
            description: qsTr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            label: qsTr("Audio"),
            icon: "volume_up",
            description: qsTr("App volumes, sound devices"),
            category: "connectivity"
        },

        // System
        {
            label: qsTr("Updates"),
            icon: "update",
            description: qsTr("System updates"),
            category: "system"
        },
        {
            label: qsTr("Plugins"),
            icon: "extension",
            description: qsTr("Manage plugins"),
            category: "system"
        },

        // Shell
        {
            label: qsTr("Panels"),
            icon: "dock_to_bottom",
            description: qsTr("Dashboard, taskbar, launcher, sidebar"),
            category: "shell"
        },
        {
            label: qsTr("Services"),
            icon: "build",
            description: qsTr("Poll intervals, lyrics backend"),
            category: "shell"
        },
        {
            label: qsTr("Language & region"),
            icon: "globe",
            description: qsTr("UI language, weather location, display units"),
            category: "shell"
        },

        // About
        {
            label: qsTr("About"),
            icon: "info",
            description: qsTr("System information, credits"),
            category: "about"
        },
    ]
}
