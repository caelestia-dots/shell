pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    readonly property bool shouldBeVisible: root.popouts.currentName === "vpnSettings"
    property bool showPassword: false

    width: Math.max(380, Tokens.sizes.bar.networkWidth + Tokens.padding.large)
    spacing: Tokens.spacing.medium

    function closeDialog(): void {
        if (root.popouts.currentName === "vpnSettings")
            root.popouts.currentName = "vpn";
    }

    function save(): void {
        MadisonVpn.cfgHost = hostField.text;
        MadisonVpn.cfgPort = portField.text;
        MadisonVpn.cfgUsername = userField.text;
        MadisonVpn.cfgPassword = passField.text;
        MadisonVpn.cfgRealm = realmField.text;
        if (MadisonVpn.saveConfig())
            root.closeDialog();
    }

    visible: shouldBeVisible
    focus: shouldBeVisible

    Keys.onEscapePressed: closeDialog()

    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            MadisonVpn.reloadConfig();
            Qt.callLater(() => {
                hostField.text = MadisonVpn.cfgHost;
                portField.text = MadisonVpn.cfgPort;
                userField.text = MadisonVpn.cfgUsername;
                passField.text = MadisonVpn.cfgPassword;
                realmField.text = MadisonVpn.cfgRealm;
                root.showPassword = false;
                hostField.forceActiveFocus();
            });
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        IconButton {
            icon: "arrow_back"
            type: IconButton.Text
            isRound: true
            onClicked: root.closeDialog()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("VPN settings")
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Stored in ~/.config/openfortivpn/config")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.large

        StyledTextField {
            id: hostField

            Layout.fillWidth: true
            verticalPadding: Tokens.padding.small
            placeholderText: Tr.trCtx("Host", "vpn server hostname")
            leadingIcon: "dns"
            text: MadisonVpn.cfgHost
            onAccepted: portField.forceActiveFocus()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledTextField {
                id: portField

                Layout.preferredWidth: Math.round(root.width * 0.32)
                Layout.minimumWidth: Tokens.sizes.nexus.smallTextFieldWidth
                verticalPadding: Tokens.padding.small
                placeholderText: Tr.trCtx("Port", "vpn server port")
                leadingIcon: "tag"
                text: MadisonVpn.cfgPort
                inputMethodHints: Qt.ImhDigitsOnly
                onAccepted: realmField.forceActiveFocus()
            }

            StyledTextField {
                id: realmField

                Layout.fillWidth: true
                verticalPadding: Tokens.padding.small
                placeholderText: Tr.trCtx("Realm", "vpn authentication realm")
                leadingIcon: "domain"
                text: MadisonVpn.cfgRealm
                onAccepted: userField.forceActiveFocus()
            }
        }

        StyledTextField {
            id: userField

            Layout.fillWidth: true
            verticalPadding: Tokens.padding.small
            placeholderText: Tr.trCtx("Username", "vpn username")
            leadingIcon: "person"
            text: MadisonVpn.cfgUsername
            onAccepted: passField.forceActiveFocus()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: passField

                Layout.fillWidth: true
                verticalPadding: Tokens.padding.small
                placeholderText: Tr.trCtx("Password", "vpn password")
                leadingIcon: "key"
                text: MadisonVpn.cfgPassword
                echoMode: root.showPassword ? T.TextField.Normal : T.TextField.Password
                onAccepted: root.save()
            }

            IconButton {
                Layout.alignment: Qt.AlignVCenter
                icon: root.showPassword ? "visibility_off" : "visibility"
                type: IconButton.Text
                isRound: true
                onClicked: root.showPassword = !root.showPassword
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        visible: !!MadisonVpn.configError
        text: MadisonVpn.configError
        color: Colours.palette.m3error
        font: Tokens.font.label.small
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        TextButton {
            Layout.fillWidth: true
            Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
            inactiveColour: Colours.palette.m3secondaryContainer
            inactiveOnColour: Colours.palette.m3onSecondaryContainer
            text: Tr.trCtx("Cancel", "button")
            onClicked: root.closeDialog()
        }

        TextButton {
            Layout.fillWidth: true
            Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
            inactiveColour: Colours.palette.m3primary
            inactiveOnColour: Colours.palette.m3onPrimary
            text: Tr.trCtx("Save", "button")
            onClicked: root.save()
        }
    }
}
