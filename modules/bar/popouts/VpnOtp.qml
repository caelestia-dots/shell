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

    readonly property bool shouldBeVisible: root.popouts.currentName === "vpnOtp"

    width: 320
    spacing: Tokens.spacing.medium

    function closeDialog(): void {
        MadisonVpn.cancelOtp();
        otpField.text = "";
        // Return to the VPN status popout (same pattern as Wi‑Fi password → network)
        if (root.popouts.currentName === "vpnOtp")
            root.popouts.currentName = "vpn";
    }

    function submit(): void {
        const token = otpField.text.trim();
        if (token.length === 0)
            return;
        MadisonVpn.connectWithOtp(token);
        otpField.text = "";
        if (root.popouts.currentName === "vpnOtp")
            root.popouts.currentName = "vpn";
    }

    visible: shouldBeVisible
    focus: shouldBeVisible

    Keys.onEscapePressed: closeDialog()

    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            otpField.text = "";
            Qt.callLater(() => otpField.forceActiveFocus());
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "vpn_lock"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.large
            fill: 1
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Tr.tr("Madison VPN")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: Tr.tr("Enter your MFA OTP to connect")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    StyledTextField {
        id: otpField

        Layout.fillWidth: true
        placeholderText: Tr.tr("6-digit OTP")
        inputMethodHints: Qt.ImhDigitsOnly
        maximumLength: 12
        font: Tokens.font.mono.large
        horizontalAlignment: Text.AlignHCenter

        Keys.onReturnPressed: root.submit()
        Keys.onEnterPressed: root.submit()
    }

    StyledText {
        visible: MadisonVpn.lastError.length > 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: MadisonVpn.lastError
        color: Colours.palette.m3error
        font: Tokens.font.body.small
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

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
            text: Tr.tr("Connect")
            enabled: otpField.text.trim().length > 0 && !MadisonVpn.busy
            onClicked: root.submit()
        }
    }
}
