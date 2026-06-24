pragma Singleton

import QtQuick
import Quickshell

// A flat index of searchable settings. Each entry points at the page that hosts
// it (pageIdx matches PageCompRegistry.pageComps) so the search bar can jump
// straight there. keywords are extra terms that should match but aren't shown.
//
// To make a new setting searchable, add a SettingEntry here. Stage 2 will also
// use the anchor field to scroll to and highlight the exact row.
Singleton {
    id: root

    readonly property list<SettingEntry> entries: [
        // Audio (pageComps[3])
        SettingEntry {
            pageIdx: 3
            page: qsTr("Audio")
            title: qsTr("Output volume")
            description: qsTr("Speaker and headphone level")
            keywords: "sound speaker headphone output loudness"
            anchor: "audio-output"
        },
        SettingEntry {
            pageIdx: 3
            page: qsTr("Audio")
            title: qsTr("Input volume")
            description: qsTr("Microphone level")
            keywords: "microphone mic input recording"
            anchor: "audio-input"
        },
        SettingEntry {
            pageIdx: 3
            page: qsTr("Audio")
            title: qsTr("App volumes")
            description: qsTr("Per-application volume mixer")
            keywords: "mixer per app application streams"
            anchor: "audio-app-volumes"
        },

        // Services (pageComps[8])
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Media refresh")
            description: qsTr("How often the media position updates")
            keywords: "media player position polling interval mpris"
            anchor: "services-media-refresh"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("System stats refresh")
            description: qsTr("CPU, memory and GPU update interval")
            keywords: "cpu memory ram gpu stats resources polling interval"
            anchor: "services-stats-refresh"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Wi-Fi rescan")
            description: qsTr("How often available networks are rescanned")
            keywords: "wifi wireless network rescan scan interval"
            anchor: "services-wifi-rescan"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Lyrics backend")
            description: qsTr("Source used to fetch synced lyrics")
            keywords: "lyrics synced lrclib netease music"
            anchor: "services-lyrics-backend"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Default player")
            description: qsTr("Preferred media player when several are open")
            keywords: "media player default preferred mpris"
            anchor: "services-default-player"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Volume step")
            description: qsTr("Amount the volume changes per scroll")
            keywords: "volume step increment scroll audio"
            anchor: "services-volume-step"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Brightness step")
            description: qsTr("Amount the brightness changes per scroll")
            keywords: "brightness step increment scroll backlight"
            anchor: "services-brightness-step"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Max volume")
            description: qsTr("Upper limit for output volume")
            keywords: "volume max maximum limit cap audio"
            anchor: "services-max-volume"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Notifications")
            description: qsTr("Notification behaviour and history")
            keywords: "notifications notify popup history dnd"
            anchor: "services-notifications"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Visualiser bars")
            description: qsTr("Number of bars in the audio visualisers")
            keywords: "visualiser visualizer bars audio spectrum cava"
            anchor: "services-visualiser-bars"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("Smart colour scheme")
            description: qsTr("Derive theme mode and variant from the wallpaper")
            keywords: "smart colour color scheme theme wallpaper auto"
            anchor: "services-smart-scheme"
        },
        SettingEntry {
            pageIdx: 8
            page: qsTr("Services")
            title: qsTr("GPU")
            description: qsTr("Override for GPU type")
            keywords: "gpu graphics nvidia amd intel monitoring"
            anchor: "services-gpu"
        },

        // Wallpaper & style (pageComps[0])
        SettingEntry {
            pageIdx: 0
            page: qsTr("Wallpaper & style")
            title: qsTr("Display wallpaper")
            description: qsTr("Show a wallpaper on the desktop")
            keywords: "wallpaper background image display desktop"
            anchor: "style-display-wallpaper"
        },
        SettingEntry {
            pageIdx: 0
            page: qsTr("Wallpaper & style")
            title: qsTr("Transparency")
            description: qsTr("Translucent panels and surfaces")
            keywords: "transparency translucent opacity blur"
            anchor: "style-transparency"
        },
        SettingEntry {
            pageIdx: 0
            page: qsTr("Wallpaper & style")
            title: qsTr("Dark theme")
            description: qsTr("Use a dark colour scheme")
            keywords: "dark theme light mode colour scheme"
            anchor: "style-dark-theme"
        },

        // Network (pageComps[1])
        SettingEntry {
            pageIdx: 1
            page: qsTr("Network")
            title: qsTr("Wi-Fi")
            description: qsTr("Enable or disable wireless networking")
            keywords: "wifi wireless network internet connection"
            anchor: "network-wifi"
        },

        // Bluetooth (pageComps[2])
        SettingEntry {
            pageIdx: 2
            page: qsTr("Bluetooth")
            title: qsTr("Bluetooth")
            description: qsTr("Enable or disable Bluetooth")
            keywords: "bluetooth wireless devices pairing"
            anchor: "bluetooth-enabled"
        },
        SettingEntry {
            pageIdx: 2
            page: qsTr("Bluetooth")
            title: qsTr("Discoverable")
            description: qsTr("Let other devices find this one")
            keywords: "bluetooth discoverable visible find devices"
            anchor: "bluetooth-discoverable"
        },
        SettingEntry {
            pageIdx: 2
            page: qsTr("Bluetooth")
            title: qsTr("Pairable")
            description: qsTr("Allow new devices to pair")
            keywords: "bluetooth pairable pairing connect devices"
            anchor: "bluetooth-pairable"
        },

        // Panels (pageComps[6])
        SettingEntry {
            pageIdx: 6
            page: qsTr("Panels")
            title: qsTr("Dashboard")
            description: qsTr("Dashboard panel settings")
            keywords: "dashboard panel widgets overview"
            anchor: "panels-dashboard"
        },
        SettingEntry {
            pageIdx: 6
            page: qsTr("Panels")
            title: qsTr("Taskbar")
            description: qsTr("Taskbar panel settings")
            keywords: "taskbar bar dock panel windows"
            anchor: "panels-taskbar"
        },
        SettingEntry {
            pageIdx: 6
            page: qsTr("Panels")
            title: qsTr("Launcher")
            description: qsTr("Launcher panel settings")
            keywords: "launcher search apps menu run"
            anchor: "panels-launcher"
        },
        SettingEntry {
            pageIdx: 6
            page: qsTr("Panels")
            title: qsTr("Sidebar")
            description: qsTr("Sidebar panel settings")
            keywords: "sidebar panel notifications tray"
            anchor: "panels-sidebar"
        },

        // Apps (pageComps[7])
        SettingEntry {
            pageIdx: 7
            page: qsTr("Apps")
            title: qsTr("All apps")
            description: qsTr("Browse every installed application")
            keywords: "apps applications installed list browse all"
            anchor: "apps-all"
        },

        // Language & region (pageComps[9])
        SettingEntry {
            pageIdx: 9
            page: qsTr("Language & region")
            title: qsTr("Temperature")
            description: qsTr("Temperature unit")
            keywords: "temperature unit celsius fahrenheit weather"
            anchor: "lang-temperature"
        },
        SettingEntry {
            pageIdx: 9
            page: qsTr("Language & region")
            title: qsTr("System temperatures")
            description: qsTr("Unit for system sensor temperatures")
            keywords: "system temperature sensor cpu gpu celsius fahrenheit"
            anchor: "lang-system-temperature"
        },
        SettingEntry {
            pageIdx: 9
            page: qsTr("Language & region")
            title: qsTr("Clock format")
            description: qsTr("12 or 24 hour clock")
            keywords: "clock time format 12 24 hour am pm"
            anchor: "lang-clock-format"
        }
    ]

    component SettingEntry: QtObject {
        required property int pageIdx
        required property string page
        required property string title
        property string description
        property string keywords
        property string anchor
    }
}
