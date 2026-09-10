import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // Notification fullscreen visibility, ordered to match config::NotifsFullscreen (On, Off)
    readonly property list<MenuItem> notifFullscreenItems: [
        MenuItem {
            text: Tr.trCtx("On", "show notifications over fullscreen apps")
            icon: "notifications"
        },
        MenuItem {
            text: Tr.trCtx("Off", "show notifications over fullscreen apps")
            icon: "notifications_off"
        }
    ]

    // Toast fullscreen visibility, mapped to GlobalConfig.utilities.toasts.fullscreen
    readonly property list<MenuItem> toastFullscreenItems: [
        MenuItem {
            text: Tr.trCtx("Off", "show toasts over fullscreen apps")
            icon: "notifications_off"
        },
        MenuItem {
            text: Tr.trCtx("Important", "show toasts over fullscreen apps: important ones only")
            icon: "priority_high"
        },
        MenuItem {
            text: Tr.trCtx("On", "show toasts over fullscreen apps")
            icon: "notifications"
        }
    ]
    readonly property list<string> toastFullscreenValues: ["off", "important", "all"]

    title: Tr.tr("Notifications")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Notifications
        SectionHeader {
            first: true
            text: Tr.tr("Notifications")
        }

        SelectRow {
            first: true
            settingAnchor: "notif-show-in-fullscreen"
            label: Tr.tr("Show in fullscreen")
            subtext: Tr.tr("Whether notifications appear over fullscreen apps")
            menuItems: root.notifFullscreenItems
            active: root.notifFullscreenItems[GlobalConfig.notifs.fullscreen]
            onSelected: item => GlobalConfig.notifs.fullscreen = root.notifFullscreenItems.indexOf(item)
        }

        ToggleRow {
            settingAnchor: "notif-expire-automatically"
            text: Tr.tr("Expire automatically")
            subtext: Tr.tr("Dismiss notifications after their timeout")
            checked: GlobalConfig.notifs.expire
            onToggled: GlobalConfig.notifs.expire = checked
        }

        ToggleRow {
            settingAnchor: "notif-open-expanded"
            text: Tr.tr("Open expanded")
            subtext: Tr.tr("Show notifications expanded by default")
            checked: GlobalConfig.notifs.openExpanded
            onToggled: GlobalConfig.notifs.openExpanded = checked
        }

        StepperRow {
            settingAnchor: "notif-default-timeout"
            label: Tr.tr("Default timeout")
            // TRANSLATORS: ms is the millisecond unit, leave it untranslated
            subtext: Tr.tr("Time before a notification dismisses (ms)")
            value: GlobalConfig.notifs.defaultExpireTimeout
            from: 1000
            to: 60000
            stepSize: 500
            onMoved: v => GlobalConfig.notifs.defaultExpireTimeout = Math.round(v)
        }

        StepperRow {
            last: true
            settingAnchor: "notif-group-preview-count"
            label: Tr.tr("Group preview count")
            subtext: Tr.tr("Notifications shown per group before collapsing")
            value: GlobalConfig.notifs.groupPreviewNum
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.notifs.groupPreviewNum = Math.round(v)
        }

        // Toasts
        SectionHeader {
            text: Tr.tr("Toasts")
        }

        SelectRow {
            first: true
            settingAnchor: "notif-show-in-fullscreen-2"
            label: Tr.tr("Show in fullscreen")
            subtext: Tr.tr("Whether toasts appear over fullscreen apps")
            menuItems: root.toastFullscreenItems
            active: root.toastFullscreenItems[Math.max(0, root.toastFullscreenValues.indexOf(GlobalConfig.utilities.toasts.fullscreen))]
            onSelected: item => GlobalConfig.utilities.toasts.fullscreen = root.toastFullscreenValues[root.toastFullscreenItems.indexOf(item)]
        }

        StepperRow {
            last: true
            settingAnchor: "notif-visible-toasts"
            label: Tr.tr("Visible toasts")
            subtext: Tr.tr("Maximum number of toasts shown at once")
            value: GlobalConfig.utilities.maxToasts
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.utilities.maxToasts = Math.round(v)
        }

        // Toast events
        SectionHeader {
            text: Tr.tr("Toast events")
        }

        ToggleRow {
            first: true
            settingAnchor: "notif-charging-changes"
            text: Tr.tr("Charging changes")
            checked: GlobalConfig.utilities.toasts.chargingChanged
            onToggled: GlobalConfig.utilities.toasts.chargingChanged = checked
        }

        ToggleRow {
            settingAnchor: "notif-game-mode-changes"
            text: Tr.tr("Game mode changes")
            checked: GlobalConfig.utilities.toasts.gameModeChanged
            onToggled: GlobalConfig.utilities.toasts.gameModeChanged = checked
        }

        ToggleRow {
            settingAnchor: "notif-do-not-disturb-changes"
            text: Tr.tr("Do not disturb changes")
            checked: GlobalConfig.utilities.toasts.dndChanged
            onToggled: GlobalConfig.utilities.toasts.dndChanged = checked
        }

        ToggleRow {
            settingAnchor: "notif-audio-output-changes"
            text: Tr.tr("Audio output changes")
            checked: GlobalConfig.utilities.toasts.audioOutputChanged
            onToggled: GlobalConfig.utilities.toasts.audioOutputChanged = checked
        }

        ToggleRow {
            settingAnchor: "notif-audio-input-changes"
            text: Tr.tr("Audio input changes")
            checked: GlobalConfig.utilities.toasts.audioInputChanged
            onToggled: GlobalConfig.utilities.toasts.audioInputChanged = checked
        }

        ToggleRow {
            settingAnchor: "notif-caps-lock-changes"
            text: Tr.tr("Caps lock changes")
            checked: GlobalConfig.utilities.toasts.capsLockChanged
            onToggled: GlobalConfig.utilities.toasts.capsLockChanged = checked
        }

        ToggleRow {
            settingAnchor: "notif-num-lock-changes"
            text: Tr.tr("Num lock changes")
            checked: GlobalConfig.utilities.toasts.numLockChanged
            onToggled: GlobalConfig.utilities.toasts.numLockChanged = checked
        }

        ToggleRow {
            settingAnchor: "notif-keyboard-layout-changes"
            text: Tr.tr("Keyboard layout changes")
            checked: GlobalConfig.utilities.toasts.kbLayoutChanged
            onToggled: GlobalConfig.utilities.toasts.kbLayoutChanged = checked
        }

        ToggleRow {
            settingAnchor: "notif-vpn-changes"
            text: Tr.tr("VPN changes")
            checked: GlobalConfig.utilities.toasts.vpnChanged
            onToggled: GlobalConfig.utilities.toasts.vpnChanged = checked
        }

        ToggleRow {
            last: true
            settingAnchor: "notif-now-playing"
            text: Tr.tr("Now playing")
            checked: GlobalConfig.utilities.toasts.nowPlaying
            onToggled: GlobalConfig.utilities.toasts.nowPlaying = checked
        }
    }
}
