import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // Notification fullscreen visibility, mapped to GlobalConfig.notifs.fullscreen
    readonly property list<MenuItem> notifFullscreenItems: [
        MenuItem {
            text: qsTr("Off")
            icon: "notifications_off"
        },
        MenuItem {
            text: qsTr("On")
            icon: "notifications"
        }
    ]
    readonly property list<string> notifFullscreenValues: ["off", "on"]

    // Toast fullscreen visibility, mapped to GlobalConfig.utilities.toasts.fullscreen
    readonly property list<MenuItem> toastFullscreenItems: [
        MenuItem {
            text: qsTr("Off")
            icon: "notifications_off"
        },
        MenuItem {
            text: qsTr("Important")
            icon: "priority_high"
        },
        MenuItem {
            text: qsTr("On")
            icon: "notifications"
        }
    ]
    readonly property list<string> toastFullscreenValues: ["off", "important", "all"]

    title: qsTr("Notifications")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Notifications
        SectionHeader {
            first: true
            text: qsTr("Notifications")
        }

        SelectRow {
            first: true
            label: qsTr("Show in fullscreen")
            subtext: qsTr("Whether notifications appear over fullscreen apps")
            menuItems: root.notifFullscreenItems
            active: root.notifFullscreenItems[Math.max(0, root.notifFullscreenValues.indexOf(GlobalConfig.notifs.fullscreen))]
            onSelected: item => GlobalConfig.notifs.fullscreen = root.notifFullscreenValues[root.notifFullscreenItems.indexOf(item)]
        }

        ToggleRow {
            text: qsTr("Expire automatically")
            subtext: qsTr("Dismiss notifications after their timeout")
            checked: GlobalConfig.notifs.expire
            onToggled: GlobalConfig.notifs.expire = checked
        }

        ToggleRow {
            text: qsTr("Open expanded")
            subtext: qsTr("Show notifications expanded by default")
            checked: GlobalConfig.notifs.openExpanded
            onToggled: GlobalConfig.notifs.openExpanded = checked
        }

        StepperRow {
            label: qsTr("Default timeout")
            subtext: qsTr("Time before a notification dismisses (ms)")
            value: GlobalConfig.notifs.defaultExpireTimeout
            from: 1000
            to: 60000
            stepSize: 500
            onMoved: v => GlobalConfig.notifs.defaultExpireTimeout = Math.round(v)
        }

        StepperRow {
            last: true
            label: qsTr("Group preview count")
            subtext: qsTr("Notifications shown per group before collapsing")
            value: GlobalConfig.notifs.groupPreviewNum
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.notifs.groupPreviewNum = Math.round(v)
        }

        // Toasts
        SectionHeader {
            text: qsTr("Toasts")
        }

        SelectRow {
            first: true
            label: qsTr("Show in fullscreen")
            subtext: qsTr("Whether toasts appear over fullscreen apps")
            menuItems: root.toastFullscreenItems
            active: root.toastFullscreenItems[Math.max(0, root.toastFullscreenValues.indexOf(GlobalConfig.utilities.toasts.fullscreen))]
            onSelected: item => GlobalConfig.utilities.toasts.fullscreen = root.toastFullscreenValues[root.toastFullscreenItems.indexOf(item)]
        }

        StepperRow {
            last: true
            label: qsTr("Visible toasts")
            subtext: qsTr("Maximum number of toasts shown at once")
            value: GlobalConfig.utilities.maxToasts
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.utilities.maxToasts = Math.round(v)
        }

        // Toast events
        SectionHeader {
            text: qsTr("Toast events")
        }

        ToggleRow {
            first: true
            text: qsTr("Charging changes")
            checked: GlobalConfig.utilities.toasts.chargingChanged
            onToggled: GlobalConfig.utilities.toasts.chargingChanged = checked
        }

        ToggleRow {
            text: qsTr("Game mode changes")
            checked: GlobalConfig.utilities.toasts.gameModeChanged
            onToggled: GlobalConfig.utilities.toasts.gameModeChanged = checked
        }

        ToggleRow {
            text: qsTr("Do not disturb changes")
            checked: GlobalConfig.utilities.toasts.dndChanged
            onToggled: GlobalConfig.utilities.toasts.dndChanged = checked
        }

        ToggleRow {
            text: qsTr("Audio output changes")
            checked: GlobalConfig.utilities.toasts.audioOutputChanged
            onToggled: GlobalConfig.utilities.toasts.audioOutputChanged = checked
        }

        ToggleRow {
            text: qsTr("Audio input changes")
            checked: GlobalConfig.utilities.toasts.audioInputChanged
            onToggled: GlobalConfig.utilities.toasts.audioInputChanged = checked
        }

        ToggleRow {
            text: qsTr("Caps lock changes")
            checked: GlobalConfig.utilities.toasts.capsLockChanged
            onToggled: GlobalConfig.utilities.toasts.capsLockChanged = checked
        }

        ToggleRow {
            text: qsTr("Num lock changes")
            checked: GlobalConfig.utilities.toasts.numLockChanged
            onToggled: GlobalConfig.utilities.toasts.numLockChanged = checked
        }

        ToggleRow {
            text: qsTr("Keyboard layout changes")
            checked: GlobalConfig.utilities.toasts.kbLayoutChanged
            onToggled: GlobalConfig.utilities.toasts.kbLayoutChanged = checked
        }

        ToggleRow {
            text: qsTr("VPN changes")
            checked: GlobalConfig.utilities.toasts.vpnChanged
            onToggled: GlobalConfig.utilities.toasts.vpnChanged = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Now playing")
            checked: GlobalConfig.utilities.toasts.nowPlaying
            onToggled: GlobalConfig.utilities.toasts.nowPlaying = checked
        }
    }
}
