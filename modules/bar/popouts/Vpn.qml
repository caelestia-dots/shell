pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    width: Math.max(320, Tokens.sizes.bar.networkWidth)
    spacing: Tokens.spacing.small

    function startConnect(): void {
        MadisonVpn.requestOtp();
        root.popouts.currentName = "vpnOtp";
    }

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.tr("Madison VPN")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: MadisonVpn.connected ? "verified_user" : "remove_moderator"
            fill: MadisonVpn.connected ? 1 : 0
            color: MadisonVpn.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: MadisonVpn.statusText
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.medium
            }

            StyledText {
                visible: MadisonVpn.connected && MadisonVpn.vpnIp.length > 0
                text: MadisonVpn.vpnIp
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.mono.small
            }
        }
    }

    TextButton {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
        inactiveColour: MadisonVpn.connected ? Colours.palette.m3errorContainer : Colours.palette.m3primary
        inactiveOnColour: MadisonVpn.connected ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimary
        text: MadisonVpn.busy ? MadisonVpn.statusText : (MadisonVpn.connected ? Tr.tr("Disconnect") : Tr.tr("Connect"))
        enabled: !MadisonVpn.busy

        onClicked: {
            if (MadisonVpn.connected)
                MadisonVpn.disconnect();
            else
                root.startConnect();
        }
    }
}
