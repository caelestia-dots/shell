pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Sub-page for manually adding a (typically hidden) Wi-Fi network. Reached from
// the "Add network" row on NetworkPage via nState.openSubPage.
PageBase {
    id: root

    // Security model: index 0 = none, 1 = WPA/WPA2/WPA3 personal.
    readonly property bool secured: securitySelect.active !== noneItem
    property bool connecting: false
    property bool failed: false

    function submit(): void {
        const ssid = ssidField.text.trim();
        if (ssid.length === 0) {
            ssidField.isError = true;
            ssidField.forceFieldFocus();
            return;
        }
        if (root.secured && passwordField.text.length < 8) {
            passwordField.isError = true;
            passwordField.forceFieldFocus();
            return;
        }

        root.failed = false;
        root.connecting = true;

        Nmcli.addHiddenNetwork(ssid, root.secured ? passwordField.text : "", root.secured ? "wpa" : "none", result => {
            root.connecting = false;
            if (result && result.success) {
                root.nState.closeSubPage();
            } else {
                root.failed = true;
                if (root.secured)
                    passwordField.isError = true;
                // Clean up the half-created profile so a retry starts fresh.
                Nmcli.forgetNetwork(ssid);
            }
        });
    }

    title: qsTr("Add hidden network")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            text: qsTr("Hidden networks don't broadcast their name, so enter the details manually.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        M3TextField {
            id: ssidField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            label: qsTr("Network name (SSID)")
            placeholder: qsTr("e.g. MyHiddenNetwork")
            leadingIcon: "wifi"
            errorText: qsTr("Network name is required")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: root.secured ? passwordField.forceFieldFocus() : root.submit()
        }

        SelectRow {
            id: securitySelect

            Layout.fillWidth: true
            first: true
            last: true
            label: qsTr("Security")
            fallbackText: qsTr("WPA/WPA2/WPA3 Personal")
            fallbackIcon: "lock"

            menuItems: [wpaItem, noneItem]

            Component.onCompleted: active = wpaItem

            MenuItem {
                id: wpaItem

                icon: "lock"
                text: qsTr("WPA/WPA2/WPA3 Personal")
            }

            MenuItem {
                id: noneItem

                icon: "lock_open"
                text: qsTr("None (open)")
            }
        }

        M3TextField {
            id: passwordField

            Layout.fillWidth: true
            visible: root.secured
            enabled: root.secured
            label: qsTr("Password")
            placeholder: qsTr("At least 8 characters")
            leadingIcon: "key"
            password: true
            supportingText: qsTr("WPA passwords are at least 8 characters")
            errorText: root.failed ? qsTr("Connection failed — check the password") : qsTr("Password must be at least 8 characters")

            onAccepted: root.submit()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            spacing: Tokens.spacing.medium

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
                type: TextButton.Text
                text: qsTr("Cancel")
                enabled: !root.connecting
                onClicked: root.nState.closeSubPage()
            }

            // Connect button — swaps to a loading spinner while connecting,
            // matching the Wi-Fi list connect animation.
            ButtonBase {
                id: connectBtn

                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3primary
                inactiveOnColour: Colours.palette.m3onPrimary
                stateLayer.disabled: root.connecting || ssidField.text.trim().length === 0

                implicitWidth: connectContent.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: connectContent.implicitHeight + Tokens.padding.medium * 2

                onClicked: if (!root.connecting && ssidField.text.trim().length > 0)
                    root.submit()

                AnimLoader {
                    id: connectContent

                    anchors.centerIn: parent
                    sourceComp: root.connecting ? connectLoadingComp : connectTextComp
                    outAnimType: Anim.SlowEffects
                    inAnimType: Anim.SlowEffects
                }

                Component {
                    id: connectLoadingComp

                    LoadingIndicator {
                        implicitSize: Math.round(Tokens.font.body.medium.pointSize * 1.4)
                        color: connectBtn.onColour
                    }
                }

                Component {
                    id: connectTextComp

                    StyledText {
                        text: qsTr("Connect")
                        color: connectBtn.onColour
                        animate: true
                    }
                }
            }
        }
    }
}
