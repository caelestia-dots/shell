pragma Singleton

import QtQuick
import Quickshell

// A flat index of every searchable setting. pageIdx matches
// PageCompRegistry.pageComps; subPath is the chain of sub-pages to open. The
// crumb* lists hold the icon + label for each step of the path, shown as a
// vertical breadcrumb in the search results.
//
// To make a new setting searchable add a SettingEntry here and give the row a
// matching settingAnchor.
Singleton {
    id: root

    readonly property list<SettingEntry> entries: [

        // Wallpaper & style
        SettingEntry {
            pageIdx: 0
            subPath: []
            crumbIcons: ["palette"]
            crumbLabels: ["Wallpaper & style"]
            title: qsTr("Display wallpaper")
            keywords: "display style wallpaper"
            anchor: "style-display-wallpaper"
        },
        SettingEntry {
            pageIdx: 0
            subPath: []
            crumbIcons: ["palette"]
            crumbLabels: ["Wallpaper & style"]
            title: qsTr("Transparency")
            keywords: "style transparency wallpaper"
            anchor: "style-transparency"
        },
        SettingEntry {
            pageIdx: 0
            subPath: []
            crumbIcons: ["palette"]
            crumbLabels: ["Wallpaper & style"]
            title: qsTr("Dark theme")
            keywords: "dark style theme wallpaper"
            anchor: "style-dark-theme"
        },

        // Network
        SettingEntry {
            pageIdx: 1
            subPath: []
            crumbIcons: ["wifi"]
            crumbLabels: ["Network"]
            title: qsTr("Wi-Fi")
            keywords: "network wi-fi"
            anchor: "network-wi-fi"
        },

        // Bluetooth
        SettingEntry {
            pageIdx: 2
            subPath: []
            crumbIcons: ["devices_other"]
            crumbLabels: ["Bluetooth"]
            title: qsTr("Bluetooth")
            keywords: "bluetooth"
            anchor: "bluetooth-bluetooth"
        },
        SettingEntry {
            pageIdx: 2
            subPath: []
            crumbIcons: ["devices_other"]
            crumbLabels: ["Bluetooth"]
            title: qsTr("Discoverable")
            keywords: "bluetooth discoverable"
            anchor: "bluetooth-discoverable"
        },
        SettingEntry {
            pageIdx: 2
            subPath: []
            crumbIcons: ["devices_other"]
            crumbLabels: ["Bluetooth"]
            title: qsTr("Pairable")
            keywords: "bluetooth pairable"
            anchor: "bluetooth-pairable"
        },

        // Audio
        SettingEntry {
            pageIdx: 3
            subPath: []
            crumbIcons: ["volume_up"]
            crumbLabels: ["Audio"]
            title: qsTr("Output")
            keywords: "audio output"
            anchor: "audio-output"
        },
        SettingEntry {
            pageIdx: 3
            subPath: []
            crumbIcons: ["volume_up"]
            crumbLabels: ["Audio"]
            title: qsTr("Input")
            keywords: "audio input"
            anchor: "audio-input"
        },

        // Panels
        SettingEntry {
            pageIdx: 6
            subPath: []
            crumbIcons: ["dock_to_bottom"]
            crumbLabels: ["Panels"]
            title: qsTr("Dashboard")
            keywords: "dashboard panels"
            anchor: "panels-dashboard"
        },
        SettingEntry {
            pageIdx: 6
            subPath: []
            crumbIcons: ["dock_to_bottom"]
            crumbLabels: ["Panels"]
            title: qsTr("Taskbar")
            keywords: "panels taskbar"
            anchor: "panels-taskbar"
        },
        SettingEntry {
            pageIdx: 6
            subPath: []
            crumbIcons: ["dock_to_bottom"]
            crumbLabels: ["Panels"]
            title: qsTr("Launcher")
            keywords: "launcher panels"
            anchor: "panels-launcher"
        },
        SettingEntry {
            pageIdx: 6
            subPath: []
            crumbIcons: ["dock_to_bottom"]
            crumbLabels: ["Panels"]
            title: qsTr("Sidebar")
            keywords: "panels sidebar"
            anchor: "panels-sidebar"
        },

        // Panels > Dashboard
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Enabled")
            keywords: "dashboard enabled panels"
            anchor: "dash-enabled"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Show on hover")
            keywords: "dashboard hover on panels show"
            anchor: "dash-show-on-hover"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Dashboard")
            keywords: "dashboard panels"
            anchor: "dash-dashboard"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Media")
            keywords: "dashboard media panels"
            anchor: "dash-media"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Performance")
            keywords: "dashboard panels performance"
            anchor: "dash-performance"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Weather")
            keywords: "dashboard panels weather"
            anchor: "dash-weather"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Battery")
            keywords: "battery dashboard panels"
            anchor: "dash-battery"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("GPU")
            keywords: "dashboard gpu panels"
            anchor: "dash-gpu"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("CPU")
            keywords: "cpu dashboard panels"
            anchor: "dash-cpu"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Memory")
            keywords: "dashboard memory panels"
            anchor: "dash-memory"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Storage")
            keywords: "dashboard panels storage"
            anchor: "dash-storage"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Network")
            keywords: "dashboard network panels"
            anchor: "dash-network"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [1]
            crumbIcons: ["dock_to_bottom", "dashboard"]
            crumbLabels: ["Panels", "Dashboard"]
            title: qsTr("Drag threshold")
            keywords: "dashboard drag panels threshold"
            anchor: "dash-drag-threshold"
        },

        // Panels > Taskbar
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Persistent")
            keywords: "panels persistent taskbar"
            anchor: "taskbar-persistent"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Show on hover")
            keywords: "hover on panels show taskbar"
            anchor: "taskbar-show-on-hover"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Drag threshold")
            keywords: "drag panels taskbar threshold"
            anchor: "taskbar-drag-threshold"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Workspaces")
            keywords: "panels taskbar workspaces"
            anchor: "taskbar-workspaces"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Active window")
            keywords: "active panels taskbar window"
            anchor: "taskbar-active-window"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Tray")
            keywords: "panels taskbar tray"
            anchor: "taskbar-tray"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Status icons")
            keywords: "icons panels status taskbar"
            anchor: "taskbar-status-icons"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Clock")
            keywords: "clock panels taskbar"
            anchor: "taskbar-clock"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Workspaces")
            keywords: "panels taskbar workspaces"
            anchor: "taskbar-workspaces-2"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Volume")
            keywords: "panels taskbar volume"
            anchor: "taskbar-volume"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom"]
            crumbLabels: ["Panels", "Taskbar"]
            title: qsTr("Brightness")
            keywords: "brightness panels taskbar"
            anchor: "taskbar-brightness"
        },

        // Panels > Launcher
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Enabled")
            keywords: "enabled launcher panels"
            anchor: "launcher-enabled"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Show on hover")
            keywords: "hover launcher on panels show"
            anchor: "launcher-show-on-hover"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Max items shown")
            keywords: "items launcher max panels shown"
            anchor: "launcher-max-items-shown"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Max wallpapers")
            keywords: "launcher max panels wallpapers"
            anchor: "launcher-max-wallpapers"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Drag threshold")
            keywords: "drag launcher panels threshold"
            anchor: "launcher-drag-threshold"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Vim keybinds")
            keywords: "keybinds launcher panels vim"
            anchor: "launcher-vim-keybinds"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Enable dangerous actions")
            keywords: "actions dangerous enable launcher panels"
            anchor: "launcher-enable-dangerous-actions"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Apps")
            keywords: "apps launcher panels"
            anchor: "launcher-apps"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Actions")
            keywords: "actions launcher panels"
            anchor: "launcher-actions"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Schemes")
            keywords: "launcher panels schemes"
            anchor: "launcher-schemes"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Variants")
            keywords: "launcher panels variants"
            anchor: "launcher-variants"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [3]
            crumbIcons: ["dock_to_bottom", "apps"]
            crumbLabels: ["Panels", "Launcher"]
            title: qsTr("Wallpapers")
            keywords: "launcher panels wallpapers"
            anchor: "launcher-wallpapers"
        },

        // Panels > Sidebar
        SettingEntry {
            pageIdx: 6
            subPath: [4]
            crumbIcons: ["dock_to_bottom", "dock_to_right"]
            crumbLabels: ["Panels", "Sidebar"]
            title: qsTr("Enabled")
            keywords: "enabled panels sidebar"
            anchor: "sidebar-enabled"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [4]
            crumbIcons: ["dock_to_bottom", "dock_to_right"]
            crumbLabels: ["Panels", "Sidebar"]
            title: qsTr("Drag threshold")
            keywords: "drag panels sidebar threshold"
            anchor: "sidebar-drag-threshold"
        },

        // Panels > Taskbar > Workspaces
        SettingEntry {
            pageIdx: 6
            subPath: [2, 5]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "workspaces"]
            crumbLabels: ["Panels", "Taskbar", "Workspaces"]
            title: qsTr("Shown")
            keywords: "panels shown taskbar workspaces"
            anchor: "bar-ws-shown"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 5]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "workspaces"]
            crumbLabels: ["Panels", "Taskbar", "Workspaces"]
            title: qsTr("Active indicator")
            keywords: "active indicator panels taskbar workspaces"
            anchor: "bar-ws-active-indicator"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 5]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "workspaces"]
            crumbLabels: ["Panels", "Taskbar", "Workspaces"]
            title: qsTr("Active trail")
            keywords: "active panels taskbar trail workspaces"
            anchor: "bar-ws-active-trail"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 5]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "workspaces"]
            crumbLabels: ["Panels", "Taskbar", "Workspaces"]
            title: qsTr("Occupied background")
            keywords: "background occupied panels taskbar workspaces"
            anchor: "bar-ws-occupied-background"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 5]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "workspaces"]
            crumbLabels: ["Panels", "Taskbar", "Workspaces"]
            title: qsTr("Show windows")
            keywords: "panels show taskbar windows workspaces"
            anchor: "bar-ws-show-windows"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 5]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "workspaces"]
            crumbLabels: ["Panels", "Taskbar", "Workspaces"]
            title: qsTr("Windows on special workspaces")
            keywords: "on panels special taskbar windows workspaces"
            anchor: "bar-ws-windows-on-special-workspaces"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 5]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "workspaces"]
            crumbLabels: ["Panels", "Taskbar", "Workspaces"]
            title: qsTr("Max window icons")
            keywords: "icons max panels taskbar window workspaces"
            anchor: "bar-ws-max-window-icons"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 5]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "workspaces"]
            crumbLabels: ["Panels", "Taskbar", "Workspaces"]
            title: qsTr("Per-monitor workspaces")
            keywords: "panels per-monitor taskbar workspaces"
            anchor: "bar-ws-per-monitor-workspaces"
        },

        // Panels > Taskbar > Active window
        SettingEntry {
            pageIdx: 6
            subPath: [2, 6]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "web_asset"]
            crumbLabels: ["Panels", "Taskbar", "Active window"]
            title: qsTr("Compact")
            keywords: "active compact panels taskbar window"
            anchor: "bar-aw-compact"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 6]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "web_asset"]
            crumbLabels: ["Panels", "Taskbar", "Active window"]
            title: qsTr("Inverted")
            keywords: "active inverted panels taskbar window"
            anchor: "bar-aw-inverted"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 6]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "web_asset"]
            crumbLabels: ["Panels", "Taskbar", "Active window"]
            title: qsTr("Show on hover")
            keywords: "active hover on panels show taskbar window"
            anchor: "bar-aw-show-on-hover"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 6]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "web_asset"]
            crumbLabels: ["Panels", "Taskbar", "Active window"]
            title: qsTr("Popout on hover")
            keywords: "active hover on panels popout taskbar window"
            anchor: "bar-aw-popout-on-hover"
        },

        // Panels > Taskbar > Tray
        SettingEntry {
            pageIdx: 6
            subPath: [2, 7]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "widgets"]
            crumbLabels: ["Panels", "Taskbar", "Tray"]
            title: qsTr("Background")
            keywords: "background panels taskbar tray"
            anchor: "bar-tray-background"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 7]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "widgets"]
            crumbLabels: ["Panels", "Taskbar", "Tray"]
            title: qsTr("Recolour icons")
            keywords: "icons panels recolour taskbar tray"
            anchor: "bar-tray-recolour-icons"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 7]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "widgets"]
            crumbLabels: ["Panels", "Taskbar", "Tray"]
            title: qsTr("Compact")
            keywords: "compact panels taskbar tray"
            anchor: "bar-tray-compact"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 7]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "widgets"]
            crumbLabels: ["Panels", "Taskbar", "Tray"]
            title: qsTr("Popout on hover")
            keywords: "hover on panels popout taskbar tray"
            anchor: "bar-tray-popout-on-hover"
        },

        // Panels > Taskbar > Status icons
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Speakers")
            keywords: "icons panels speakers status taskbar"
            anchor: "bar-si-speakers"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Microphone")
            keywords: "icons microphone panels status taskbar"
            anchor: "bar-si-microphone"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Keyboard layout")
            keywords: "icons keyboard layout panels status taskbar"
            anchor: "bar-si-keyboard-layout"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Network")
            keywords: "icons network panels status taskbar"
            anchor: "bar-si-network"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Wi-Fi")
            keywords: "icons panels status taskbar wi-fi"
            anchor: "bar-si-wi-fi"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Bluetooth")
            keywords: "bluetooth icons panels status taskbar"
            anchor: "bar-si-bluetooth"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Battery")
            keywords: "battery icons panels status taskbar"
            anchor: "bar-si-battery"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Caps lock")
            keywords: "caps icons lock panels status taskbar"
            anchor: "bar-si-caps-lock"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 8]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "signal_cellular_alt"]
            crumbLabels: ["Panels", "Taskbar", "Status icons"]
            title: qsTr("Popout on hover")
            keywords: "hover icons on panels popout status taskbar"
            anchor: "bar-si-popout-on-hover"
        },

        // Panels > Taskbar > Clock
        SettingEntry {
            pageIdx: 6
            subPath: [2, 9]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "schedule"]
            crumbLabels: ["Panels", "Taskbar", "Clock"]
            title: qsTr("Background")
            keywords: "background clock panels taskbar"
            anchor: "bar-clock-background"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 9]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "schedule"]
            crumbLabels: ["Panels", "Taskbar", "Clock"]
            title: qsTr("Show date")
            keywords: "clock date panels show taskbar"
            anchor: "bar-clock-show-date"
        },
        SettingEntry {
            pageIdx: 6
            subPath: [2, 9]
            crumbIcons: ["dock_to_bottom", "dock_to_bottom", "schedule"]
            crumbLabels: ["Panels", "Taskbar", "Clock"]
            title: qsTr("Show icon")
            keywords: "clock icon panels show taskbar"
            anchor: "bar-clock-show-icon"
        },

        // Apps
        SettingEntry {
            pageIdx: 7
            subPath: []
            crumbIcons: ["apps"]
            crumbLabels: ["Apps"]
            title: qsTr("All apps")
            keywords: "all apps"
            anchor: "apps-all-apps"
        },

        // Services
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Notifications")
            keywords: "notifications services"
            anchor: "services-notifications"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Media refresh")
            keywords: "media refresh services"
            anchor: "services-media-refresh"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("System stats refresh")
            keywords: "refresh services stats system"
            anchor: "services-system-stats-refresh"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Wi-Fi rescan")
            keywords: "rescan services wi-fi"
            anchor: "services-wi-fi-rescan"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Lyrics backend")
            keywords: "backend lyrics services"
            anchor: "services-lyrics-backend"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Default player")
            keywords: "default player services"
            anchor: "services-default-player"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Volume step")
            keywords: "services step volume"
            anchor: "services-volume-step"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Brightness step")
            keywords: "brightness services step"
            anchor: "services-brightness-step"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Max volume")
            keywords: "max services volume"
            anchor: "services-max-volume"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Visualiser bars")
            keywords: "bars services visualiser"
            anchor: "services-visualiser-bars"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("Smart colour scheme")
            keywords: "colour scheme services smart"
            anchor: "services-smart-colour-scheme"
        },
        SettingEntry {
            pageIdx: 8
            subPath: []
            crumbIcons: ["build"]
            crumbLabels: ["Services"]
            title: qsTr("GPU")
            keywords: "gpu services"
            anchor: "services-gpu"
        },

        // Services > Notifications
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Show in fullscreen")
            keywords: "fullscreen in notifications services show"
            anchor: "notif-show-in-fullscreen"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Expire automatically")
            keywords: "automatically expire notifications services"
            anchor: "notif-expire-automatically"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Open expanded")
            keywords: "expanded notifications open services"
            anchor: "notif-open-expanded"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Default timeout")
            keywords: "default notifications services timeout"
            anchor: "notif-default-timeout"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Group preview count")
            keywords: "count group notifications preview services"
            anchor: "notif-group-preview-count"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Show in fullscreen")
            keywords: "fullscreen in notifications services show"
            anchor: "notif-show-in-fullscreen-2"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Visible toasts")
            keywords: "notifications services toasts visible"
            anchor: "notif-visible-toasts"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Charging changes")
            keywords: "changes charging notifications services"
            anchor: "notif-charging-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Game mode changes")
            keywords: "changes game mode notifications services"
            anchor: "notif-game-mode-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Do not disturb changes")
            keywords: "changes disturb do not notifications services"
            anchor: "notif-do-not-disturb-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Audio output changes")
            keywords: "audio changes notifications output services"
            anchor: "notif-audio-output-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Audio input changes")
            keywords: "audio changes input notifications services"
            anchor: "notif-audio-input-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Caps lock changes")
            keywords: "caps changes lock notifications services"
            anchor: "notif-caps-lock-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Num lock changes")
            keywords: "changes lock notifications num services"
            anchor: "notif-num-lock-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Keyboard layout changes")
            keywords: "changes keyboard layout notifications services"
            anchor: "notif-keyboard-layout-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("VPN changes")
            keywords: "changes notifications services vpn"
            anchor: "notif-vpn-changes"
        },
        SettingEntry {
            pageIdx: 8
            subPath: [1]
            crumbIcons: ["build", "notifications"]
            crumbLabels: ["Services", "Notifications"]
            title: qsTr("Now playing")
            keywords: "notifications now playing services"
            anchor: "notif-now-playing"
        },

        // Language & region
        SettingEntry {
            pageIdx: 9
            subPath: []
            crumbIcons: ["globe"]
            crumbLabels: ["Language & region"]
            title: qsTr("Temperature")
            keywords: "language region temperature"
            anchor: "lang-temperature"
        },
        SettingEntry {
            pageIdx: 9
            subPath: []
            crumbIcons: ["globe"]
            crumbLabels: ["Language & region"]
            title: qsTr("System temperatures")
            keywords: "language region system temperatures"
            anchor: "lang-system-temperatures"
        },
        SettingEntry {
            pageIdx: 9
            subPath: []
            crumbIcons: ["globe"]
            crumbLabels: ["Language & region"]
            title: qsTr("Clock format")
            keywords: "clock format language region"
            anchor: "lang-clock-format"
        }
    ]

    component SettingEntry: QtObject {
        required property int pageIdx
        property list<int> subPath: []
        required property list<string> crumbIcons
        required property list<string> crumbLabels
        required property string title
        property string keywords
        property string anchor
    }
}
