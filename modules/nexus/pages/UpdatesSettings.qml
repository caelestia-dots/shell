pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Update settings")
    isSubPage: true

    readonly property list<MenuItem> wrapperItems: [
        MenuItem { text: "yay" },
        MenuItem { text: "paru" },
        MenuItem { text: "trizen" },
        MenuItem { text: "pikaur" },
        MenuItem { text: "aura" }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Sources")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Arch repositories")
            subtext: Tr.tr("Official packages via checkupdates")
            checked: GlobalConfig.utilities.updates.checkArch
            onToggled: GlobalConfig.utilities.updates.checkArch = checked
        }

        ToggleRow {
            text: Tr.tr("AUR")
            subtext: Tr.tr("Arch User Repository via the selected wrapper")
            checked: GlobalConfig.utilities.updates.checkAur
            onToggled: GlobalConfig.utilities.updates.checkAur = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Flatpak")
            subtext: Tr.tr("Flatpak remotes")
            checked: GlobalConfig.utilities.updates.checkFlatpak
            onToggled: GlobalConfig.utilities.updates.checkFlatpak = checked
        }

        SectionHeader {
            text: Tr.tr("AUR wrapper")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Wrapper")
            subtext: Tr.tr("Used for AUR checks and installs")
            menuItems: root.wrapperItems
            active: root.wrapperItems.find(i => i.text === (GlobalConfig.utilities.updates.aurWrapper || "yay")) ?? root.wrapperItems[0]
            onSelected: item => GlobalConfig.utilities.updates.aurWrapper = item.text
        }

        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        StepperRow {
            first: true
            label: Tr.tr("Poll interval")
            subtext: Tr.tr("Minutes between automatic checks")
            value: GlobalConfig.utilities.updates.pollIntervalMinutes
            from: 5
            to: 180
            stepSize: 5
            onMoved: v => GlobalConfig.utilities.updates.pollIntervalMinutes = Math.round(v)
        }

        ToggleRow {
            text: Tr.tr("Notify on new updates")
            subtext: Tr.tr("Toast when newly available packages are detected")
            checked: GlobalConfig.utilities.updates.notifications
            onToggled: GlobalConfig.utilities.updates.notifications = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Allow single-package updates")
            subtext: Tr.tr("Risky: can break partial upgrades on Arch")
            checked: GlobalConfig.utilities.updates.allowSingleModification
            onToggled: GlobalConfig.utilities.updates.allowSingleModification = checked
        }
    }
}
