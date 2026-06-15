pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Taskbar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Behaviour
        SectionHeader {
            first: true
            text: qsTr("Behaviour")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Persistent")
            subtext: qsTr("Keep the bar visible at all times")
            checked: Config.bar.persistent
            onToggled: GlobalConfig.bar.persistent = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal the bar when the cursor reaches the screen edge")
            checked: Config.bar.showOnHover
            onToggled: GlobalConfig.bar.showOnHover = checked
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the bar reveals")
            value: Config.bar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.bar.dragThreshold = v
        }

        // Components
        SectionHeader {
            text: qsTr("Components")
        }

        NavRow {
            first: true
            icon: "workspaces"
            label: qsTr("Workspaces")
            status: qsTr("Indicators, window icons")
            onClicked: root.nState.openSubPage(5)
        }

        NavRow {
            icon: "web_asset"
            label: qsTr("Active window")
            status: qsTr("Title display, popout")
            onClicked: root.nState.openSubPage(6)
        }

        NavRow {
            icon: "widgets"
            label: qsTr("Tray")
            status: qsTr("System tray icons")
            onClicked: root.nState.openSubPage(7)
        }

        NavRow {
            icon: "signal_cellular_alt"
            label: qsTr("Status icons")
            status: qsTr("Visible indicators")
            onClicked: root.nState.openSubPage(8)
        }

        NavRow {
            last: true
            icon: "schedule"
            label: qsTr("Clock")
            status: qsTr("Date, icon, background")
            onClicked: root.nState.openSubPage(9)
        }

        // Scroll actions
        SectionHeader {
            text: qsTr("Scroll actions")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Workspaces")
            subtext: qsTr("Scroll over the workspace indicator to switch workspaces")
            checked: Config.bar.scrollActions.workspaces
            onToggled: GlobalConfig.bar.scrollActions.workspaces = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Volume")
            subtext: qsTr("Scroll on the top half of the bar to adjust volume")
            checked: Config.bar.scrollActions.volume
            onToggled: GlobalConfig.bar.scrollActions.volume = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Brightness")
            subtext: qsTr("Scroll on the bottom half of the bar to adjust brightness")
            checked: Config.bar.scrollActions.brightness
            onToggled: GlobalConfig.bar.scrollActions.brightness = checked
        }
    }
}
