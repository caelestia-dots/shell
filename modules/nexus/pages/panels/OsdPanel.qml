pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("OSD")
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
            text: Tr.trCtx("Enabled", "toggle label")
            subtext: Tr.tr("Show the on-screen display panel")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal when the cursor reaches the screen edge")
            checked: Config.osd.showOnHover
            onToggled: GlobalConfig.osd.showOnHover = checked
        }

        StepperRow {
            last: true
            label: Tr.tr("Hide delay")
            subtext: Tr.tr("Time before the OSD closes (ms)")
            value: Config.osd.hideDelay
            from: 500
            to: 5000
            stepSize: 100
            onMoved: v => GlobalConfig.osd.hideDelay = v
        }

        // Sliders
        SectionHeader {
            text: Tr.tr("Sliders")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Brightness")
            subtext: Tr.tr("Show the screen brightness slider")
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Microphone")
            subtext: Tr.tr("Show the microphone input slider")
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }
    }
}
