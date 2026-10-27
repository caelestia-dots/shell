pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Complements")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Available")
        }

        ToggleRow {
            first: true
            leadingIcon: "verified_user"
            text: Tr.tr("Madison VPN")
            subtext: MadisonVpn.enabled
                ? (MadisonVpn.connected ? MadisonVpn.statusText : Tr.tr("FortiClient / openfortivpn status icon and connect flow"))
                : Tr.tr("Disabled — tunnel and related processes are stopped")
            checked: GlobalConfig.addons.madisonVpn.enabled
            onToggled: MadisonVpn.setEnabled(checked)
        }

        ToggleRow {
            last: true
            leadingIcon: "timer"
            text: Tr.tr("Timers")
            subtext: Timers.enabled
                ? Tr.tr("Quick timers from the clock popout")
                : Tr.tr("Disabled — active timers are cleared")
            checked: GlobalConfig.addons.timers.enabled
            onToggled: Timers.setEnabled(checked)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            text: Tr.tr("Madison VPN config: ~/.config/openfortivpn/config (popout gear). Scripts: ~/.local/share/madison-vpn/")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
