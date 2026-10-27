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

    readonly property bool shouldBeVisible: root.popouts.currentName === "updatesPassword"

    width: Math.max(360, Tokens.sizes.bar.networkWidth)
    spacing: Tokens.spacing.medium

    function closeDialog(): void {
        Updates.cancelPassword();
        passwordField.text = "";
        if (root.popouts.currentName === "updatesPassword")
            root.popouts.currentName = "updates";
    }

    function submit(): void {
        const pw = passwordField.text;
        if (!pw.length)
            return;
        Updates.confirmPassword(pw);
        passwordField.text = "";
    }

    function focusPasswordField(): void {
        passwordField.text = "";
        root.forceActiveFocus();
        passwordField.forceActiveFocus();
    }

    visible: shouldBeVisible
    focus: shouldBeVisible

    Keys.onEscapePressed: closeDialog()

    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            // Wait for OnDemand keyboard focus Binding to apply (same pattern as Wi-Fi password)
            focusTimer.restart();
        } else if (Updates.awaitingPassword && !Updates.installing) {
            // Left the password UI without confirming (e.g. hover dismissed the popout)
            Updates.cancelPassword();
        }
    }

    Connections {
        target: root.popouts

        function onHasCurrentChanged(): void {
            // Hover-away dismisses the layer without changing currentName first
            if (!root.popouts.hasCurrent && Updates.awaitingPassword && !Updates.installing)
                Updates.cancelPassword();
        }
    }

    Connections {
        target: Updates
        function onPendingModeChanged(): void {
            // Auth succeeded (or cancelled) — leave password popout
            if (root.shouldBeVisible && !Updates.awaitingPassword && !Updates.authError.length) {
                passwordField.text = "";
                if (Updates.installing) {
                    root.popouts.hasCurrent = false;
                } else if (root.popouts.currentName === "updatesPassword") {
                    root.popouts.currentName = "updates";
                }
            }
        }
        function onInstallingChanged(): void {
            if (root.shouldBeVisible && Updates.installing && !Updates.awaitingPassword) {
                passwordField.text = "";
                root.popouts.hasCurrent = false;
            }
        }
        function onAuthErrorChanged(): void {
            // Wrong password — keep dialog open and refocus for retry
            if (root.shouldBeVisible && Updates.authError.length)
                focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer

        interval: 150
        onTriggered: {
            if (root.shouldBeVisible)
                root.focusPasswordField();
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "lock"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.large
            fill: 1
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Tr.tr("Authenticate")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Enter your password to update the system in the background.")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.WordWrap
            }
        }
    }

    StyledTextField {
        id: passwordField

        Layout.fillWidth: true
        placeholderText: Tr.tr("Password")
        echoMode: TextInput.Password
        enabled: !Updates.installing

        Keys.onReturnPressed: root.submit()
        Keys.onEnterPressed: root.submit()
    }

    StyledText {
        visible: Updates.authError.length > 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: Updates.authError
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
            enabled: !Updates.installing
            onClicked: root.closeDialog()
        }

        TextButton {
            Layout.fillWidth: true
            Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
            inactiveColour: Colours.palette.m3primary
            inactiveOnColour: Colours.palette.m3onPrimary
            text: Updates.installing ? Tr.tr("Authenticating…") : Tr.tr("Update")
            enabled: passwordField.text.length > 0 && !Updates.installing
            onClicked: root.submit()
        }
    }
}
