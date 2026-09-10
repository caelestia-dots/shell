pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
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
    property bool success: false

    function submit(): void {
        const ssid = ssidField.text.trim();
        if (ssid.length === 0) {
            ssidField.isError = true;
            ssidField.forceActiveFocus();
            return;
        }
        if (root.secured && passwordField.text.length < 8) {
            passwordField.isError = true;
            passwordField.forceActiveFocus();
            return;
        }

        root.failed = false;
        root.connecting = true;

        Nmcli.addHiddenNetwork(ssid, root.secured ? passwordField.text : "", root.secured ? "wpa" : "none", hiddenToggle.checked, result => {
            root.connecting = false;
            if (result && result.success) {
                root.success = true;
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

    title: Tr.tr("Add network")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        Connections {
            function onSubPageClosed(): void {
                if (root.success)
                    return;

                const ssid = ssidField.text.trim();
                if (ssid)
                    Nmcli.forgetNetwork(ssid);
            }

            target: root.nState
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            text: Tr.tr("Enter the details below to manually connect to a network.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        StyledTextField {
            id: ssidField

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            // TRANSLATORS: SSID is a protocol term, leave it untranslated
            placeholderText: Tr.tr("Network name (SSID)")
            // TRANSLATORS: sample network name, translate the e.g. but the name is a placeholder
            supportingText: Tr.tr("e.g. MyHiddenNetwork")
            leadingIcon: "wifi"
            errorText: Tr.tr("Network name is required")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

            onAccepted: root.secured ? passwordField.forceActiveFocus() : root.submit()
        }

        ToggleRow {
            id: hiddenToggle

            first: true
            text: Tr.tr("Hidden network")
            subtext: Tr.tr("Actively probe for a network that doesn't broadcast its name")
            checked: true
        }

        SelectRow {
            id: securitySelect

            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            last: !root.secured
            label: Tr.tr("Security")
            // TRANSLATORS: WPA/WPA2/WPA3 are protocol names, leave them untranslated
            fallbackText: Tr.tr("WPA/WPA2/WPA3 Personal")
            fallbackIcon: "lock"

            menuItems: [
                MenuItem {
                    icon: "lock"
                    // TRANSLATORS: WPA/WPA2/WPA3 are protocol names, leave them untranslated
                    text: Tr.tr("WPA/WPA2/WPA3 Personal")
                },
                MenuItem {
                    id: noneItem

                    icon: "lock_open"
                    text: Tr.trCtx("None (open)", "wifi security type")
                }
            ]

            Behavior on bottomLeftRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on bottomRightRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.bottomMargin: root.secured ? 0 : -parent.spacing
            implicitHeight: root.secured ? passwordField.implicitHeight : 0
            opacity: root.secured ? 1 : 0

            Behavior on Layout.bottomMargin {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on implicitHeight {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            StyledTextField {
                id: passwordField

                anchors.left: parent.left
                anchors.right: parent.right

                enabled: root.secured
                placeholderText: Tr.tr("Password")
                leadingIcon: "key"
                echoMode: TextInput.Password
                // TRANSLATORS: WPA is a protocol name, leave it untranslated
                supportingText: Tr.tr("WPA passwords are at least 8 characters")
                errorText: root.failed ? Tr.tr("Connection failed — check the password") : Tr.tr("Password must be at least 8 characters")

                onAccepted: root.submit()
            }
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
                text: Tr.trCtx("Cancel", "button")
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

                implicitWidth: connectMetrics.width + Tokens.padding.extraLarge * 2
                implicitHeight: connectMetrics.height + Tokens.padding.medium * 2

                onClicked: {
                    if (!root.connecting && ssidField.text.trim().length > 0)
                        root.submit();
                }

                TextMetrics {
                    id: connectMetrics

                    text: Tr.tr("Connect")
                    font: connectBtn.font
                }

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
                        text: connectMetrics.text
                        font: connectBtn.font
                        color: connectBtn.onColour
                    }
                }
            }
        }
    }
}
