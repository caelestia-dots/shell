pragma Singleton

import QtQuick
import Caelestia.I18n

QtObject {
    id: root

    // Order must match PageCompRegistry.pageComps
    readonly property list<var> pages: [
        {
            label: Tr.tr("Style"),
            icon: "palette",
            description: Tr.tr("Style, flavour, wallpaper"),
            category: "appearance"
        },
        {
            label: Tr.tr("Animations"),
            icon: "animation",
            description: Tr.tr("Mascot, scenes, seasons, transitions"),
            category: "appearance"
        },
        {
            label: Tr.tr("Notch"),
            icon: "toggle_on",
            description: Tr.tr("Clock, scale, mascot, focus timer"),
            category: "shell"
        },
        {
            label: Tr.tr("Overlays"),
            icon: "notifications",
            description: Tr.tr("OSD, notifications, toasts"),
            category: "shell"
        },
        {
            label: Tr.tr("AI agents"),
            icon: "smart_toy",
            description: Tr.tr("Claude Code hooks and approvals"),
            category: "shell"
        },
        {
            label: Tr.tr("Apps"),
            icon: "apps",
            description: Tr.tr("Default apps, favourites, hidden apps"),
            category: "shell"
        },
        {
            label: Tr.tr("Network"),
            icon: "wifi",
            description: Tr.tr("Wi-Fi, ethernet, VPN"),
            category: "connectivity"
        },
        {
            label: Tr.tr("Connected devices"),
            icon: "devices_other",
            description: Tr.tr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            label: Tr.tr("Audio"),
            icon: "volume_up",
            description: Tr.tr("App volumes, sound devices"),
            category: "connectivity"
        },
        {
            label: Tr.tr("Services"),
            icon: "build",
            description: Tr.tr("Input steps, polling, media"),
            category: "system"
        },
        {
            label: Tr.tr("Language & region"),
            icon: "globe",
            description: Tr.tr("UI language, units"),
            category: "system"
        },
        {
            label: Tr.tr("About"),
            icon: "info",
            description: Tr.tr("System information"),
            category: "system"
        }
    ]
}
