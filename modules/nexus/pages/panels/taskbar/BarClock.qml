pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Clock")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: Tr.trCtx("Background", "taskbar clock: draw a background behind the clock")
            checked: Config.bar.clock.background
            onToggled: GlobalConfig.bar.clock.background = checked
        }

        ToggleRow {
            text: Tr.tr("Show date")
            checked: Config.bar.clock.showDate
            onToggled: GlobalConfig.bar.clock.showDate = checked
        }

        ToggleRow {
            text: Tr.tr("Show icon")
            checked: Config.bar.clock.showIcon
            onToggled: GlobalConfig.bar.clock.showIcon = checked
        }

        ToggleRow {
            text: Tr.tr("Show seconds")
            checked: Config.bar.clock.showSeconds
            onToggled: GlobalConfig.bar.clock.showSeconds = checked
        }

        ToggleRow {
            text: Tr.tr("Popout on hover")
            subtext: Tr.tr("Show an analog clock and digital time when hovering")
            checked: Config.bar.popouts.clock
            onToggled: GlobalConfig.bar.popouts.clock = checked
        }

        StepperRow {
            last: true
            label: Tr.tr("Hover delay")
            subtext: Tr.tr("Milliseconds before the clock popout opens")
            value: Config.bar.clock.hoverDelay
            from: 0
            to: 1000
            stepSize: 20
            onMoved: value => GlobalConfig.bar.clock.hoverDelay = value
        }
    }
}
