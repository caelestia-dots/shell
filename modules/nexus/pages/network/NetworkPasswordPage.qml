pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

// Sub-page for entering the password of a Wi-Fi network. Opened from the
// network list when a connection attempt reports that secrets are required.
PageBase {
    id: root

    readonly property var ap: Nmcli.findNetwork(nState.passwordNetwork?.ssid ?? "")
    property bool connecting: false
    property bool failed: false

    function submit(): void {
        const network = root.nState.passwordNetwork;
        if (!network || root.connecting)
            return;

        if (passwordField.text.length < 8) {
            passwordField.isError = true;
            passwordField.forceActiveFocus();
            return;
        }

        root.failed = false;
        root.connecting = true;

        // The service layer deletes any stale profile for this SSID before
        // creating the new one, so no cleanup is needed here.
        NetworkConnection.connectWithPassword(network, passwordField.text, result => {
            root.connecting = false;
            if (result && result.success) {
                root.nState.closeSubPage();
            } else if (result && result.needsPassword) {
                // Wrong password: let the user retry in place.
                root.failed = true;
                passwordField.isError = true;
                passwordField.selectAll();
                passwordField.forceActiveFocus();
            } else {
                root.failed = true;
                passwordField.isError = true;
            }
        });
    }

    title: nState.passwordNetwork?.ssid ?? qsTr("Password")
    isSubPage: true

    Connections {
        function onSubPageClosed(): void {
            root.nState.passwordNetwork = null;
        }

        target: root.nState
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            text: root.ap ? qsTr("Enter the password for “%1”.").arg(root.ap.ssid) : qsTr("Enter the network password.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        StyledTextField {
            id: passwordField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            placeholderText: qsTr("Password")
            leadingIcon: "key"
            echoMode: TextInput.Password
            supportingText: qsTr("WPA passwords are at least 8 characters")
            errorText: root.failed ? qsTr("Connection failed — check the password") : qsTr("Password must be at least 8 characters")
            inputMethodHints: Qt.ImhNoPredictiveText

            onAccepted: root.submit()
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: Tokens.spacing.extraSmall - parent.spacing
            spacing: Tokens.spacing.small

            TextButton {
                Layout.fillHeight: true
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                type: TextButton.Tonal
                text: qsTr("Cancel")
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
                stateLayer.disabled: root.connecting || passwordField.text.length === 0

                implicitWidth: connectMetrics.width + Tokens.padding.extraLarge * 2
                implicitHeight: connectMetrics.height + Tokens.padding.medium * 2

                onClicked: {
                    if (!root.connecting && passwordField.text.length > 0)
                        root.submit();
                }

                TextMetrics {
                    id: connectMetrics

                    text: qsTr("Connect")
                    font: connectBtn.font
                }

                AnimLoader {
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
                        text: connectMetrics.text
                        font: connectBtn.font
                        color: connectBtn.onColour
                    }
                }
            }
        }
    }
}
