pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Dashboard")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            settingAnchor: "dash-enabled"
            text: Tr.trCtx("Enabled", "toggle label")
            checked: Config.dashboard.enabled
            onToggled: GlobalConfig.dashboard.enabled = checked
        }

        ToggleRow {
            settingAnchor: "dash-show-on-hover"
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal when the cursor reaches the screen edge")
            checked: Config.dashboard.showOnHover
            onToggled: GlobalConfig.dashboard.showOnHover = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Show clock seconds")
            subtext: Tr.tr("Display seconds for the clock in the main panel")
            checked: Config.dashboard.showClockSeconds
            onToggled: GlobalConfig.dashboard.showClockSeconds = checked
        }

        // Tabs
        SectionHeader {
            text: Tr.tr("Tabs")
        }

        ToggleRow {
            first: true
            settingAnchor: "dash-dashboard"
            text: Tr.tr("Dashboard")
            checked: Config.dashboard.showDashboard
            onToggled: GlobalConfig.dashboard.showDashboard = checked
        }

        ToggleRow {
            settingAnchor: "dash-media"
            text: Tr.tr("Media")
            checked: Config.dashboard.showMedia
            onToggled: GlobalConfig.dashboard.showMedia = checked
        }

        ToggleRow {
            settingAnchor: "dash-performance"
            text: Tr.tr("Performance")
            checked: Config.dashboard.showPerformance
            onToggled: GlobalConfig.dashboard.showPerformance = checked
        }

        ToggleRow {
            last: true
            settingAnchor: "dash-weather"
            text: Tr.tr("Weather")
            checked: Config.dashboard.showWeather
            onToggled: GlobalConfig.dashboard.showWeather = checked
        }

        // Performance widgets
        SectionHeader {
            text: Tr.tr("Performance widgets")
        }

        ToggleRow {
            first: true
            settingAnchor: "dash-battery"
            text: Tr.tr("Battery")
            checked: Config.dashboard.performance.showBattery
            onToggled: GlobalConfig.dashboard.performance.showBattery = checked
        }

        ToggleRow {
            settingAnchor: "dash-gpu"
            text: Tr.tr("GPU")
            checked: Config.dashboard.performance.showGpu
            onToggled: GlobalConfig.dashboard.performance.showGpu = checked
        }

        ToggleRow {
            settingAnchor: "dash-cpu"
            text: Tr.tr("CPU")
            checked: Config.dashboard.performance.showCpu
            onToggled: GlobalConfig.dashboard.performance.showCpu = checked
        }

        ToggleRow {
            settingAnchor: "dash-memory"
            text: Tr.tr("Memory")
            checked: Config.dashboard.performance.showMemory
            onToggled: GlobalConfig.dashboard.performance.showMemory = checked
        }

        ToggleRow {
            settingAnchor: "dash-storage"
            text: Tr.tr("Storage")
            checked: Config.dashboard.performance.showStorage
            onToggled: GlobalConfig.dashboard.performance.showStorage = checked
        }

        ToggleRow {
            last: true
            settingAnchor: "dash-network"
            text: Tr.tr("Network")
            checked: Config.dashboard.performance.showNetwork
            onToggled: GlobalConfig.dashboard.performance.showNetwork = checked
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        StepperRow {
            first: true
            last: true
            settingAnchor: "dash-drag-threshold"
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the dashboard opens")
            value: Config.dashboard.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.dashboard.dragThreshold = v
        }
    }
}
